import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/data/dog_repository_provider.dart';
import 'package:woofy/features/landing/presentation/widgets/landing_shelter_card.dart';
import 'package:woofy/features/landing/presentation/widgets/recent_dog_preview_card.dart';
import 'package:woofy/features/publisher/data/publisher_providers.dart';
import 'package:woofy/shared/widgets/woofy_bottom_navigation.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_circle_icon_button.dart';
import 'package:woofy/shared/widgets/woofy_promo_banner.dart';
import 'package:woofy/shared/widgets/woofy_refresh.dart';
import 'package:woofy/shared/widgets/woofy_search_field.dart';
import 'package:woofy/shared/widgets/woofy_section_header.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  static const _recentDogsLimit = 3;

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage>
    with WoofyRefreshMixin {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Future<void> onWoofyRefresh() async {
    ref.invalidate(publishedDogsProvider);
    await ref.read(publishedDogsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final shelterSession = ref.watch(shelterPortalSessionProvider).value;
    final dogs = ref.watch(publishedDogsProvider);

    final hasAccount = user != null || shelterSession != null;
    void goToAccount() =>
        context.go(hasAccount ? RoutePaths.profile : RoutePaths.auth);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: CustomScrollView(
            slivers: [
              WoofyRefreshControl(onRefresh: refreshData),
              SliverToBoxAdapter(
                child: _ImmersiveHeader(
                  searchController: _searchController,
                  onNotificationsPressed: () =>
                      context.push(RoutePaths.messages),
                  onAccountPressed: goToAccount,
                  onExplorePressed: () => context.go(RoutePaths.dogs),
                  onServicesPressed: () => context.push(RoutePaths.services),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  WoofySpacing.lg,
                  WoofySpacing.xl,
                  WoofySpacing.lg,
                  WoofySpacing.xxl +
                      WoofyBottomNavigation.reservedHeight +
                      MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    WoofyPromoBanner(onTap: () => context.go(RoutePaths.dogs)),
                    const SizedBox(height: WoofySpacing.xl),
                    _LandingQuickActions(
                      onExplore: () => context.go(RoutePaths.dogs),
                      onFavorites: () => context.push(RoutePaths.favorites),
                      onMessages: () => context.push(RoutePaths.messages),
                      onProfile: goToAccount,
                    ),
                    if (shelterSession != null) ...[
                      const SizedBox(height: WoofySpacing.lg),
                      LandingShelterCard(
                        shelterName: shelterSession.shelterName,
                        onPressed: () => context.go(RoutePaths.publisher),
                      ),
                    ],
                    const SizedBox(height: WoofySpacing.xxxl),
                    WoofySectionHeader(
                      title: 'Conocé a estos peluditos',
                      subtitle: 'Animales que buscan un hogar hoy.',
                      trailing: TextButton(
                        onPressed: () => context.go(RoutePaths.dogs),
                        child: const Text('Ver todos'),
                      ),
                    ),
                    const SizedBox(height: WoofySpacing.md),
                    _RecentDogsPreview(
                      dogs: dogs,
                      onExplorePressed: () => context.go(RoutePaths.dogs),
                      onRetry: () => ref.invalidate(publishedDogsProvider),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Celeste "immersive" top band, inspired by the reference's colored hero:
/// greeting, search and the adoption hero live inside one rounded block that
/// bleeds to the screen edges. The couple photo sits on the right, clipped by
/// the block's rounded bottom corner.
class _ImmersiveHeader extends StatelessWidget {
  const _ImmersiveHeader({
    required this.searchController,
    required this.onNotificationsPressed,
    required this.onAccountPressed,
    required this.onExplorePressed,
    required this.onServicesPressed,
  });

  final TextEditingController searchController;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onAccountPressed;
  final VoidCallback onExplorePressed;
  final VoidCallback onServicesPressed;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: ColoredBox(
        color: WoofyColors.primarySoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: topInset + WoofySpacing.md,
                left: WoofySpacing.xl,
                right: WoofySpacing.md,
              ),
              child: _HeaderBar(
                onNotificationsPressed: onNotificationsPressed,
                onAccountPressed: onAccountPressed,
              ),
            ),
            const SizedBox(height: WoofySpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WoofySpacing.xl),
              child: WoofySearchField(
                controller: searchController,
                hintText: 'Buscar animales, refugios o razas',
              ),
            ),
            const SizedBox(height: WoofySpacing.xl),
            _HeroBand(
              onExplorePressed: onExplorePressed,
              onServicesPressed: onServicesPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.onNotificationsPressed,
    required this.onAccountPressed,
  });

  final VoidCallback onNotificationsPressed;
  final VoidCallback onAccountPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CitySelector(),
              const SizedBox(height: WoofySpacing.xs),
              Text(
                'Hola 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: WoofySpacing.sm),
        WoofyCircleIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notificaciones',
          onPressed: onNotificationsPressed,
        ),
        const SizedBox(width: WoofySpacing.sm),
        WoofyCircleIconButton(
          icon: Icons.person_outline_rounded,
          tooltip: 'Mi cuenta',
          onPressed: onAccountPressed,
        ),
      ],
    );
  }
}

/// City scope for the whole catalog. Reads the cities that actually have
/// published animals, so it never offers an empty result.
class _CitySelector extends ConsumerWidget {
  const _CitySelector();

  static const _allLabel = 'Todas las ciudades';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cities = ref.watch(availableCitiesProvider);
    final selected = ref.watch(selectedCityProvider);

    return InkWell(
      key: const ValueKey('city-selector'),
      onTap: cities.isEmpty ? null : () => _openSheet(context, ref, cities),
      borderRadius: BorderRadius.circular(WoofyRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: WoofySpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.place_outlined,
              size: 20,
              color: WoofyColors.textPrimary,
            ),
            const SizedBox(width: WoofySpacing.xs),
            Flexible(
              child: Text(
                selected ?? _allLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (cities.isNotEmpty)
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: WoofyColors.textPrimary,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref,
    List<String> cities,
  ) {
    final selected = ref.read(selectedCityProvider);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final city in <String?>[null, ...cities])
              ListTile(
                title: Text(city ?? _allLabel),
                trailing: city == selected
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  ref.read(selectedCityProvider.notifier).select(city);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroBand extends StatelessWidget {
  const _HeroBand({
    required this.onExplorePressed,
    required this.onServicesPressed,
  });

  final VoidCallback onExplorePressed;
  final VoidCallback onServicesPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: WoofySpacing.xl,
        right: WoofySpacing.xl,
        top: WoofySpacing.xs,
        bottom: WoofySpacing.xxl,
      ),
      child: _HeroText(
        onExplorePressed: onExplorePressed,
        onServicesPressed: onServicesPressed,
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText({
    required this.onExplorePressed,
    required this.onServicesPressed,
  });

  final VoidCallback onExplorePressed;
  final VoidCallback onServicesPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Adoptá felicidad,\nuna patita a la vez.',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: WoofySpacing.sm),
        Text(
          'Conocé animales que están esperando una familia.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: WoofySpacing.lg),
        // Los dos en `Expanded` y no con ancho propio: "Ver animales" es la
        // acción principal y no puede quedar apretada porque la otra etiqueta
        // crezca. En pantallas de 320 px entran ajustados y por eso el texto
        // del botón es `Flexible`.
        Row(
          children: [
            Expanded(
              child: WoofyButton(
                label: 'Ver animales',
                icon: Icons.pets_rounded,
                isExpanded: true,
                onPressed: onExplorePressed,
              ),
            ),
            const SizedBox(width: WoofySpacing.sm),
            Expanded(
              child: WoofyButton(
                key: const ValueKey('landing-services-button'),
                label: 'Servicios',
                icon: Icons.spa_outlined,
                isExpanded: true,
                variant: WoofyButtonVariant.secondary,
                // Beige de la paleta: la adopción se queda con el azul de
                // marca y los servicios no compiten con ella.
                backgroundColor: WoofyColors.surfaceMuted,
                foregroundColor: WoofyColors.textPrimary,
                onPressed: onServicesPressed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LandingQuickActions extends StatelessWidget {
  const _LandingQuickActions({
    required this.onExplore,
    required this.onFavorites,
    required this.onMessages,
    required this.onProfile,
  });

  final VoidCallback onExplore;
  final VoidCallback onFavorites;
  final VoidCallback onMessages;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.explore_rounded,
            label: 'Explorar',
            onPressed: onExplore,
          ),
        ),
        const SizedBox(width: WoofySpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: Icons.favorite_rounded,
            label: 'Favoritos',
            onPressed: onFavorites,
          ),
        ),
        const SizedBox(width: WoofySpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: Icons.chat_bubble_rounded,
            label: 'Mensajes',
            onPressed: onMessages,
          ),
        ),
        const SizedBox(width: WoofySpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: Icons.person_rounded,
            label: 'Perfil',
            onPressed: onProfile,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: WoofyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: WoofyRadius.cardAll,
        side: BorderSide(color: WoofyColors.border),
      ),
      child: InkWell(
        borderRadius: WoofyRadius.cardAll,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: WoofySpacing.md,
            horizontal: WoofySpacing.xs,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: WoofyColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: WoofyColors.primary),
              ),
              const SizedBox(height: WoofySpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDogsPreview extends StatelessWidget {
  const _RecentDogsPreview({
    required this.dogs,
    required this.onExplorePressed,
    required this.onRetry,
  });

  final AsyncValue<List<Dog>> dogs;
  final VoidCallback onExplorePressed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return dogs.when(
      loading: _RecentDogsLoading.new,
      error: (error, stackTrace) => _RecentDogsMessage(
        message: 'No pudimos cargar los recién llegados.',
        actionLabel: 'Reintentar',
        onPressed: onRetry,
      ),
      data: (dogs) {
        if (dogs.isEmpty) {
          return _RecentDogsMessage(
            message: 'Todavía no hay animales publicados.',
            actionLabel: 'Ver animales',
            onPressed: onExplorePressed,
          );
        }

        final recentDogs = dogs.take(LandingPage._recentDogsLimit).toList();
        return SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: recentDogs.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: WoofySpacing.md),
            itemBuilder: (context, index) {
              final dog = recentDogs[index];
              return SizedBox(
                width: 176,
                child: RecentDogPreviewCard(
                  dog: dog,
                  onTap: () => context.push(RoutePaths.dogDetail(dog.slug)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RecentDogsLoading extends StatelessWidget {
  const _RecentDogsLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: List.generate(
            2,
            (index) => Padding(
              padding: EdgeInsets.only(right: index == 0 ? WoofySpacing.md : 0),
              child: Container(
                width: 112,
                height: 156,
                decoration: const BoxDecoration(
                  color: WoofyColors.surfaceMuted,
                  borderRadius: WoofyRadius.cardAll,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentDogsMessage extends StatelessWidget {
  const _RecentDogsMessage({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(WoofySpacing.lg),
      decoration: BoxDecoration(
        color: WoofyColors.surfaceMuted,
        borderRadius: WoofyRadius.cardAll,
      ),
      child: Row(
        children: [
          Icon(Icons.pets_outlined, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: WoofySpacing.md),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: WoofySpacing.sm),
          TextButton(
            key: ValueKey('recent-dogs-action-$actionLabel'),
            onPressed: onPressed,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
