import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/banners/data/banner_models.dart';
import 'package:woofy/features/banners/presentation/widgets/banner_carousel.dart';
import 'package:woofy/features/partners/data/cart_provider.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';
import 'package:woofy/features/partners/presentation/widgets/partner_card.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_bottom_navigation.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_filter_chips.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_refresh.dart';
import 'package:woofy/shared/widgets/woofy_search_field.dart';

/// Listado de veterinarias aliadas, con búsqueda y filtro por ciudad.
class VetsPage extends ConsumerStatefulWidget {
  const VetsPage({super.key});

  @override
  ConsumerState<VetsPage> createState() => _VetsPageState();
}

class _VetsPageState extends ConsumerState<VetsPage> with WoofyRefreshMixin {
  final _searchController = TextEditingController();
  String _query = '';

  static const _all = 'todas';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Future<void> onWoofyRefresh() async {
    ref.invalidate(activePartnersProvider);
    await ref.read(activePartnersProvider.future);
  }

  List<Partner> _applyFilters(List<Partner> partners) {
    final query = _query.trim().toLowerCase();
    final city = ref.watch(selectedPartnerCityProvider);
    return partners.where((partner) {
      if (city != null && partner.city != city) return false;
      if (query.isEmpty) return true;
      final haystack = [
        partner.name,
        partner.city ?? '',
        partner.description ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vets = ref.watch(activePartnersProvider);
    final cities = ref.watch(availablePartnerCitiesProvider);
    final selectedCity = ref.watch(selectedPartnerCityProvider);

    return PopScope<Object?>(
      // Rama del shell, no ruta apilada: el back del sistema vuelve a Inicio.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RoutePaths.landing);
      },
      child: Scaffold(
        appBar: WoofyAppBar(
          title: 'Veterinarias',
          actions: const [_CartButton()],
        ),
        body: SafeArea(
          child: vets.when(
            skipLoadingOnRefresh: true,
            loading: () =>
                const WoofyLoading(message: 'Cargando veterinarias…'),
            error: (error, stackTrace) => WoofyError(
              message: 'No pudimos cargar las veterinarias.',
              onRetry: () => ref.invalidate(activePartnersProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const WoofyEmptyState(
                  icon: Icons.local_hospital_outlined,
                  title: 'Todavía no hay veterinarias',
                  message:
                      'Estamos sumando veterinarias aliadas. Volvé a mirar '
                      'en unos días.',
                );
              }
              final results = _applyFilters(items);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal = constraints.maxWidth >= 600
                      ? WoofySpacing.xxxl
                      : WoofySpacing.lg;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: CustomScrollView(
                        slivers: [
                          WoofyRefreshControl(onRefresh: refreshData),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontal,
                              WoofySpacing.xl,
                              horizontal,
                              WoofySpacing.md,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cuidá a tu compañero',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: WoofySpacing.xs),
                                  Text(
                                    'Veterinarias aliadas con productos y '
                                    'turnos que reservás desde acá.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: WoofySpacing.lg),
                                  WoofySearchField(
                                    controller: _searchController,
                                    hintText: 'Buscar por nombre o ciudad',
                                    onChanged: (value) =>
                                        setState(() => _query = value),
                                  ),
                                  // Sin `fallback`: si el admin no cargó
                                  // publicidad, la fila no existe.
                                  const BannerCarousel(
                                    slot: BannerSlot.vets,
                                    padding: EdgeInsets.only(
                                      top: WoofySpacing.lg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (cities.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: WoofySpacing.lg,
                                ),
                                child: WoofyFilterChips(
                                  options: [
                                    const WoofyFilterOption(
                                      value: _all,
                                      label: 'Todas',
                                    ),
                                    for (final city in cities)
                                      WoofyFilterOption(
                                        value: city,
                                        label: city,
                                      ),
                                  ],
                                  selected: selectedCity ?? _all,
                                  onSelected: (value) => ref
                                      .read(
                                        selectedPartnerCityProvider.notifier,
                                      )
                                      .select(value == _all ? null : value),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontal,
                                  ),
                                ),
                              ),
                            ),
                          if (results.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: WoofyEmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'Sin resultados',
                                message:
                                    'No encontramos veterinarias con esa '
                                    'búsqueda.',
                                actionLabel: 'Limpiar filtros',
                                onAction: _clearFilters,
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontal,
                                0,
                                horizontal,
                                WoofySpacing.xxl +
                                    WoofyBottomNavigation.reservedHeight +
                                    MediaQuery.paddingOf(context).bottom,
                              ),
                              sliver: SliverList.separated(
                                itemCount: results.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: WoofySpacing.lg),
                                itemBuilder: (context, index) {
                                  final partner = results[index];
                                  return PartnerCard(
                                    partner: partner,
                                    onTap: () => context.push(
                                      RoutePaths.partnerDetail(partner.slug),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
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

  void _clearFilters() {
    ref.read(selectedPartnerCityProvider.notifier).select(null);
    setState(() {
      _searchController.clear();
      _query = '';
    });
  }
}

/// Ícono del carrito con globo de cantidad.
class _CartButton extends ConsumerWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartItemCountProvider);
    return IconButton(
      key: const ValueKey('vet-cart-button'),
      tooltip: 'Mi carrito',
      onPressed: () => context.push(RoutePaths.cart),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_bag_outlined),
          if (count > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: const BoxDecoration(
                  color: WoofyColors.accent,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: WoofyColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
