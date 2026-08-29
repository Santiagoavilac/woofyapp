import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/reports/data/report_models.dart';
import 'package:woofy/features/reports/providers/reports_providers.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_filter_chips.dart';
import 'package:woofy/shared/widgets/woofy_text_field.dart';

/// Hoja de denuncia, única para los cuatro tipos de contenido reportable.
/// Sigue la convención del sheet de filtros del catálogo: `showDragHandle` y
/// `isScrollControlled`.
Future<void> showReportSheet(
  BuildContext context, {
  required ReportTargetType targetType,
  required String targetId,
  required String title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      // Deja subir la hoja cuando aparece el teclado.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _ReportSheet(
        targetType: targetType,
        targetId: targetId,
        title: title,
      ),
    ),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({
    required this.targetType,
    required this.targetId,
    required this.title,
  });

  final ReportTargetType targetType;
  final String targetId;
  final String title;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  ReportReason _reason = ReportReason.inappropriateContent;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await ref
          .read(reportControllerProvider.notifier)
          .submit(
            ReportDraft(
              targetType: widget.targetType,
              targetId: widget.targetId,
              reason: _reason,
              details: _detailsController.text,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gracias. Vamos a revisar tu denuncia.')),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportControllerProvider);
    final error = state.error;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          WoofySpacing.lg,
          0,
          WoofySpacing.lg,
          WoofySpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: WoofySpacing.sm),
            const Text('Contanos qué pasa para que podamos revisarlo.'),
            const SizedBox(height: WoofySpacing.lg),
            WoofyFilterChips(
              padding: EdgeInsets.zero,
              options: [
                for (final reason in ReportReason.values)
                  WoofyFilterOption(value: reason.name, label: reason.label),
              ],
              selected: _reason.name,
              onSelected: (value) =>
                  setState(() => _reason = ReportReason.values.byName(value)),
            ),
            const SizedBox(height: WoofySpacing.lg),
            WoofyTextField(
              key: const ValueKey('report-details'),
              controller: _detailsController,
              label: 'Detalle (opcional)',
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
            ),
            if (error is AppException) ...[
              const SizedBox(height: WoofySpacing.sm),
              Text(
                error.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: WoofySpacing.md),
            WoofyButton(
              key: const ValueKey('report-submit'),
              label: 'Enviar denuncia',
              isExpanded: true,
              isLoading: state.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
