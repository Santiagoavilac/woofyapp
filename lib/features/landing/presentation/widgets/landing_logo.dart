import 'package:flutter/material.dart';
import 'package:mi_app/core/theme/woofy_colors.dart';

class LandingLogo extends StatelessWidget {
  const LandingLogo({
    this.assetPath = 'assets/images/woofy_logo_white.png',
    super.key,
  });

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(190.0, 310.0);

        return Center(
          child: ClipRect(
            child: SizedBox(
              width: width,
              height: width * 0.43,
              child: Transform.scale(
                scale: 2.45,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  semanticLabel: 'Woofy',
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      'WOOFY',
                      key: const ValueKey('landing-logo-fallback'),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: WoofyColors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
