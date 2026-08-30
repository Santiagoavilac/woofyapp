import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/partners/data/money.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';
import 'package:woofy/features/partners/presentation/widgets/partner_card.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_refresh.dart';

class MerchStorePage extends ConsumerStatefulWidget {
  const MerchStorePage({super.key});

  @override
  ConsumerState<MerchStorePage> createState() => _MerchStorePageState();
}

class _MerchStorePageState extends ConsumerState<MerchStorePage>
    with WoofyRefreshMixin {
  @override
  Future<void> onWoofyRefresh() async {
    ref.invalidate(officialStoreProvider);
    await ref.read(officialStoreProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(officialStoreProvider);
    return Scaffold(
      appBar: WoofyAppBar(
        title: 'Tienda Woofy',
        backFallbackLocation: RoutePaths.landing,
      ),
      body: store.when(
        skipLoadingOnReload: true,
        loading: () => const WoofyLoading(message: 'Cargando la tienda…'),
        error: (error, stackTrace) => WoofyError(
          message: 'No pudimos cargar la tienda.',
          onRetry: () => ref.invalidate(officialStoreProvider),
        ),
        data: (detail) {
          if (detail == null || detail.products.isEmpty) {
            return WoofyEmptyState(
              icon: Icons.checkroom_outlined,
              title: 'La tienda se está preparando',
              message: 'Volvé pronto para conocer la merch oficial de Woofy.',
              actionLabel: 'Reintentar',
              onAction: () => ref.invalidate(officialStoreProvider),
            );
          }
          return _StoreContent(detail: detail, onRefresh: refreshData);
        },
      ),
    );
  }
}

class _StoreContent extends StatelessWidget {
  const _StoreContent({required this.detail, required this.onRefresh});

  final PartnerDetail detail;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        WoofyRefreshControl(onRefresh: onRefresh),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            WoofySpacing.lg,
            WoofySpacing.lg,
            WoofySpacing.lg,
            WoofySpacing.md,
          ),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(WoofySpacing.xl),
              decoration: const BoxDecoration(
                color: WoofyColors.primarySoft,
                borderRadius: WoofyRadius.cardLargeAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.pets_rounded, color: WoofyColors.primary),
                  const SizedBox(height: WoofySpacing.md),
                  Text(
                    'Vestite con propósito',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: WoofySpacing.sm),
                  Text(
                    detail.partner.description ??
                        'Cada compra ayuda a sostener Woofy. Adoptar un perro '
                            'continúa siendo completamente gratuito.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: WoofySpacing.sm),
                  Text(
                    'Pago, retiro o delivery en Santa Cruz se coordinan por WhatsApp.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            WoofySpacing.lg,
            WoofySpacing.md,
            WoofySpacing.lg,
            WoofySpacing.xxl,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: 294,
              crossAxisSpacing: WoofySpacing.md,
              mainAxisSpacing: WoofySpacing.md,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => MerchProductTile(
                product: detail.products[index],
                onTap: () => context.push(
                  RoutePaths.storeProduct(detail.products[index].id),
                ),
              ),
              childCount: detail.products.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// Etiqueta que hermana la foto de la tarjeta con la del detalle.
///
/// La tarjeta vive en dos lugares (el carrusel de Inicio y la grilla de la
/// tienda) pero nunca en la ruta visible al mismo tiempo, así que el id del
/// producto alcanza para que la etiqueta sea única.
String merchPhotoHeroTag(String productId) => 'merch-photo-$productId';

class MerchProductTile extends StatelessWidget {
  const MerchProductTile({
    required this.product,
    required this.onTap,
    super.key,
  });

  final PartnerProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('merch-product-${product.id}'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: merchPhotoHeroTag(product.id),
                child: ColoredBox(
                  color: WoofyColors.surfaceMuted,
                  child: PartnerImage(
                    url: product.imageUrl,
                    icon: Icons.checkroom_outlined,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(WoofySpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: WoofySpacing.xs),
                  Text(
                    product.isAvailable
                        ? Money.fromCents(product.priceCents)
                        : 'Sin stock',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: product.isAvailable
                          ? WoofyColors.primary
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
