import 'package:flutter/material.dart';

/// Hunde levemente su contenido mientras el dedo está apoyado.
///
/// Responde una sola pregunta: "¿toqué esto?". Baja rápido (90 ms) y vuelve
/// más lento pasándose apenas del tamaño original (160 ms): ese rebote al
/// soltar es lo que se lee como "vivo" y no como una imagen que se encogió.
///
/// Usa [Listener] y no [GestureDetector] a propósito: no compite en la arena
/// de gestos, así que no le roba el tap al `InkWell` de adentro ni frena el
/// scroll horizontal de los carruseles.
class WoofyPressable extends StatefulWidget {
  const WoofyPressable({
    required this.child,
    this.pressedScale = 0.97,
    super.key,
  });

  final Widget child;
  final double pressedScale;

  @override
  State<WoofyPressable> createState() => _WoofyPressableState();
}

class _WoofyPressableState extends State<WoofyPressable>
    with SingleTickerProviderStateMixin {
  /// Vuelta con rebote: la curva se pasa de 1, y como el tween va de 1 a
  /// [WoofyPressable.pressedScale], pasarse se traduce en crecer un poco por
  /// encima del tamaño en reposo antes de asentarse.
  static const _rebound = Cubic(0.22, 2.8, 0.6, 1);

  /// Las curvas se pasan en cada llamada en vez de vivir en un
  /// `CurvedAnimation`: su `reverseCurve` solo aplica si el controller llegó a
  /// `completed`, y acá se suelta el dedo en cualquier momento del camino.
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Margen negativo: es el espacio donde vive el rebote.
      lowerBound: -0.6,
      upperBound: 1,
      value: 0,
    );
    _scale = Tween<double>(
      begin: 1,
      end: widget.pressedScale,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sin movimiento no hay nada que aportar: el `InkWell` de adentro sigue
    // dando su propio feedback.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return Listener(
      onPointerDown: (_) => _controller.animateTo(
        1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
      ),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }

  void _release() => _controller.animateTo(
    0,
    duration: const Duration(milliseconds: 160),
    curve: _rebound,
  );
}
