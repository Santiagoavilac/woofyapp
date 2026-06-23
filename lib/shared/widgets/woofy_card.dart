import 'package:flutter/material.dart';

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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(key: tapKey, onTap: onTap, child: content),
    );
  }
}
