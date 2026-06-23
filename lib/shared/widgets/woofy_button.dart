import 'package:flutter/material.dart';

enum WoofyButtonVariant { primary, secondary }

class WoofyButton extends StatelessWidget {
  const WoofyButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.variant = WoofyButtonVariant.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final WoofyButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;
    final content = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: variant == WoofyButtonVariant.primary
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
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
        child: content,
      ),
      WoofyButtonVariant.secondary => OutlinedButton(
        onPressed: callback,
        child: content,
      ),
    };

    if (!isExpanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
