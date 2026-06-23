import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';
import 'package:mi_app/features/dogs/presentation/widgets/dog_info_chip.dart';
import 'package:mi_app/shared/widgets/woofy_card.dart';

class DogCard extends StatelessWidget {
  const DogCard({
    required this.dog,
    required this.onTap,
    this.overlay,
    super.key,
  });

  final Dog dog;
  final VoidCallback onTap;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return WoofyCard(
      key: ValueKey('dog-card-${dog.slug}'),
      tapKey: ValueKey('dog-card-${dog.slug}-tap'),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: _DogCardPhoto(dog: dog),
              ),
              if (overlay != null)
                Positioned(top: 10, right: 10, child: overlay!),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dog.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (dog.shelter?.name case final shelterName?) ...[
                  const SizedBox(height: 4),
                  Text(
                    shelterName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (dog.ageLabel != null ||
                    dog.size != null ||
                    dog.sex != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (dog.ageLabel case final age?)
                        DogInfoChip(label: age, icon: Icons.cake_outlined),
                      if (dog.size case final size?)
                        DogInfoChip(label: size, icon: Icons.straighten),
                      if (dog.sex case final sex?)
                        DogInfoChip(label: sex, icon: Icons.pets_outlined),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DogCardPhoto extends StatelessWidget {
  const _DogCardPhoto({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final url = dog.coverPhoto?.publicUrl;
    if (url == null || url.isEmpty) return const DogPhotoPlaceholder();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (context, url, error) => const DogPhotoPlaceholder(),
    );
  }
}

class DogPhotoPlaceholder extends StatelessWidget {
  const DogPhotoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('dog-photo-placeholder'),
      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.25),
      child: Center(
        child: Icon(
          Icons.pets_rounded,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
