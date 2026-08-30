import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/blocks/data/blocks_repository.dart';
import 'package:woofy/features/blocks/providers/blocks_providers.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';

/// Bloquear sin poder deshacerlo sería una trampa: acá se revierte.
class BlockedAccountsPage extends ConsumerWidget {
  const BlockedAccountsPage({super.key});

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    BlockedShelter blocked,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Desbloquear refugio'),
        content: Text(
          '${blocked.shelterName} va a poder volver a escribirte y sus '
          'conversaciones reaparecen en tu bandeja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(blockControllerProvider.notifier)
          .unblockShelter(blocked.shelterId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Desbloqueaste a ${blocked.shelterName}.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos desbloquear al refugio.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedSheltersProvider);

    return BackFallbackScope(
      fallbackLocation: RoutePaths.profile,
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Cuentas bloqueadas'),
        body: SafeArea(
          child: blocked.when(
            skipLoadingOnReload: true,
            loading: () => const WoofyLoading(message: 'Cargando bloqueos…'),
            error: (_, _) => WoofyError(
              message: 'No pudimos cargar tus bloqueos.',
              onRetry: () => ref.invalidate(blockedSheltersProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const WoofyEmptyState(
                  icon: Icons.block_outlined,
                  title: 'No bloqueaste a nadie.',
                  message:
                      'Si un refugio te incomoda, podés bloquearlo desde la '
                      'conversación.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(WoofySpacing.lg),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: WoofySpacing.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return WoofyCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.shelterName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          key: ValueKey('unblock-${item.shelterId}'),
                          onPressed: () => _unblock(context, ref, item),
                          child: const Text('Desbloquear'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
