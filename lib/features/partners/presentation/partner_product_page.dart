import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/partners/data/cart_provider.dart';
import 'package:woofy/features/partners/data/money.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';
import 'package:woofy/features/partners/presentation/widgets/add_to_cart_bar.dart';
import 'package:woofy/features/partners/presentation/widgets/partner_card.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_refresh.dart';
import 'package:woofy/shared/widgets/woofy_section_header.dart';

/// Detalle de un producto: foto, descripción, cuánto agregar y qué más vende
/// la misma veterinaria.
class PartnerProductPage extends ConsumerStatefulWidget {
  const PartnerProductPage({
    required this.slug,
    required this.productId,
    super.key,
  });

  final String slug;
  final String productId;

  @override
  ConsumerState<PartnerProductPage> createState() => _VetProductPageState();
}

class _VetProductPageState extends ConsumerState<PartnerProductPage>
    with WoofyRefreshMixin {
  int _quantity = 1;

  @override
  Future<void> onWoofyRefresh() async {
    ref.invalidate(partnerDetailProvider(widget.slug));
    await ref.read(partnerDetailProvider(widget.slug).future);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(partnerDetailProvider(widget.slug));

    return detail.when(
      skipLoadingOnReload: true,
      loading: () => Scaffold(
        appBar: WoofyAppBar(
          title: 'Producto',
          backFallbackLocation: RoutePaths.partnerDetail(widget.slug),
        ),
        body: const WoofyLoading(message: 'Cargando producto…'),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: WoofyAppBar(
          title: 'Producto',
          backFallbackLocation: RoutePaths.partnerDetail(widget.slug),
        ),
        body: WoofyError(
          message: 'No pudimos cargar este producto.',
          onRetry: () => ref.invalidate(partnerDetailProvider(widget.slug)),
        ),
      ),
      data: (data) {
        final product = data?.products
            .where((item) => item.id == widget.productId)
            .firstOrNull;
        if (data == null || product == null) {
          return Scaffold(
            appBar: WoofyAppBar(
              title: 'Producto',
              backFallbackLocation: RoutePaths.partnerDetail(widget.slug),
            ),
            body: WoofyEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Producto no disponible',
              message: 'Puede que la veterinaria lo haya sacado del catálogo.',
              actionLabel: 'Ver el catálogo',
              onAction: () => context.go(RoutePaths.partnerDetail(widget.slug)),
            ),
          );
        }
        return _buildProduct(data, product);
      },
    );
  }

  Widget _buildProduct(PartnerDetail detail, PartnerProduct product) {
    final theme = Theme.of(context);
    final others = detail.products
        .where((item) => item.id != product.id)
        .toList();
    final inCart = ref
        .watch(cartProvider)[detail.partner.id]
        ?.lines
        .where((line) => line.productId == product.id)
        .fold(0, (total, line) => total + line.quantity);

    return Scaffold(
      appBar: WoofyAppBar(
        title: product.name,
        backFallbackLocation: RoutePaths.partnerDetail(widget.slug),
        actions: [
          IconButton(
            key: const ValueKey('vet-product-cart-button'),
            tooltip: 'Mi carrito',
            onPressed: () => context.push(RoutePaths.cart),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            WoofyRefreshControl(onRefresh: refreshData),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                WoofySpacing.lg,
                WoofySpacing.lg,
                WoofySpacing.lg,
                WoofySpacing.xxl,
              ),
              sliver: SliverList.list(
                children: [
                  ClipRRect(
                    borderRadius: WoofyRadius.cardLargeAll,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ColoredBox(
                        color: WoofyColors.surfaceMuted,
                        child: PartnerImage(
                          url: product.imageUrl,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: WoofySpacing.lg),
                  Text(product.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: WoofySpacing.xs),
                  Text(
                    detail.partner.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: WoofySpacing.md),
                  Text(
                    Money.fromCents(product.priceCents),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: WoofyColors.primary,
                    ),
                  ),
                  if (!product.isAvailable) ...[
                    const SizedBox(height: WoofySpacing.xs),
                    Text(
                      'Sin stock por ahora',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  if (inCart != null && inCart > 0) ...[
                    const SizedBox(height: WoofySpacing.xs),
                    Text(
                      inCart == 1
                          ? 'Ya tenés 1 en el carrito'
                          : 'Ya tenés $inCart en el carrito',
                      key: const ValueKey('vet-product-in-cart'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (product.description case final description?) ...[
                    const SizedBox(height: WoofySpacing.lg),
                    Text('Descripción', style: theme.textTheme.titleSmall),
                    const SizedBox(height: WoofySpacing.xs),
                    Text(description, style: theme.textTheme.bodyLarge),
                  ],
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: WoofySpacing.xxl),
                    const WoofySectionHeader(
                      title: 'Otras personas también compraron',
                    ),
                    const SizedBox(height: WoofySpacing.md),
                    SizedBox(
                      height: 208,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: others.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: WoofySpacing.md),
                        itemBuilder: (context, index) => _RelatedProductCard(
                          product: others[index],
                          // `pushReplacement`: encadenar productos apilaría una
                          // pantalla por cada toque y el back tendría que deshacer
                          // toda la caminata para volver al perfil.
                          onTap: () => context.pushReplacement(
                            RoutePaths.partnerProduct(
                              widget.slug,
                              others[index].id,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AddToCartBar(
        unitPriceCents: product.priceCents,
        quantity: _quantity,
        onDecrement: () => setState(() => _quantity -= 1),
        onIncrement: () => setState(() => _quantity += 1),
        onAdd: product.isAvailable
            ? () => _addToCart(detail.partner, product)
            : null,
      ),
    );
  }

  void _addToCart(Partner partner, PartnerProduct product) {
    ref.read(cartProvider.notifier).add(partner, product, quantity: _quantity);
    setState(() => _quantity = 1);
    context.push(RoutePaths.cart);
  }
}

class _RelatedProductCard extends StatelessWidget {
  const _RelatedProductCard({required this.product, required this.onTap});

  final PartnerProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 148,
      child: InkWell(
        key: ValueKey('vet-related-${product.id}'),
        onTap: onTap,
        borderRadius: WoofyRadius.cardLargeAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: WoofyRadius.cardLargeAll,
              child: SizedBox(
                height: 132,
                width: 148,
                child: ColoredBox(
                  color: WoofyColors.surfaceMuted,
                  child: PartnerImage(
                    url: product.imageUrl,
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: WoofySpacing.sm),
            Text(
              product.name,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              Money.fromCents(product.priceCents),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: WoofyColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
