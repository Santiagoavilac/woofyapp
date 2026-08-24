import 'package:flutter/material.dart';
import 'package:mi_app/core/theme/woofy_colors.dart';

enum WoofyButtonVariant { primary, secondary }

class WoofyButton extends StatelessWidget {
  const WoofyButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.variant = WoofyButtonVariant.primary,
    this.onPrimary = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final WoofyButtonVariant variant;

  /// When placed on a `primary`-colored surface (e.g. the landing hero),
  /// inverts the palette so the button stays legible: filled becomes white
  /// with primary-colored text; outlined becomes white text and border.
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callback = isLoading ? null : onPressed;
    final spinnerColor = switch (variant) {
      WoofyButtonVariant.primary =>
        onPrimary ? WoofyColors.primary : theme.colorScheme.onPrimary,
      WoofyButtonVariant.secondary =>
        onPrimary ? WoofyColors.white : theme.colorScheme.primary,
    };
    final content = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: spinnerColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    final button = switch (variant) {
      WoofyButtonVariant.primary => FilledButton(
        onPressed: callback,
        style: onPrimary
            ? (theme.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
                backgroundColor: const WidgetStatePropertyAll(
                  WoofyColors.white,
                ),
                foregroundColor: const WidgetStatePropertyAll(
                  WoofyColors.primary,
                ),
              )
            : null,
        child: content,
      ),
      WoofyButtonVariant.secondary => OutlinedButton(
        onPressed: callback,
        style: onPrimary
            ? (theme.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
                foregroundColor: const WidgetStatePropertyAll(
                  WoofyColors.white,
                ),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: WoofyColors.white),
                ),
              )
            : null,
        child: content,
      ),
    };

    if (!isExpanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
