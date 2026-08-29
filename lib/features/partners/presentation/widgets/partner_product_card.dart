import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/partners/data/money.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/presentation/widgets/partner_card.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';

/// Producto del catálogo de una veterinaria, con su precio y el botón de
/// agregar al carrito.
class PartnerProductCard extends StatelessWidget {
  const PartnerProductCard({
    required this.product,
    required this.onAdd,
    required this.onOpen,
    this.inCart = 0,
    super.key,
  });

  final PartnerProduct product;
  final VoidCallback onAdd;

  /// Abre el detalle del producto. El `+` sigue siendo el atajo para sumar sin
  /// salir del perfil.
  final VoidCallback onOpen;

  /// Unidades ya cargadas en el carrito, para dar feedback sin salir del perfil.
  final int inCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = product.isAvailable;

    return WoofyCard(
      key: ValueKey('vet-product-${product.id}'),
      tapKey: ValueKey('vet-product-${product.id}-tap'),
      onTap: onOpen,
      padding: const EdgeInsets.all(WoofySpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: WoofyRadius.controlAll,
            child: SizedBox(
              width: 72,
              height: 72,
              child: ColoredBox(
                color: WoofyColors.surfaceMuted,
                child: PartnerImage(
                  url: product.imageUrl,
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(width: WoofySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.description case final description?) ...[
                  const SizedBox(height: WoofySpacing.xs),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: WoofySpacing.sm),
                Row(
                  children: [
                    Text(
                      Money.fromCents(product.priceCents),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: WoofyColors.primary,
                      ),
                    ),
                    if (inCart > 0) ...[
                      const SizedBox(width: WoofySpacing.sm),
                      Text(
                        '$inCart en el carrito',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: WoofySpacing.sm),
          IconButton.filled(
            key: ValueKey('vet-product-add-${product.id}'),
            tooltip: available ? 'Agregar al carrito' : 'Sin stock',
            onPressed: available ? onAdd : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
