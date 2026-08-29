import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/partners/data/cart_provider.dart';
import 'package:woofy/features/partners/data/money.dart';

/// Resumen del carrito anclado abajo: cuántas unidades hay y cuánto suman,
/// con acceso directo al carrito. Se esconde solo cuando no hay nada cargado.
class CartSummaryBar extends ConsumerWidget {
  const CartSummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groups = ref.watch(cartProvider).values;
    final count = groups.fold(0, (total, group) => total + group.itemCount);
    if (count == 0) return const SizedBox.shrink();

    final totalCents = groups.fold(
      0,
      (total, group) => total + group.totalCents,
    );

    return Material(
      color: theme.colorScheme.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(WoofySpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      count == 1 ? '1 producto' : '$count productos',
                      key: const ValueKey('cart-summary-count'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      Money.fromCents(totalCents),
                      key: const ValueKey('cart-summary-total'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: WoofyColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: WoofySpacing.md),
              FilledButton.icon(
                key: const ValueKey('cart-summary-open'),
                onPressed: () => context.push(RoutePaths.cart),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Ver carrito'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
