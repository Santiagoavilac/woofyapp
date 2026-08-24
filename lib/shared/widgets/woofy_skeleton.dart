import 'package:flutter/material.dart';
import 'package:mi_app/core/theme/woofy_radius.dart';
import 'package:mi_app/core/theme/woofy_spacing.dart';

/// A soft pulsing placeholder box used while content loads.
class WoofySkeleton extends StatefulWidget {
  const WoofySkeleton({
    this.width,
    this.height = 16,
    this.borderRadius = WoofyRadius.controlAll,
    super.key,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<WoofySkeleton> createState() => _WoofySkeletonState();
}

class _WoofySkeletonState extends State<WoofySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 0.9).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}

/// A skeleton shaped like an [DogCard] used to fill browse lists on load.
class WoofyCardSkeleton extends StatelessWidget {
  const WoofyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: WoofyRadius.cardAll,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 11,
            child: WoofySkeleton(
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(WoofySpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                WoofySkeleton(width: 140, height: 20),
                SizedBox(height: WoofySpacing.sm),
                WoofySkeleton(width: 90, height: 14),
                SizedBox(height: WoofySpacing.md),
                WoofySkeleton(width: double.infinity, height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
