import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/vets/data/vet_models.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';

/// Tarjeta de veterinaria: portada arriba, nombre y ciudad abajo.
/// Misma gramática visual que [DogCard], sin precios: el catálogo se ve dentro.
class VetCard extends StatelessWidget {
  const VetCard({required this.vet, required this.onTap, super.key});

  final Vet vet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WoofyCard(
      key: ValueKey('vet-card-${vet.slug}'),
      tapKey: ValueKey('vet-card-${vet.slug}-tap'),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: WoofyColors.primarySoft,
              child: VetImage(url: vet.coverImageUrl ?? vet.profileImageUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(WoofySpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vet.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vet.verified)
                      const Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: WoofyColors.primary,
                      ),
                  ],
                ),
                if (vet.city case final city?) ...[
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
                          city,
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
                if (vet.description case final description?) ...[
                  const SizedBox(height: WoofySpacing.sm),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

/// Imagen de veterinaria con marcador de posición propio.
class VetImage extends StatelessWidget {
  const VetImage({required this.url, this.icon = Icons.storefront_rounded, super.key});

  final String? url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final placeholder = _VetImagePlaceholder(icon: icon);
    if (url == null || url!.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) => placeholder,
    );
  }
}

class _VetImagePlaceholder extends StatelessWidget {
  const _VetImagePlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const ValueKey('vet-image-placeholder'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 48, color: theme.colorScheme.primary),
      ),
    );
  }
}
