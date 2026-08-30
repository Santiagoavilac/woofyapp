import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/merch/presentation/merch_store_page.dart';
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

class MerchProductPage extends ConsumerStatefulWidget {
  const MerchProductPage({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<MerchProductPage> createState() => _MerchProductPageState();
}

class _MerchProductPageState extends ConsumerState<MerchProductPage> {
  PartnerProductVariant? _variant;
  int _quantity = 1;
  int _photo = 0;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(officialStoreProvider);
    return store.when(
      skipLoadingOnReload: true,
      loading: () => Scaffold(
        appBar: _appBar('Producto'),
        body: const WoofyLoading(message: 'Cargando producto…'),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: _appBar('Producto'),
        body: WoofyError(
          message: 'No pudimos cargar este producto.',
          onRetry: () => ref.invalidate(officialStoreProvider),
        ),
      ),
      data: (detail) {
        final product = detail?.products
            .where((item) => item.id == widget.productId)
            .firstOrNull;
        if (detail == null || product == null) {
          return Scaffold(
            appBar: _appBar('Producto'),
            body: WoofyEmptyState(
              icon: Icons.checkroom_outlined,
              title: 'Producto no disponible',
              message: 'Puede que haya sido retirado de la tienda.',
              actionLabel: 'Volver a la tienda',
              onAction: () => context.go(RoutePaths.store),
            ),
          );
        }
        return _content(detail.partner, product);
      },
    );
  }

  PreferredSizeWidget _appBar(String title) =>
      WoofyAppBar(title: title, backFallbackLocation: RoutePaths.store);

  Widget _content(Partner store, PartnerProduct product) {
    final theme = Theme.of(context);
    final images = product.imageUrls.isEmpty
        ? <String?>[product.imageUrl]
        : product.imageUrls.cast<String?>().toList();
    final availableVariants = product.variants
        .where((variant) => variant.isActive)
        .toList();
    final selectedStock = _variant?.stock ?? 0;
    final visibleQuantity = selectedStock > 0
        ? _quantity.clamp(1, selectedStock).toInt()
        : 1;

    return Scaffold(
      appBar: _appBar(product.name),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          WoofySpacing.lg,
          WoofySpacing.lg,
          WoofySpacing.lg,
          WoofySpacing.xxl,
        ),
        children: [
          ClipRRect(
            borderRadius: WoofyRadius.cardLargeAll,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (value) => setState(() => _photo = value),
                    itemBuilder: (context, index) {
                      final photo = ColoredBox(
                        color: WoofyColors.surfaceMuted,
                        child: PartnerImage(
                          url: images[index],
                          icon: Icons.checkroom_outlined,
                        ),
                      );
                      // Solo la portada viaja desde la tarjeta: es la foto que
                      // el usuario venía mirando. Poner la etiqueta en todas
                      // duplicaría el tag apenas pase de página.
                      return index == 0
                          ? Hero(
                              tag: merchPhotoHeroTag(product.id),
                              child: photo,
                            )
                          : photo;
                    },
                  ),
                  if (images.length > 1)
                    Positioned(
                      right: WoofySpacing.md,
                      bottom: WoofySpacing.md,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(WoofyRadius.pill),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WoofySpacing.sm,
                            vertical: WoofySpacing.xs,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              '${_photo + 1}/${images.length}',
                              key: ValueKey(_photo),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: WoofySpacing.lg),
          Text(product.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: WoofySpacing.sm),
          Text(
            Money.fromCents(product.priceCents),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: WoofyColors.primary,
            ),
          ),
          if (product.description case final description?) ...[
            const SizedBox(height: WoofySpacing.lg),
            Text(description, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: WoofySpacing.xl),
          Text('Elegí tu talle', style: theme.textTheme.titleMedium),
          const SizedBox(height: WoofySpacing.sm),
          Wrap(
            spacing: WoofySpacing.sm,
            runSpacing: WoofySpacing.sm,
            children: [
              for (final variant in availableVariants)
                ChoiceChip(
                  key: ValueKey('merch-size-${variant.id}'),
                  label: Text(
                    variant.stock == 0
                        ? '${variant.sizeLabel} · Sin stock'
                        : variant.sizeLabel,
                  ),
                  selected: _variant?.id == variant.id,
                  onSelected: variant.stock == 0
                      ? null
                      : (_) => setState(() {
                          _variant = variant;
                          _quantity = 1;
                        }),
                ),
            ],
          ),
          if (availableVariants.isEmpty) ...[
            const SizedBox(height: WoofySpacing.sm),
            Text(
              'No hay talles disponibles por ahora.',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: WoofySpacing.xl),
          const Text(
            'Tu compra ayuda a sostener Woofy. La adopción es gratuita y no '
            'depende de comprar productos.',
          ),
          const SizedBox(height: WoofySpacing.sm),
          const Text(
            'El pago y la entrega se coordinan por WhatsApp al confirmar el pedido.',
          ),
        ],
      ),
      bottomNavigationBar: AddToCartBar(
        unitPriceCents: product.priceCents,
        quantity: visibleQuantity,
        onDecrement: () => setState(() => _quantity -= 1),
        onIncrement: selectedStock > 0 && visibleQuantity < selectedStock
            ? () => setState(() => _quantity += 1)
            : null,
        onAdd: _variant == null
            ? null
            : () => _addToCart(
                store: store,
                product: product,
                variant: _variant!,
                quantity: visibleQuantity,
              ),
      ),
    );
  }

  void _addToCart({
    required Partner store,
    required PartnerProduct product,
    required PartnerProductVariant variant,
    required int quantity,
  }) {
    ref
        .read(cartProvider.notifier)
        .add(store, product, quantity: quantity, variant: variant);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('${product.name} · Talle ${variant.sizeLabel}'),
          action: SnackBarAction(
            label: 'Ver carrito',
            onPressed: () => context.push(RoutePaths.cart),
          ),
        ),
      );
  }
}
