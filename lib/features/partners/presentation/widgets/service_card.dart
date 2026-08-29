import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/partners/data/money.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/presentation/widgets/partner_card.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';

/// Un servicio en el listado general, con el aliado que lo ofrece.
///
/// A diferencia de [PartnerServiceTile], que vive dentro de un perfil donde el
/// negocio ya se sabe, acá el negocio es parte del dato: sin él, "Baño para
/// perro — Bs 70" no le dice a nadie a quién le está por escribir.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.service,
    required this.onTap,
    required this.onOpenPartner,
    super.key,
  });

  final PartnerService service;

  /// Reservar el servicio.
  final VoidCallback onTap;

  /// Abrir el perfil del aliado.
  final VoidCallback onOpenPartner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = [
      service.partnerName,
      service.partnerCity,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');

    return WoofyCard(
      key: ValueKey('service-card-${service.id}'),
      tapKey: ValueKey('service-card-${service.id}-tap'),
      padding: const EdgeInsets.all(WoofySpacing.md),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: WoofyRadius.cardLargeAll,
            child: SizedBox(
              height: 88,
              width: 88,
              child: ColoredBox(
                color: WoofyColors.surfaceMuted,
                child: PartnerImage(
                  url: service.imageUrl,
                  icon: Icons.pets_rounded,
                ),
              ),
            ),
          ),
          const SizedBox(width: WoofySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (place.isNotEmpty) ...[
                  const SizedBox(height: WoofySpacing.xs),
                  // Toque propio: el nombre del negocio es la puerta a su
                  // perfil, mientras que la tarjeta entera va a reservar.
                  InkWell(
                    key: ValueKey('service-card-${service.id}-partner'),
                    onTap: onOpenPartner,
                    child: Text(
                      place,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: WoofyColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: WoofyColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: WoofySpacing.sm),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        Money.fromCents(service.priceCents),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: WoofyColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (service.durationMinutes case final minutes?) ...[
                      const SizedBox(width: WoofySpacing.sm),
                      Flexible(
                        child: Text(
                          '· $minutes min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
