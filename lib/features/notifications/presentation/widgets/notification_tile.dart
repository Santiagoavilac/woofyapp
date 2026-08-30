import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/notifications/data/notification_models.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    required this.onTap,
    super.key,
  });

  final WoofyNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMessage = notification.kind == WoofyNotificationKind.message;
    return InkWell(
      key: ValueKey('notification-${notification.id}'),
      onTap: onTap,
      borderRadius: WoofyRadius.fieldAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: WoofySpacing.md,
          vertical: WoofySpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isMessage
                    ? WoofyColors.primarySoft
                    : WoofyColors.secondarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMessage
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.pets_outlined,
                size: 20,
                color: WoofyColors.textPrimary,
              ),
            ),
            const SizedBox(width: WoofySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WoofyColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (notification.isUnread) ...[
              const SizedBox(width: WoofySpacing.sm),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: WoofyColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
