import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';

/// White circular icon button that floats over coloured surfaces: the home
/// header band and the dog detail hero.
class WoofyCircleIconButton extends StatelessWidget {
  const WoofyCircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WoofyColors.white,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: WoofyColors.textPrimary,
        icon: Icon(icon),
      ),
    );
  }
}
