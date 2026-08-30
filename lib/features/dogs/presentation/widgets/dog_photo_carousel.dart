import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_card.dart';
import 'package:woofy/shared/widgets/woofy_photo_hero.dart';

class DogPhotoCarousel extends StatefulWidget {
  const DogPhotoCarousel({required this.photos, this.heroSlug, super.key});

  final List<DogPhoto> photos;

  /// Con slug, la primera foto es el otro extremo del vuelo que arranca en la
  /// tarjeta del catálogo. Solo la primera: dos `Hero` con la misma etiqueta
  /// en una ruta rompen el vuelo, y el carrusel las tiene todas montadas.
  final String? heroSlug;

  @override
  State<DogPhotoCarousel> createState() => _DogPhotoCarouselState();
}

class _DogPhotoCarouselState extends State<DogPhotoCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    if (photos.isEmpty) {
      return const AspectRatio(
        aspectRatio: 4 / 3,
        child: DogPhotoPlaceholder(),
      );
    }
    if (photos.length == 1) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: _heroed(0, _Photo(photo: photos.first)),
      );
    }
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              itemCount: photos.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) =>
                  _heroed(index, _Photo(photo: photos[index])),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: WoofySpacing.md,
            child: _PageDots(count: photos.length, current: _page),
          ),
        ],
      ),
    );
  }

  Widget _heroed(int index, Widget child) {
    final slug = widget.heroSlug;
    if (slug == null || index != 0) return child;
    return WoofyPhotoHero(tag: dogPhotoHeroTag(slug), child: child);
  }
}

/// Los puntitos del carrusel: el activo se estira en vez de solo encenderse,
/// que es lo que hace legible cuántas fotos faltan sin contar.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final instant = MediaQuery.disableAnimationsOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: instant
                ? Duration.zero
                : const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 8,
            width: index == current ? 20 : 8,
            decoration: BoxDecoration(
              color: index == current
                  ? WoofyColors.white
                  : WoofyColors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.photo});

  final DogPhoto photo;

  @override
  Widget build(BuildContext context) {
    final url = photo.publicUrl;
    if (url == null || url.isEmpty) return const DogPhotoPlaceholder();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => const DogPhotoPlaceholder(),
      errorWidget: (context, url, error) => const DogPhotoPlaceholder(),
    );
  }
}
