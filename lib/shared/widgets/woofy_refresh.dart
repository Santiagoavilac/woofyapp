import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Deslizar hacia abajo para recargar, igual en toda la app.
///
/// Es un sliver, así que la página tiene que ser un [CustomScrollView]. Vale la
/// pena: un `RefreshIndicator` de Material pinta un círculo distinto al de
/// Cupertino, y tener dos gestos que se ven distinto según la pantalla es peor
/// que convertir la lista a slivers.
class WoofyRefreshControl extends StatelessWidget {
  const WoofyRefreshControl({required this.onRefresh, super.key});

  /// Cuánto hay que arrastrar para que dispare.
  ///
  /// Corto a propósito: el gesto se hace con el pulgar y sin soltar el
  /// teléfono, así que el recorrido tiene que entrar en ese arco.
  static const triggerPullDistance = 110.0;

  /// Alto que ocupa el indicador mientras recarga.
  static const indicatorExtent = 70.0;

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => CupertinoSliverRefreshControl(
    refreshTriggerPullDistance: triggerPullDistance,
    refreshIndicatorExtent: indicatorExtent,
    onRefresh: onRefresh,
  );
}

/// Estado del gesto de recarga para un [State] de página.
///
/// Resuelve dos cosas que hay que acertar en cada pantalla y es fácil olvidar:
/// que dos tirones seguidos no disparen dos recargas, y que el indicador no
/// aparezca y desaparezca en un frame cuando la respuesta vuelve al instante.
mixin WoofyRefreshMixin<T extends StatefulWidget> on State<T> {
  Future<void>? _inFlight;

  /// Recarga los datos de la pantalla. Cada página decide qué invalidar.
  Future<void> onWoofyRefresh();

  /// Piso de tiempo visible para que el indicador no parpadee.
  static const _minVisible = Duration(milliseconds: 900);

  Future<void> refreshData() {
    final existing = _inFlight;
    if (existing != null) return existing;

    final future = _run();
    _inFlight = future;
    future.whenComplete(() => _inFlight = null);
    return future;
  }

  Future<void> _run() async {
    HapticFeedback.mediumImpact();
    final started = DateTime.now();
    try {
      await onWoofyRefresh();
    } catch (_) {
      // El error ya se muestra en el cuerpo de la página desde el provider.
    }
    final elapsed = DateTime.now().difference(started);
    if (elapsed < _minVisible) {
      await Future<void>.delayed(_minVisible - elapsed);
    }
  }
}
