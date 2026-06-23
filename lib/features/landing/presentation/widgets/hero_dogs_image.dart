import 'package:flutter/material.dart';
import 'package:mi_app/core/theme/woofy_colors.dart';

class HeroDogsImage extends StatelessWidget {
  const HeroDogsImage({
    this.assetPath = 'assets/images/woofy_hero_dogs.png',
    super.key,
  });

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth * 1.32;
        final visibleHeight = imageWidth / (16 / 9) * 0.84;

        return SizedBox(
          height: visibleHeight,
          child: ClipRect(
            child: OverflowBox(
              minWidth: imageWidth,
              maxWidth: imageWidth,
              minHeight: visibleHeight,
              maxHeight: visibleHeight,
              alignment: Alignment.topCenter,
              child: Image.asset(
                assetPath,
                width: imageWidth,
                height: imageWidth / (16 / 9),
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                semanticLabel: 'Grupo de perros de Woofy',
                errorBuilder: (context, error, stackTrace) => SizedBox(
                  width: imageWidth,
                  height: visibleHeight,
                  child: const _DogsFallback(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DogsFallback extends StatelessWidget {
  const _DogsFallback();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        key: const ValueKey('landing-dogs-fallback'),
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          _FallbackDog(size: 52),
          SizedBox(width: 8),
          _FallbackDog(size: 70),
          SizedBox(width: 8),
          _FallbackDog(size: 58),
        ],
      ),
    );
  }
}

class _FallbackDog extends StatelessWidget {
  const _FallbackDog({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: WoofyColors.white.withValues(alpha: 0.88),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.pets_rounded,
        size: size * 0.5,
        color: WoofyColors.textDark,
      ),
    );
  }
}
