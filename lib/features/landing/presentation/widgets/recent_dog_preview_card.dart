import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_card.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';

class RecentDogPreviewCard extends StatelessWidget {
  const RecentDogPreviewCard({
    required this.dog,
    required this.onTap,
    super.key,
  });

  final Dog dog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = dog.shelter?.city ?? dog.shelter?.name;
    return WoofyCard(
      key: ValueKey('recent-dog-${dog.slug}'),
      tapKey: ValueKey('recent-dog-${dog.slug}-tap'),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: _RecentDogPhoto(dog: dog),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WoofySpacing.md,
              WoofySpacing.sm,
              WoofySpacing.md,
              WoofySpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dog.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                if (location != null && location.isNotEmpty) ...[
                  const SizedBox(height: WoofySpacing.xs),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

class _RecentDogPhoto extends StatelessWidget {
  const _RecentDogPhoto({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final url = dog.coverPhoto?.publicUrl;
    if (url == null || url.isEmpty) return const DogPhotoPlaceholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const DogPhotoPlaceholder(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const DogPhotoPlaceholder();
      },
    );
  }
}
