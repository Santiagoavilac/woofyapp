import 'package:flutter/material.dart';
import 'package:mi_app/core/theme/woofy_colors.dart';

class LandingBackground extends StatelessWidget {
  const LandingBackground({
    required this.child,
    this.patternAssetPath = 'assets/images/paw_pattern.png',
    super.key,
  });

  final Widget child;
  final String patternAssetPath;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: WoofyColors.pastelBlue,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            patternAssetPath,
            repeat: ImageRepeat.repeat,
            color: WoofyColors.white.withValues(alpha: 0.08),
            colorBlendMode: BlendMode.srcIn,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) => const CustomPaint(
              key: ValueKey('landing-paw-pattern-fallback'),
              painter: _PawPatternPainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PawPatternPainter extends CustomPainter {
  const _PawPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = WoofyColors.white.withValues(alpha: 0.09);
    const spacing = 92.0;

    for (var row = 0; row * spacing < size.height + spacing; row++) {
      for (var column = 0; column * spacing < size.width + spacing; column++) {
        final center = Offset(
          column * spacing + (row.isEven ? 18 : 62),
          row * spacing + 28,
        );
        _paintPaw(canvas, center, paint);
      }
    }
  }

  void _paintPaw(Canvas canvas, Offset center, Paint paint) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 20, height: 17),
      paint,
    );
    canvas.drawCircle(center.translate(-10, -11), 4, paint);
    canvas.drawCircle(center.translate(-3.5, -16), 4.2, paint);
    canvas.drawCircle(center.translate(4.5, -16), 4.2, paint);
    canvas.drawCircle(center.translate(11, -10), 4, paint);
  }

  @override
  bool shouldRepaint(covariant _PawPatternPainter oldDelegate) => false;
}
