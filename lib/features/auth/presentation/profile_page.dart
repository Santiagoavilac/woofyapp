import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/auth/presentation/widgets/profile_info_card.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/legal/data/legal_links.dart';
import 'package:woofy/features/publisher/data/publisher_models.dart';
import 'package:woofy/features/publisher/data/publisher_providers.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final controller = ref.watch(authControllerProvider);
    final user = ref.watch(currentUserProvider);
    final shelterSession = ref.watch(shelterPortalSessionProvider).value;

    final hasUser = user != null;
    final hasShelter = shelterSession != null;

    return PopScope<Object?>(
      // Perfil is a shell branch, not a pushed route: the system back must
      // return to Home. Intercepting inside the branch navigator makes Flutter
      // report canHandlePop=true so Android hands us the back instead of
      // exiting the app.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RoutePaths.landing);
      },
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Mi cuenta'),
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
                      'Mi cuenta',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    if (hasShelter) ...[
                      _ShelterSection(session: shelterSession),
                      const SizedBox(height: 16),
                      WoofyButton(
                        label: 'Ir al panel del refugio',
                        icon: Icons.home_work_rounded,
                        isExpanded: true,
                        onPressed: () => context.push(RoutePaths.publisher),
                      ),
                      const SizedBox(height: 12),
                      WoofyButton(
                        label: 'Editar refugio',
                        icon: Icons.edit_outlined,
                        variant: WoofyButtonVariant.secondary,
                        isExpanded: true,
                        onPressed: () =>
                            context.push(RoutePaths.shelterEditProfile),
                      ),
                      const SizedBox(height: 12),
                      WoofyButton(
                        label: 'Cerrar sesión del refugio',
                        icon: Icons.logout_rounded,
                        variant: WoofyButtonVariant.secondary,
                        isExpanded: true,
                        onPressed: () => _confirmShelterLogout(context, ref),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (hasUser)
                      _AdopterSection(
                        profile: profile,
                        controller: controller,
                        onRetry: () => ref
                            .read(authControllerProvider.notifier)
                            .ensureCurrentProfile(),
                        onSignOut: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .signOut();
                          if (context.mounted) context.go(RoutePaths.landing);
                        },
                      )
                    else if (!hasShelter)
                      _NoSessionSection()
                    else
                      _AdopterInviteSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmShelterLogout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cerrar sesión del refugio'),
        content: const Text('¿Querés salir del portal del refugio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(shelterPortalSessionProvider.notifier).logout();
    if (context.mounted) context.go(RoutePaths.landing);
  }
}

class _ShelterSection extends ConsumerWidget {
  const _ShelterSection({required this.session});

  final ShelterPortalSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final path = session.profileImagePath;
    final photoUrl = (path == null || path.isEmpty)
        ? null
        : ref
              .watch(supabaseClientProvider)
              .storage
              .from('dog-images')
              .getPublicUrl(path);
    return WoofyCard(
      child: Row(
        children: [
          ClipOval(
            child: Container(
              width: 56,
              height: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              child: photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Icon(
                        Icons.home_work_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      errorWidget: (_, _, _) => Icon(
                        Icons.home_work_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.home_work_rounded,
                      color: theme.colorScheme.primary,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.shelterName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Sesión de refugio activa',
                  style: theme.textTheme.bodySmall,
                ),
                if (session.shelterCity != null &&
                    session.shelterCity!.isNotEmpty)
                  Text(session.shelterCity!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdopterSection extends StatelessWidget {
  const _AdopterSection({
    required this.profile,
    required this.controller,
    required this.onRetry,
    required this.onSignOut,
  });

  final AsyncValue<dynamic> profile;
  final AsyncValue<void> controller;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return profile.when(
      skipLoadingOnReload: true,
      loading: () => const WoofyLoading(message: 'Cargando tu perfil…'),
      error: (error, _) => WoofyError(
        message: error is AppException
            ? error.message
            : 'No pudimos cargar tu perfil.',
        onRetry: onRetry,
      ),
      data: (data) {
        if (data == null) {
          if (controller.isLoading) {
            return const WoofyLoading(message: 'Preparando tu perfil…');
          }
          if (controller.hasError) {
            return WoofyError(
              message: controller.error is AppException
                  ? (controller.error as AppException).message
                  : 'No pudimos preparar tu perfil.',
              onRetry: onRetry,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tu perfil todavía no está completo.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Podés volver a intentar crearlo con tu cuenta actual.',
              ),
              const SizedBox(height: 16),
              WoofyButton(
                label: 'Reintentar',
                isExpanded: true,
                onPressed: onRetry,
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tu cuenta adoptante',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ProfileInfoCard(profile: data),
            const SizedBox(height: 12),
            WoofyButton(
              label: 'Editar mi cuenta',
              icon: Icons.edit_outlined,
              variant: WoofyButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => context.push(RoutePaths.adopterEditProfile),
            ),
            const SizedBox(height: 12),
            WoofyButton(
              label: 'Mis favoritos',
              icon: Icons.favorite_outline_rounded,
              variant: WoofyButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => context.push(RoutePaths.favorites),
            ),
            const SizedBox(height: 12),
            WoofyButton(
              label: 'Mis mensajes',
              icon: Icons.forum_outlined,
              variant: WoofyButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => context.push(RoutePaths.messages),
            ),
            const SizedBox(height: 12),
            WoofyButton(
              label: 'Mis pedidos',
              icon: Icons.receipt_long_outlined,
              variant: WoofyButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => context.push(RoutePaths.orders),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Legal y soporte',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            WoofyButton(
              label: 'Términos de uso',
              icon: Icons.description_outlined,
              variant: WoofyButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => openLegalUrl(LegalLinks.terminos),
            ),
            const SizedBox(height: 12),
            WoofyButton(
              label: 'Política de privacidad',
              icon: Icons.privacy_tip_outlined,
              variant: WoofyButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => openLegalUrl(LegalLinks.privacidad),
            ),
            const SizedBox(height: 12),
            WoofyButton(
              label: 'Definiciones',
              icon: Icons.menu_book_outlined,
              variant: WoofyButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => openLegalUrl(LegalLinks.definiciones),
            ),
            const SizedBox(height: 12),
            WoofyButton(
              label: 'Soporte',
              icon: Icons.support_agent_outlined,
              variant: WoofyButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => openLegalUrl(LegalLinks.soporte),
            ),
            const SizedBox(height: 12),
            WoofyButton(
              key: const ValueKey('blocked-accounts'),
              label: 'Cuentas bloqueadas',
              icon: Icons.block_outlined,
              variant: WoofyButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => context.push(RoutePaths.blockedAccounts),
            ),
            const SizedBox(height: 12),
            WoofyButton(
              label: 'Eliminar cuenta',
              icon: Icons.delete_outline_rounded,
              variant: WoofyButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => context.push(RoutePaths.deleteAccount),
            ),
            const SizedBox(height: 20),
            WoofyButton(
              label: 'Cerrar sesión',
              icon: Icons.logout_rounded,
              variant: WoofyButtonVariant.secondary,
              isExpanded: true,
              isLoading: controller.isLoading,
              onPressed: onSignOut,
            ),
          ],
        );
      },
    );
  }
}

class _AdopterInviteSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WoofyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿También adoptás?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ingresá o creá una cuenta de adoptante para guardar favoritos y '
            'chatear con otros refugios.',
          ),
          const SizedBox(height: 12),
          WoofyButton(
            label: 'Ingresar como adoptante',
            variant: WoofyButtonVariant.secondary,
            isExpanded: true,
            onPressed: () => context.push(RoutePaths.auth),
          ),
        ],
      ),
    );
  }
}

class _NoSessionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WoofyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Todavía no iniciaste sesión.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Elegí cómo querés ingresar a Woofy.'),
          const SizedBox(height: 16),
          WoofyButton(
            label: 'Ingresar como adoptante',
            isExpanded: true,
            onPressed: () => context.push(RoutePaths.auth),
          ),
          const SizedBox(height: 12),
          WoofyButton(
            label: 'Ingresar como refugio',
            icon: Icons.home_work_rounded,
            variant: WoofyButtonVariant.secondary,
            isExpanded: true,
            onPressed: () => context.push(RoutePaths.shelterLogin),
          ),
        ],
      ),
    );
  }
}
