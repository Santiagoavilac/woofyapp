import 'package:flutter/material.dart';
import 'package:mi_app/core/theme/woofy_colors.dart';

class LandingHeaderNav extends StatelessWidget {
  const LandingHeaderNav({
    required this.onDogsPressed,
    required this.onAccountPressed,
    super.key,
  });

  final VoidCallback onDogsPressed;
  final VoidCallback onAccountPressed;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextButton.styleFrom(
      foregroundColor: WoofyColors.white,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    );

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      children: [
        TextButton(
          onPressed: onDogsPressed,
          style: baseStyle,
          child: const Text('Perros'),
        ),
        TextButton(
          onPressed: onAccountPressed,
          style: baseStyle.copyWith(
            backgroundColor: WidgetStatePropertyAll(
              WoofyColors.white.withValues(alpha: 0.14),
            ),
            shape: const WidgetStatePropertyAll(
              StadiumBorder(side: BorderSide(color: Color(0x66FFFFFF))),
            ),
          ),
          child: const Text('Mi cuenta'),
        ),
      ],
    );
  }
}
