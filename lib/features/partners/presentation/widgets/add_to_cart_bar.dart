import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/partners/data/money.dart';

/// Barra fija de compra: a la izquierda cuántas unidades y a la derecha el
/// total de lo que se está por agregar, con el contador y el botón debajo.
///
/// El total se calcula con enteros de centavos, igual que el resto de la
/// vertical: `unitPriceCents * quantity` nunca pasa por flotante.
class AddToCartBar extends StatelessWidget {
  const AddToCartBar({
    required this.unitPriceCents,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAdd,
    super.key,
  });

  final int unitPriceCents;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  /// `null` deja el botón apagado (por ejemplo, sin stock).
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            WoofySpacing.lg,
            WoofySpacing.md,
            WoofySpacing.lg,
            WoofySpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    quantity == 1 ? '1 producto' : '$quantity productos',
                    key: const ValueKey('add-bar-count'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    Money.fromCents(unitPriceCents * quantity),
                    key: const ValueKey('add-bar-total'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: WoofyColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WoofySpacing.md),
              Row(
                children: [
                  _Stepper(
                    quantity: quantity,
                    onDecrement: onDecrement,
                    onIncrement: onIncrement,
                  ),
                  const SizedBox(width: WoofySpacing.md),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('add-bar-submit'),
                      onPressed: onAdd,
                      child: const Text('Agregar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: WoofyColors.surfaceMuted,
        borderRadius: BorderRadius.circular(WoofyRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const ValueKey('add-bar-decrement'),
            tooltip: 'Quitar uno',
            // Con una unidad el menos queda apagado: bajar a cero desde acá
            // dejaría la barra ofreciendo agregar nada.
            onPressed: quantity > 1 ? onDecrement : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            key: const ValueKey('add-bar-increment'),
            tooltip: 'Agregar uno',
            onPressed: onIncrement,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
