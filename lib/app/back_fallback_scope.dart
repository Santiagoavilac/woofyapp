import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackFallbackScope extends StatelessWidget {
  const BackFallbackScope({
    required this.fallbackLocation,
    required this.child,
    super.key,
  });

  final String fallbackLocation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(fallbackLocation);
      },
      child: child,
    );
  }
}
