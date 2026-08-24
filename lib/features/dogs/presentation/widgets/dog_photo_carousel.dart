import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_card.dart';

class DogPhotoCarousel extends StatelessWidget {
  const DogPhotoCarousel({required this.photos, super.key});

  final List<DogPhoto> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const AspectRatio(
        aspectRatio: 4 / 3,
        child: DogPhotoPlaceholder(),
      );
    }
    if (photos.length == 1) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: _Photo(photo: photos.first),
      );
    }
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (context, index) => _Photo(photo: photos[index]),
      ),
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
