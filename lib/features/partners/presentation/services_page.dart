import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/banners/data/banner_models.dart';
import 'package:woofy/features/banners/presentation/widgets/banner_carousel.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';
import 'package:woofy/features/partners/presentation/widgets/service_card.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_filter_chips.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_refresh.dart';
import 'package:woofy/shared/widgets/woofy_search_field.dart';

/// Servicios de todos los aliados: paseos, baños, hoteles, adiestramiento.
///
/// Lista servicios y no negocios porque es lo que la persona está buscando.
/// El perfil del aliado sigue existiendo y se llega desde cada tarjeta.
class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage>
    with WoofyRefreshMixin {
  final _searchController = TextEditingController();
  String _query = '';

  static const _all = 'todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Future<void> onWoofyRefresh() async {
    ref.invalidate(servicesProvider);
    await ref.read(servicesProvider.future);
  }

  List<PartnerService> _applyFilters(List<PartnerService> services) {
    final query = _query.trim().toLowerCase();
    final kind = ref.watch(selectedServiceKindProvider);
    return services.where((service) {
      if (kind != null && !service.kinds.contains(kind)) return false;
      if (query.isEmpty) return true;
      final haystack = [
        service.name,
        service.description ?? '',
        service.partnerName ?? '',
        service.partnerCity ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _clearFilters() {
    ref.read(selectedServiceKindProvider.notifier).select(null);
    setState(() {
      _searchController.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final kinds = ref.watch(availableServiceKindsProvider);
    final selectedKind = ref.watch(selectedServiceKindProvider);

    return BackFallbackScope(
      fallbackLocation: RoutePaths.landing,
      child: Scaffold(
        appBar: const WoofyAppBar(
          title: 'Servicios',
          backFallbackLocation: RoutePaths.landing,
        ),
        body: SafeArea(
          child: services.when(
            skipLoadingOnRefresh: true,
            loading: () => const WoofyLoading(message: 'Cargando servicios…'),
            error: (error, stackTrace) => WoofyError(
              message: 'No pudimos cargar los servicios.',
              onRetry: () => ref.invalidate(servicesProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const WoofyEmptyState(
                  icon: Icons.pets_rounded,
                  title: 'Todavía no hay servicios',
                  message:
                      'Estamos sumando paseadores, peluquerías y hoteles. '
                      'Volvé a mirar en unos días.',
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
                                    'Todo lo que tu perro necesita',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: WoofySpacing.xs),
                                  Text(
                                    'Paseos, baños, hoteles y más, de aliados '
                                    'que ya trabajan con Woofy.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: WoofySpacing.lg),
                                  WoofySearchField(
                                    controller: _searchController,
                                    hintText: 'Buscar un servicio',
                                    onChanged: (value) =>
                                        setState(() => _query = value),
                                  ),
                                  const BannerCarousel(
                                    slot: BannerSlot.services,
                                    padding: EdgeInsets.only(
                                      top: WoofySpacing.lg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (kinds.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: WoofySpacing.lg,
                                ),
                                child: WoofyFilterChips(
                                  options: [
                                    const WoofyFilterOption(
                                      value: _all,
                                      label: 'Todos',
                                    ),
                                    for (final kind in kinds)
                                      WoofyFilterOption(
                                        value: kind.id,
                                        label: kind.label,
                                      ),
                                  ],
                                  selected: selectedKind?.id ?? _all,
                                  onSelected: (value) => ref
                                      .read(
                                        selectedServiceKindProvider.notifier,
                                      )
                                      .select(
                                        value == _all
                                            ? null
                                            : PartnerCategory.tryParse(value),
                                      ),
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
                                    'No encontramos servicios con esa búsqueda.',
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
                                    MediaQuery.paddingOf(context).bottom,
                              ),
                              sliver: SliverList.separated(
                                itemCount: results.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: WoofySpacing.md),
                                itemBuilder: (context, index) {
                                  final service = results[index];
                                  final slug = service.partnerSlug;
                                  return ServiceCard(
                                    service: service,
                                    onTap: slug == null
                                        ? () {}
                                        : () => context.push(
                                            RoutePaths.partnerReservation(slug),
                                            extra: service.id,
                                          ),
                                    onOpenPartner: slug == null
                                        ? () {}
                                        : () => context.push(
                                            RoutePaths.partnerDetail(slug),
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
}
