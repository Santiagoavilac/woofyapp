import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_card.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_info_chip.dart';
import 'package:woofy/features/favorites/presentation/widgets/favorite_toggle_button.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';

/// Un favorito en una sola fila.
///
/// La tarjeta grande del catálogo mide 448 px de alto: en una columna de
/// teléfono entra una sola y tu lista de favoritos parece vacía. Acostada
/// entran cinco de un vistazo, que es lo que uno quiere de una lista corta que
/// va a mirar muchas veces.
class FavoriteRowCard extends StatelessWidget {
  const FavoriteRowCard({required this.dog, required this.onTap, super.key});

  static const extent = 148.0;
  static const _photo = 120.0;

  final Dog dog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = [
      dog.shelter?.name,
      dog.shelter?.city,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');

    return WoofyCard(
      key: ValueKey('favorite-row-${dog.slug}'),
      tapKey: ValueKey('favorite-row-${dog.slug}-tap'),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SizedBox(
        height: extent,
        child: Row(
          children: [
            SizedBox.square(
              dimension: _photo,
              child: ColoredBox(
                color: WoofyColors.primarySoft,
                child: _Photo(dog: dog),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: WoofySpacing.md,
                  vertical: WoofySpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dog.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (dog.ageLabel != null || dog.sex != null) ...[
                      const SizedBox(height: WoofySpacing.sm),
                      Wrap(
                        spacing: WoofySpacing.xs,
                        runSpacing: WoofySpacing.xs,
                        children: [
                          if (dog.ageLabel case final age?)
                            DogInfoChip(label: age, icon: Icons.cake_outlined),
                          if (dog.sex case final sex?)
                            DogInfoChip(label: sex, icon: Icons.pets_outlined),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: WoofySpacing.sm),
              child: FavoriteToggleButton(dogId: dog.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.dog});

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
