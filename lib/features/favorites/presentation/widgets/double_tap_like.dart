import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/features/favorites/data/favorites_providers.dart';

/// Doble toque sobre la foto para guardar el perro, como en Instagram.
///
/// El gesto ya está aprendido: nadie tiene que explicarlo. Y como el corazón
/// grande sale sobre la foto misma, guardar deja de ser tocar un botón chiquito
/// en una esquina y pasa a ser un gesto sobre el perro.
///
/// Solo escucha el doble toque, así que no le roba el arrastre horizontal al
/// carrusel ni el toque simple a lo que tenga debajo.
class DoubleTapLike extends ConsumerStatefulWidget {
  const DoubleTapLike({required this.dogId, required this.child, super.key});

  final String dogId;
  final Widget child;

  @override
  ConsumerState<DoubleTapLike> createState() => _DoubleTapLikeState();
}

class _DoubleTapLikeState extends ConsumerState<DoubleTapLike>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );

  // Entra de golpe, se pasa de largo, se acomoda y recién ahí se va. El
  // "pasarse de largo" es lo que se lee como entusiasmo.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.2,
        end: 1.15,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 28,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.15,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 12,
    ),
    TweenSequenceItem(tween: ConstantTween(1), weight: 40),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.25,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 20,
    ),
  ]).animate(_controller);

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
    TweenSequenceItem(tween: ConstantTween(1), weight: 65),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    // El corazón sale siempre, incluso si ya era favorito: el gesto tiene que
    // contestar algo, si no parece que la app no lo escuchó.
    HapticFeedback.lightImpact();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
    ref.read(favoriteMutationProvider.notifier).like(widget.dogId);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Transparente y no opaco: lo de abajo sigue recibiendo sus propios
      // gestos, este solo se queda con el doble toque.
      behavior: HitTestBehavior.translucent,
      onDoubleTap: _onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          // Sin `IgnorePointer` el corazón se comería el toque siguiente
          // mientras se desvanece.
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // Se mira la opacidad y no el estado del controlador: al
                // terminar queda en `completed`, no en `dismissed`, y el
                // corazón se quedaba invisible pero montado para siempre.
                final opacity = _opacity.value.clamp(0.0, 1.0);
                if (opacity == 0) return const SizedBox.shrink();
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 108,
                      color: WoofyColors.white,
                      shadows: [
                        Shadow(color: Color(0x59000000), blurRadius: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
