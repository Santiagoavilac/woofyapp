import 'package:flutter/material.dart';

/// La foto de un perro volando de la tarjeta a su ficha.
///
/// Existe como widget propio por dos motivos que no son obvios:
///
/// 1. `Hero` no mira `MediaQuery.disableAnimationsOf`. Con movimiento reducido
///    hay que saltear el vuelo a mano, si no la foto sigue viajando.
/// 2. Los dos extremos tienen esquinas distintas (la tarjeta redondea 22, la
///    banda de la ficha 28). Sin `flightShuttleBuilder` propio el vuelo se ve
///    con las esquinas del destino desde el primer cuadro.
class WoofyPhotoHero extends StatelessWidget {
  const WoofyPhotoHero({
    required this.tag,
    required this.child,
    this.enabled = true,
    this.fromRadius = 22,
    this.toRadius = 28,
    super.key,
  });

  final String tag;
  final Widget child;

  /// Apagado deja pasar el `child` pelado.
  ///
  /// Dos `Hero` con la misma etiqueta en una misma ruta rompen el vuelo, así
  /// que quien pinta la foto decide si le toca volar.
  final bool enabled;

  final double fromRadius;
  final double toRadius;

  @override
  Widget build(BuildContext context) {
    if (!enabled || MediaQuery.disableAnimationsOf(context)) return child;
    return Hero(
      tag: tag,
      flightShuttleBuilder:
          (flightContext, animation, direction, fromContext, toContext) {
            final push = direction == HeroFlightDirection.push;
            final begin = push ? fromRadius : toRadius;
            final end = push ? toRadius : fromRadius;
            // El widget que se pinta durante el vuelo es el del destino: es el
            // que ya tiene el tamaño y el recorte con los que va a aterrizar.
            final hero = (push ? toContext : fromContext).widget as Hero;
            final radius = Tween<double>(begin: begin, end: end).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            return AnimatedBuilder(
              animation: radius,
              builder: (context, _) => ClipRRect(
                borderRadius: BorderRadius.circular(radius.value),
                child: hero.child,
              ),
            );
          },
      child: child,
    );
  }
}
