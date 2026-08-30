import 'package:flutter/material.dart';
import 'package:woofy/shared/widgets/woofy_press.dart';

class WoofyCard extends StatelessWidget {
  const WoofyCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.tapKey,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Key? tapKey;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(key: tapKey, onTap: onTap, child: content),
    );
    // El hundido va por fuera de la `Card` para que la sombra acompañe; la
    // `tapKey` se queda en el `InkWell`, que es lo que buscan los tests.
    return onTap == null ? card : WoofyPressable(child: card);
  }
}
