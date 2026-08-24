import 'package:flutter/material.dart';
import 'package:mi_app/features/messages/data/message_models.dart';
import 'package:mi_app/shared/widgets/woofy_card.dart';

class ThreadCard extends StatelessWidget {
  const ThreadCard({required this.thread, required this.onTap, super.key});

  final ConversationThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = thread.lastMessagePreview;
    return WoofyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _DogAvatar(thread: thread),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.displayShelterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  thread.displayDogName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  preview ?? 'Sin mensajes todavía',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatThreadDate(thread.sortDate),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _DogAvatar extends StatelessWidget {
  const _DogAvatar({required this.thread});

  final ConversationThread thread;

  @override
  Widget build(BuildContext context) {
    final photoUrl = thread.dogPhotoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 72,
        height: 72,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: photoUrl == null
            ? Icon(
                Icons.pets_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              )
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.pets_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
      ),
    );
  }
}

String _formatThreadDate(DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return '${_two(local.hour)}:${_two(local.minute)}';
  }
  return '${_two(local.day)}/${_two(local.month)}/${local.year}';
}

String _two(int value) => value.toString().padLeft(2, '0');
