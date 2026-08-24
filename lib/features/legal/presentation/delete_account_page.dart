import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/legal/data/legal_links.dart';
import 'package:woofy/features/legal/providers/legal_providers.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  bool _isSubmitting = false;
  bool _requested = false;
  String? _error;

  Future<void> _confirmAndRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Solicitar eliminación de cuenta'),
        content: const Text(
          '¿Querés enviar una solicitud para eliminar tu cuenta de Woofy? '
          'Vamos a procesarla y te avisaremos por correo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Solicitar eliminación'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(accountDeletionRepositoryProvider).requestDeletion(user);
      if (!mounted) return;
      setState(() => _requested = true);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AppException
            ? error.message
            : 'No pudimos registrar tu solicitud. Intentá nuevamente.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BackFallbackScope(
      fallbackLocation: RoutePaths.profile,
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Eliminar cuenta'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Eliminar tu cuenta',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    WoofyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qué pasa cuando solicitás la eliminación',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Se eliminan tu perfil, tus favoritos, tus '
                            'solicitudes, tus mensajes y tus publicaciones '
                            'asociadas a tu cuenta.',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Podemos conservar temporalmente cierta '
                            'información por razones de seguridad, reportes o '
                            'cumplimiento legal.',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Si tenés dudas, escribinos a hola@woofy.bo antes '
                            'de continuar.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_requested)
                      WoofyCard(
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Recibimos tu solicitud de eliminación. Te '
                                'contactaremos por correo para continuar.',
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      WoofyButton(
                        key: const ValueKey('request-deletion'),
                        label: 'Solicitar eliminación de cuenta',
                        icon: Icons.delete_outline_rounded,
                        variant: WoofyButtonVariant.secondary,
                        isExpanded: true,
                        isLoading: _isSubmitting,
                        onPressed: _confirmAndRequest,
                      ),
                      const SizedBox(height: 12),
                      WoofyButton(
                        label: 'Ver política de eliminación',
                        icon: Icons.open_in_new_rounded,
                        variant: WoofyButtonVariant.secondary,
                        isExpanded: true,
                        onPressed: () =>
                            openLegalUrl(LegalLinks.eliminarCuenta),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
