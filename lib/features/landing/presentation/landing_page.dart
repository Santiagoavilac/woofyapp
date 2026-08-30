import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/banners/data/banner_models.dart';
import 'package:woofy/features/banners/data/banner_repository_provider.dart';
import 'package:woofy/features/banners/presentation/widgets/banner_carousel.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/data/dog_repository_provider.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/merch/presentation/merch_store_page.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';
import 'package:woofy/features/partners/presentation/widgets/partner_card.dart';
import 'package:woofy/features/partners/presentation/widgets/service_card.dart';
import 'package:woofy/features/landing/presentation/widgets/landing_shelter_card.dart';
import 'package:woofy/features/landing/presentation/widgets/recent_dog_preview_card.dart';
import 'package:woofy/features/notifications/presentation/widgets/notifications_bell.dart';
import 'package:woofy/features/publisher/data/publisher_providers.dart';
import 'package:woofy/shared/widgets/woofy_bottom_navigation.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_circle_icon_button.dart';
import 'package:woofy/shared/widgets/woofy_promo_banner.dart';
import 'package:woofy/shared/widgets/woofy_reveal.dart';
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
    ref
      ..invalidate(publishedDogsProvider)
      ..invalidate(activePartnersProvider)
      ..invalidate(servicesProvider)
      ..invalidate(officialStoreProvider)
      ..invalidate(bannersProvider(BannerSlot.home));
    // Solo se espera el catálogo de animales: es lo que ocupa la pantalla y lo
    // que justifica el gesto. Las demás secciones se van llenando solas y
    // colgar el indicador de refresco de la más lenta lo haría sentir pesado.
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
                  onSearchPressed: () => context.push(RoutePaths.search),
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
                    // El banner de adopción queda como respaldo: si el admin
                    // todavía no cargó publicidad, Inicio no se queda mudo.
                    BannerCarousel(
                      slot: BannerSlot.home,
                      fallback: WoofyPromoBanner(
                        onTap: () => context.go(RoutePaths.dogs),
                      ),
                    ),
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
                    // Veterinarias y servicios en carrusel, debajo de los
                    // animales: la adopción sigue siendo lo primero que se ve.
                    // Cada sección desaparece entera si no hay nada que
                    // mostrar, para no dejar filas vacías en Inicio.
                    const _LandingVetsPreview(),
                    // Segunda tanda de publicidad, entre las dos secciones de
                    // aliados. Sin `fallback`: acá, si no hay nada cargado, no
                    // se muestra nada. Un respaldo inventado en el medio de la
                    // pantalla se leería como relleno.
                    const BannerCarousel(
                      slot: BannerSlot.homeSecondary,
                      padding: EdgeInsets.only(bottom: WoofySpacing.xxxl),
                    ),
                    const _LandingServicesPreview(),
                    const _LandingMerchPreview(),
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
    required this.onSearchPressed,
    required this.onAccountPressed,
    required this.onExplorePressed,
    required this.onServicesPressed,
  });

  final TextEditingController searchController;
  final VoidCallback onSearchPressed;
  final VoidCallback onAccountPressed;
  final VoidCallback onExplorePressed;
  final VoidCallback onServicesPressed;

  /// Cuánto celeste se pinta por encima del header para cubrir el rebote del
  /// scroll. 600 alcanza de sobra para el tirón más largo posible.
  static const _overscrollBleed = 600.0;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Stack(
      // El celeste se prolonga hacia arriba fuera de la caja del header. El
      // viewport lo recorta, así que no se ve nunca... salvo al hacer
      // pull-to-refresh, que es justo cuando antes aparecía el crema del
      // Scaffold y cortaba el color. Se desplaza junto con el header, así
      // que al scrollear hacia abajo desaparece con él.
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          top: -_overscrollBleed,
          left: 0,
          right: 0,
          height: _overscrollBleed,
          child: ColoredBox(color: WoofyColors.primarySoft),
        ),
        _headerBlock(context, topInset),
      ],
    );
  }

  Widget _headerBlock(BuildContext context, double topInset) {
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
              child: _HeaderBar(onAccountPressed: onAccountPressed),
            ),
            const SizedBox(height: WoofySpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WoofySpacing.xl),
              // Acá no se escribe: el campo abre el buscador general y ahí se
              // teclea. Antes se podía escribir y no pasaba absolutamente
              // nada, que es peor que no tener buscador.
              child: WoofySearchField(
                key: const ValueKey('home-search-field'),
                controller: searchController,
                readOnly: true,
                hintText: 'Buscar animales, poleras, veterinarias…',
                onTap: onSearchPressed,
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
  const _HeaderBar({required this.onAccountPressed});

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
              // El wordmark es blanco sobre transparente, así que se tiñe con
              // el azul de marca: sobre el celeste del header el blanco no se
              // leería.
              Image.asset(
                'assets/images/woofy_wordmark.png',
                key: const ValueKey('landing-logo'),
                height: 26,
                color: WoofyColors.primary,
                alignment: Alignment.centerLeft,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) => Text(
                  'Woofy',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: WoofyColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
        const NotificationsBell(),
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
      skipLoadingOnReload: true,
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

/// Veterinarias aliadas en carrusel.
///
/// Solo se dibuja con datos ya cargados: en Inicio, una fila que aparece vacía
/// y después se llena mueve todo lo de abajo mientras la persona está leyendo.
class _LandingVetsPreview extends ConsumerWidget {
  const _LandingVetsPreview();

  static const _limit = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partners =
        ref.watch(activePartnersProvider).value ?? const <Partner>[];
    if (partners.isEmpty) return const SizedBox.shrink();

    return _LandingCarouselSection(
      title: 'Veterinarias cerca tuyo',
      subtitle: 'Aliados que atienden a tu mascota.',
      onSeeAll: () => context.go(RoutePaths.vets),
      height: 240,
      itemWidth: 244,
      children: [
        for (final partner in partners.take(_limit))
          PartnerCard(
            partner: partner,
            compact: true,
            onTap: () => context.push(RoutePaths.partnerDetail(partner.slug)),
          ),
      ],
    );
  }
}

/// Servicios sueltos de todos los rubros, en carrusel.
class _LandingServicesPreview extends ConsumerWidget {
  const _LandingServicesPreview();

  static const _limit = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services =
        ref.watch(servicesProvider).value ?? const <PartnerService>[];
    if (services.isEmpty) return const SizedBox.shrink();

    return _LandingCarouselSection(
      title: 'Servicios para tu mascota',
      subtitle: 'Baños, paseos, hoteles y más.',
      onSeeAll: () => context.push(RoutePaths.services),
      height: 136,
      itemWidth: 300,
      children: [
        for (final service in services.take(_limit))
          ServiceCard(
            service: service,
            onTap: service.partnerSlug == null
                ? () {}
                : () => context.push(
                    RoutePaths.partnerReservation(service.partnerSlug!),
                    extra: service.id,
                  ),
            onOpenPartner: service.partnerSlug == null
                ? () {}
                : () => context.push(
                    RoutePaths.partnerDetail(service.partnerSlug!),
                  ),
          ),
      ],
    );
  }
}

/// Merch oficial al final del Inicio. Si la tienda sigue pendiente, falla o
/// no tiene productos, no reserva espacio ni desplaza la adopción y servicios.
class _LandingMerchPreview extends ConsumerWidget {
  const _LandingMerchPreview();

  static const _limit = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(officialStoreProvider).value;
    if (detail == null || detail.products.isEmpty) {
      return const SizedBox.shrink();
    }

    return _LandingCarouselSection(
      title: 'Merch oficial Woofy',
      subtitle: 'Tu compra ayuda a sostener adopciones siempre gratuitas.',
      onSeeAll: () => context.push(RoutePaths.store),
      height: 280,
      itemWidth: 210,
      children: [
        for (final product in detail.products.take(_limit))
          MerchProductTile(
            product: product,
            onTap: () => context.push(RoutePaths.storeProduct(product.id)),
          ),
      ],
    );
  }
}

/// Encabezado con "Ver todos" y una fila horizontal de tarjetas de ancho fijo.
class _LandingCarouselSection extends StatelessWidget {
  const _LandingCarouselSection({
    required this.title,
    required this.subtitle,
    required this.onSeeAll,
    required this.height,
    required this.itemWidth,
    required this.children,
  });

  final String title;
  final String subtitle;
  final VoidCallback onSeeAll;
  final double height;
  final double itemWidth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: WoofySpacing.xxxl),
        WoofySectionHeader(
          title: title,
          subtitle: subtitle,
          trailing: TextButton(
            onPressed: onSeeAll,
            child: const Text('Ver todos'),
          ),
        ),
        const SizedBox(height: WoofySpacing.md),
        SizedBox(
          height: height,
          child: WoofyStaggeredRow(
            itemCount: children.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: WoofySpacing.md),
            itemBuilder: (context, index) =>
                SizedBox(width: itemWidth, child: children[index]),
          ),
        ),
      ],
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
