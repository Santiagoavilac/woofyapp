import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';

class LandingShelterCard extends StatelessWidget {
  const LandingShelterCard({
    required this.shelterName,
    required this.onPressed,
    super.key,
  });

  final String shelterName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(WoofySpacing.lg),
      decoration: const BoxDecoration(
        color: WoofyColors.secondarySoft,
        borderRadius: WoofyRadius.cardAll,
      ),
      child: Row(
        children: [
          const Icon(Icons.home_work_outlined, color: WoofyColors.secondary),
          const SizedBox(width: WoofySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Refugio', style: theme.textTheme.labelMedium),
                const SizedBox(height: WoofySpacing.xs),
                Text(
                  shelterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onPressed, child: const Text('Ir al panel')),
        ],
      ),
    );
  }
}
