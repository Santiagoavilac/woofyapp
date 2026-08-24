import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String? _error;

  Future<void> _confirmAndDelete() async {
    final usesApple = ref.read(authRepositoryProvider).hasAppleIdentity;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text(
          usesApple
              ? '¿Seguro que querés eliminar tu cuenta de Woofy? Vamos a '
                    'pedirte confirmar con Apple para revocar el acceso. '
                    'Esta acción no se puede deshacer.'
              : '¿Seguro que querés eliminar tu cuenta de Woofy? Se borran '
                    'tus datos de forma definitiva y esta acción no se puede '
                    'deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      // Apple exige revocar los tokens al eliminar la cuenta. Pedimos un
      // código fresco en este momento en vez de guardar uno de larga
      // duración en la base.
      String? appleCode;
      if (usesApple) {
        appleCode = await ref
            .read(authRepositoryProvider)
            .reauthenticateWithApple();
      }

      await ref
          .read(accountDeletionRepositoryProvider)
          .deleteAccount(appleAuthorizationCode: appleCode);

      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu cuenta fue eliminada.')),
      );
      context.go(RoutePaths.landing);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AppException
            ? error.message
            : 'No pudimos eliminar tu cuenta. Intentá nuevamente.',
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
                            'Qué pasa cuando eliminás tu cuenta',
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
                    WoofyButton(
                      key: const ValueKey('request-deletion'),
                      label: 'Eliminar mi cuenta',
                      icon: Icons.delete_outline_rounded,
                      variant: WoofyButtonVariant.secondary,
                      isExpanded: true,
                      isLoading: _isSubmitting,
                      onPressed: _confirmAndDelete,
                    ),
                    const SizedBox(height: 12),
                    WoofyButton(
                      label: 'Ver política de eliminación',
                      icon: Icons.open_in_new_rounded,
                      variant: WoofyButtonVariant.secondary,
                      isExpanded: true,
                      onPressed: () => openLegalUrl(LegalLinks.eliminarCuenta),
                    ),
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
