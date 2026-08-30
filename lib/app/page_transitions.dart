import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Cómo entra cada tipo de pantalla.
///
/// Sin esto cada ruta usa la animación por defecto del sistema, que se ve
/// distinta en iOS que en Android y no dice nada sobre qué clase de pantalla
/// se abrió. Acá el movimiento carga significado: mirar algo se desliza de
/// costado, decidir algo sube desde abajo.
enum WoofyTransition {
  /// Ramas del shell: sin animación.
  ///
  /// Es obligatorio que sea nula. La barra de abajo ya anima su pastilla
  /// mientras se cambia de pestaña; sumarle una transición de página hace que
  /// las dos animaciones peleen y cambiar de sección se sienta roto.
  branch,

  /// Ir a ver algo: ficha del perro, conversación, producto, veterinaria.
  detail,

  /// Ir a decidir algo: la postulación. Sube como una hoja que se apoya.
  commit,

  /// Pantallas de servicio (auth, legales): solo se funde.
  fade,
}

/// Página con la transición que le corresponde.
Page<T> woofyPage<T>(
  GoRouterState state,
  Widget child, {
  WoofyTransition kind = WoofyTransition.detail,
}) {
  if (kind == WoofyTransition.branch) {
    return NoTransitionPage<T>(key: state.pageKey, child: child);
  }
  return CustomTransitionPage<T>(
    key: state.pageKey,
    // La duración se conserva con el movimiento apagado a propósito: cambiarla
    // a cero altera el ciclo de vida de `go_router` y el comportamiento de
    // `pumpAndSettle`, así que la app se comportaría distinto de lo probado.
    transitionDuration: _durationIn(kind),
    reverseTransitionDuration: _durationOut(kind),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      if (kind == WoofyTransition.fade) {
        return FadeTransition(opacity: curved, child: child);
      }
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: kind == WoofyTransition.commit
                ? const Offset(0, 0.10)
                : const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
    child: child,
  );
}

Duration _durationIn(WoofyTransition kind) => switch (kind) {
  WoofyTransition.branch => Duration.zero,
  WoofyTransition.detail => const Duration(milliseconds: 300),
  // Un poco más larga: es el momento de decidir y merece respirar.
  WoofyTransition.commit => const Duration(milliseconds: 380),
  WoofyTransition.fade => const Duration(milliseconds: 240),
};

Duration _durationOut(WoofyTransition kind) => switch (kind) {
  WoofyTransition.branch => Duration.zero,
  WoofyTransition.detail => const Duration(milliseconds: 240),
  WoofyTransition.commit => const Duration(milliseconds: 260),
  WoofyTransition.fade => const Duration(milliseconds: 240),
};

/// Misma sensación para los `Navigator.push` imperativos, que no pasan por
/// `go_router` y si no se quedarían con la animación del sistema.
const woofyPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _WoofyPageTransitionsBuilder(),
    TargetPlatform.iOS: _WoofyPageTransitionsBuilder(),
    TargetPlatform.macOS: _WoofyPageTransitionsBuilder(),
    TargetPlatform.windows: _WoofyPageTransitionsBuilder(),
    TargetPlatform.linux: _WoofyPageTransitionsBuilder(),
    TargetPlatform.fuchsia: _WoofyPageTransitionsBuilder(),
  },
);

class _WoofyPageTransitionsBuilder extends PageTransitionsBuilder {
  const _WoofyPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
