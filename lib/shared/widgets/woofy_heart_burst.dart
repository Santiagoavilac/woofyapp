import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';

/// Celebra el momento en que algo se marca como favorito.
///
/// El corazón pega un salto corto y sale un anillo que se abre y se apaga.
/// Al desmarcar no anima: quitar algo no se celebra.
class WoofyHeartBurst extends StatefulWidget {
  const WoofyHeartBurst({
    required this.isActive,
    required this.child,
    super.key,
  });

  final bool isActive;
  final Widget child;

  @override
  State<WoofyHeartBurst> createState() => _WoofyHeartBurstState();
}

class _WoofyHeartBurstState extends State<WoofyHeartBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.28,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.28,
        end: 0.94,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0.94,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
  ]);

  @override
  void didUpdateWidget(WoofyHeartBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      if (MediaQuery.disableAnimationsOf(context)) return;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => CustomPaint(
        painter: _RingPainter(_controller.value),
        child: Transform.scale(
          scale: _scale.evaluate(_controller),
          child: child,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // En reposo (0) y al terminar (1) no queda nada dibujado.
    if (progress <= 0 || progress >= 1) return;
    final base = size.shortestSide / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = WoofyColors.accent.withValues(alpha: 0.35 * (1 - progress));
    canvas.drawCircle(
      size.center(Offset.zero),
      base * (0.2 + 1.7 * progress),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
