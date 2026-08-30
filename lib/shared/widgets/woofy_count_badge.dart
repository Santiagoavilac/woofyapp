import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';

/// Globo de novedades sin leer sobre un ícono.
///
/// Aparece con un salto corto en vez de encenderse de la nada: si el contador
/// sube mientras el usuario mira la pantalla, tiene que enterarse.
class WoofyCountBadge extends StatelessWidget {
  const WoofyCountBadge({required this.count, required this.child, super.key});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final label = count > 9 ? '9+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -2,
          top: -2,
          child: Semantics(
            label: count == 0 ? '' : '$count novedades sin leer',
            child: AnimatedScale(
              scale: count > 0 ? 1 : 0,
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              // Solo rebota al aparecer: al apagarse se va derecho, si no la
              // curva `back` pasa por escala negativa y el globo parpadea.
              curve: count > 0 ? Curves.easeOutBack : Curves.easeIn,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: const BoxDecoration(
                  color: WoofyColors.accent,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: Text(
                    label,
                    key: ValueKey(label),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: WoofyColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
