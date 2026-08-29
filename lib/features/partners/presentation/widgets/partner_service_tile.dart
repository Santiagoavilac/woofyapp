import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/partners/data/money.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';

/// Servicio reservable: precio y acceso a la reserva.
class PartnerServiceTile extends StatelessWidget {
  const PartnerServiceTile({
    required this.service,
    required this.onReserve,
    super.key,
  });

  final PartnerService service;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WoofyCard(
      key: ValueKey('vet-service-${service.id}'),
      tapKey: ValueKey('vet-service-${service.id}-tap'),
      padding: const EdgeInsets.all(WoofySpacing.md),
      onTap: onReserve,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: theme.textTheme.titleSmall),
                if (service.description case final description?) ...[
                  const SizedBox(height: WoofySpacing.xs),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: WoofySpacing.sm),
                Text(
                  Money.fromCents(service.priceCents),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: WoofyColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
