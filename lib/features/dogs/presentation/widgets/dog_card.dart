import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_info_chip.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';

/// Editorial adoption card: a large photo takes the lead, an info panel below
/// keeps name, location and quick facts scannable in a couple of seconds.
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
    final theme = Theme.of(context);
    final locationParts = [
      dog.shelter?.name,
      dog.shelter?.city,
    ].whereType<String>().where((value) => value.isNotEmpty).toList();

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
                aspectRatio: 16 / 11,
                child: _DogCardPhoto(dog: dog),
              ),
              if (overlay != null)
                Positioned(
                  top: WoofySpacing.md,
                  right: WoofySpacing.md,
                  child: overlay!,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(WoofySpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dog.name,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (locationParts.isNotEmpty) ...[
                  const SizedBox(height: WoofySpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: WoofySpacing.xs),
                      Expanded(
                        child: Text(
                          locationParts.join(' · '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (dog.ageLabel != null ||
                    dog.size != null ||
                    dog.sex != null) ...[
                  const SizedBox(height: WoofySpacing.md),
                  Wrap(
                    spacing: WoofySpacing.sm,
                    runSpacing: WoofySpacing.sm,
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
      placeholder: (context, url) => const DogPhotoPlaceholder(),
      errorWidget: (context, url, error) => const DogPhotoPlaceholder(),
    );
  }
}

class DogPhotoPlaceholder extends StatelessWidget {
  const DogPhotoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const ValueKey('dog-photo-placeholder'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.primaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.pets_rounded,
          size: 56,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
