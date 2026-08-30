import 'package:flutter/material.dart';

/// Dueño de la animación de entrada de un grupo de widgets.
///
/// Un solo [AnimationController] mueve todo el grupo y cada hijo entra con su
/// propio [Interval]: el bloque se arma en orden en vez de aparecer de golpe.
/// El escalonado se corta a los primeros [_staggered] hijos porque más allá el
/// retraso ya no se lee como intención sino como carga lenta.
///
/// El controller corre una sola vez al montar. Los hijos que se construyan
/// después (al desplazarse una lista, por ejemplo) nacen con el controller ya
/// terminado y aparecen enteros: la animación es de la primera pintada, no del
/// scroll.
///
/// Sirve igual para cajas que para slivers: es un widget transparente al
/// árbol de render, así que puede envolver un `SliverList` sin romperlo.
class WoofyRevealGroup extends StatefulWidget {
  const WoofyRevealGroup({required this.child, super.key});

  final Widget child;

  /// Cuántos hijos reciben retraso propio antes de que el resto entre junto.
  static const _staggered = 5;

  /// Porción del recorrido que cada hijo espera respecto del anterior.
  static const _step = 0.12;

  static const _duration = Duration(milliseconds: 620);

  /// Animación que le toca al hijo [index].
  ///
  /// Sin grupo ancestro devuelve una animación ya terminada: un [WoofyReveal]
  /// suelto se pinta entero en vez de quedar invisible esperando algo que no
  /// existe.
  static Animation<double> of(BuildContext context, int index) {
    final scope = context.dependOnInheritedWidgetOfExactType<_RevealScope>();
    return scope?.state._animationFor(index) ?? kAlwaysCompleteAnimation;
  }

  @override
  State<WoofyRevealGroup> createState() => _WoofyRevealGroupState();
}

class _WoofyRevealGroupState extends State<WoofyRevealGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: WoofyRevealGroup._duration,
  );

  /// Una curva por posición del escalonado, no por hijo: dos ítems que
  /// comparten retraso comparten el objeto y no se recrea en cada pintada.
  final _curves = <int, CurvedAnimation>{};

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    for (final curve in _curves.values) {
      curve.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _animationFor(int index) {
    final slot = index < WoofyRevealGroup._staggered
        ? index
        : WoofyRevealGroup._staggered - 1;
    return _curves.putIfAbsent(
      slot,
      () => CurvedAnimation(
        parent: _controller,
        curve: Interval(
          WoofyRevealGroup._step * slot,
          1,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Con "reducir movimiento" el grupo se pinta quieto y completo. Es
    // contenido, no decoración: nunca puede quedar invisible por no animarse.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    }
    return _RevealScope(state: this, child: widget.child);
  }
}

class _RevealScope extends InheritedWidget {
  const _RevealScope({required this.state, required super.child});

  final _WoofyRevealGroupState state;

  @override
  bool updateShouldNotify(_RevealScope oldWidget) => state != oldWidget.state;
}

/// Entrada escalonada para una fila horizontal de tarjetas.
class WoofyStaggeredRow extends StatelessWidget {
  const WoofyStaggeredRow({
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    super.key,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;

  @override
  Widget build(BuildContext context) {
    return WoofyRevealGroup(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Las tarjetas tienen sombra: recortarlas al borde de la fila las deja
        // con el contorno cortado.
        clipBehavior: Clip.none,
        itemCount: itemCount,
        separatorBuilder: separatorBuilder,
        itemBuilder: (context, index) {
          final child = itemBuilder(context, index);
          if (child == null) return null;
          return WoofyReveal.indexed(index: index, child: child);
        },
      ),
    );
  }
}

/// Entrada escalonada para una columna de secciones.
///
/// Es una [Column], no una lista perezosa, y eso es a propósito: el contenido
/// se construye entero aunque esté fuera de pantalla.
class WoofyStaggeredColumn extends StatelessWidget {
  const WoofyStaggeredColumn({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    super.key,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return WoofyRevealGroup(
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < children.length; index++)
            WoofyReveal.indexed(index: index, child: children[index]),
        ],
      ),
    );
  }
}

/// Grupo de entrada para slivers.
///
/// Envuelve cualquier sliver (lista, grilla) y le da el controller compartido;
/// los ítems de adentro piden su animación con [WoofyReveal.indexed].
class WoofySliverStagger extends StatelessWidget {
  const WoofySliverStagger({required this.sliver, super.key});

  final Widget sliver;

  @override
  Widget build(BuildContext context) => WoofyRevealGroup(child: sliver);
}

/// Aparición de un bloque: se funde mientras sube un poco.
///
/// El desplazamiento es corto a propósito. Una entrada larga desde abajo pelea
/// con el scroll y marea; esto solo tiene que dar la sensación de que el
/// contenido se acomoda.
class WoofyReveal extends StatelessWidget {
  const WoofyReveal({
    required Animation<double> this.animation,
    required this.child,
    super.key,
  }) : index = null;

  /// Resuelve la animación contra el [WoofyRevealGroup] ancestro.
  const WoofyReveal.indexed({
    required int this.index,
    required this.child,
    super.key,
  }) : animation = null;

  final Animation<double>? animation;
  final int? index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation =
        this.animation ?? WoofyRevealGroup.of(context, index ?? 0);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
