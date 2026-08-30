import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/shared/widgets/woofy_reveal.dart';

/// Cierre celebratorio de un momento importante.
///
/// El check se **dibuja**: el trazo se escribe de punta a punta en vez de
/// aparecer hecho. Es la diferencia entre "listo" y "lo lograste", y es lo que
/// hace que el final del recorrido se sienta como un logro y no como el
/// acuse de recibo de un trámite.
class WoofyCelebration extends StatefulWidget {
  const WoofyCelebration({
    required this.title,
    required this.body,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String body;
  final List<Widget> actions;

  @override
  State<WoofyCelebration> createState() => _WoofyCelebrationState();
}

class _WoofyCelebrationState extends State<WoofyCelebration>
    with SingleTickerProviderStateMixin {
  static const _diameter = 120.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final Animation<double> _circle = _interval(0, 0.35, Curves.easeOutBack);
  late final Animation<double> _check = _interval(0.20, 0.55, Curves.easeOut);
  // Dos anillos desfasados: uno solo se lee como un borde, dos se leen como
  // un aplauso.
  late final Animation<double> _ringA = _interval(0.35, 0.70, Curves.easeOut);
  late final Animation<double> _ringB = _interval(0.44, 0.79, Curves.easeOut);
  late final Animation<double> _titleIn = _interval(0.50, 0.80, Curves.easeOut);
  late final Animation<double> _bodyIn = _interval(0.60, 0.90, Curves.easeOut);
  late final Animation<double> _actionsIn = _interval(0.70, 1, Curves.easeOut);

  final _curves = <CurvedAnimation>[];

  Animation<double> _interval(double begin, double end, Curve curve) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: curve),
    );
    _curves.add(animation);
    return animation;
  }

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    for (final curve in _curves) {
      curve.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // El logro tiene que estar escrito y visible aunque no se anime nada.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox.square(
            dimension: _diameter * 1.9,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => CustomPaint(
                painter: _RingsPainter(
                  first: _ringA.value,
                  second: _ringB.value,
                ),
                child: child,
              ),
              child: Center(
                child: ScaleTransition(
                  scale: _circle,
                  child: SizedBox.square(
                    dimension: _diameter,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: WoofyColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedBuilder(
                        animation: _check,
                        builder: (context, _) => CustomPaint(
                          painter: _CheckPainter(progress: _check.value),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: WoofySpacing.xl),
        WoofyReveal(
          animation: _titleIn,
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: WoofySpacing.md),
        WoofyReveal(
          animation: _bodyIn,
          child: Text(
            widget.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        if (widget.actions.isNotEmpty) ...[
          const SizedBox(height: WoofySpacing.xl),
          WoofyReveal(
            animation: _actionsIn,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final action in widget.actions) ...[
                  action,
                  const SizedBox(height: WoofySpacing.md),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Dibuja el check trazo a trazo con [PathMetric].
class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.34);

    final drawn = Path();
    for (final metric in path.computeMetrics()) {
      drawn.addPath(
        metric.extractPath(0, metric.length * progress),
        Offset.zero,
      );
    }

    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.08
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = WoofyColors.primary,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter({required this.first, required this.second});

  final double first;
  final double second;

  @override
  void paint(Canvas canvas, Size size) {
    _ring(canvas, size, first);
    _ring(canvas, size, second);
  }

  void _ring(Canvas canvas, Size size, double progress) {
    if (progress <= 0 || progress >= 1) return;
    final base = size.shortestSide / 2;
    canvas.drawCircle(
      size.center(Offset.zero),
      base * (0.55 + 0.45 * progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = WoofyColors.primary.withValues(alpha: 0.30 * (1 - progress)),
    );
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) =>
      oldDelegate.first != first || oldDelegate.second != second;
}
