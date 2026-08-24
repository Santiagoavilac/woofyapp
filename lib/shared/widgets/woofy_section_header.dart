import 'package:flutter/material.dart';
import 'package:mi_app/core/theme/woofy_spacing.dart';

/// Consistent section title with optional subtitle and trailing action.
class WoofySectionHeader extends StatelessWidget {
  const WoofySectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle case final subtitle?) ...[
                const SizedBox(height: WoofySpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing case final trailing?) ...[WoofySpacing.gapMd, trailing],
      ],
    );
  }
}
