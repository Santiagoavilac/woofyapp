import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_app/app/back_fallback_scope.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/core/errors/app_exception.dart';
import 'package:mi_app/features/auth/presentation/widgets/profile_info_card.dart';
import 'package:mi_app/features/auth/providers/auth_providers.dart';
import 'package:mi_app/shared/widgets/woofy_app_bar.dart';
import 'package:mi_app/shared/widgets/woofy_button.dart';
import 'package:mi_app/shared/widgets/woofy_empty_state.dart';
import 'package:mi_app/shared/widgets/woofy_error.dart';
import 'package:mi_app/shared/widgets/woofy_loading.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final controller = ref.watch(authControllerProvider);

    return BackFallbackScope(
      fallbackLocation: RoutePaths.dogs,
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Mi perfil'),
        body: SafeArea(
          child: profile.when(
            loading: () => const WoofyLoading(message: 'Cargando tu perfil…'),
            error: (error, _) => WoofyError(
              message: error is AppException
                  ? error.message
                  : 'No pudimos cargar tu perfil.',
              onRetry: () => ref.invalidate(currentProfileProvider),
            ),
            data: (data) {
              if (data == null) {
                if (controller.isLoading) {
                  return const WoofyLoading(message: 'Preparando tu perfil…');
                }
                if (controller.hasError) {
                  final error = controller.error;
                  return WoofyError(
                    message: error is AppException
                        ? error.message
                        : 'No pudimos preparar tu perfil.',
                    onRetry: () => ref
                        .read(authControllerProvider.notifier)
                        .ensureCurrentProfile(),
                  );
                }
                return WoofyEmptyState(
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Tu perfil todavía no está completo.',
                  message:
                      'Podés volver a intentar crearlo con tu cuenta actual.',
                  actionLabel: 'Reintentar',
                  onAction: controller.isLoading
                      ? null
                      : () => ref
                            .read(authControllerProvider.notifier)
                            .ensureCurrentProfile(),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Tu cuenta Woofy',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Estos son los datos básicos de tu perfil.'),
                        const SizedBox(height: 24),
                        ProfileInfoCard(profile: data),
                        const SizedBox(height: 16),
                        WoofyButton(
                          label: 'Mis favoritos',
                          icon: Icons.favorite_outline_rounded,
                          variant: WoofyButtonVariant.secondary,
                          isExpanded: true,
                          onPressed: () => context.push(RoutePaths.favorites),
                        ),
                        const SizedBox(height: 24),
                        WoofyButton(
                          label: 'Cerrar sesión',
                          icon: Icons.logout_rounded,
                          variant: WoofyButtonVariant.secondary,
                          isExpanded: true,
                          isLoading: controller.isLoading,
                          onPressed: () async {
                            await ref
                                .read(authControllerProvider.notifier)
                                .signOut();
                            if (context.mounted) context.go(RoutePaths.landing);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
