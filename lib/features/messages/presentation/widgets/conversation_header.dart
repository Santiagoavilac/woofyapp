import 'package:flutter/material.dart';
import 'package:woofy/features/messages/data/message_models.dart';

class ConversationHeader extends StatelessWidget {
  const ConversationHeader({required this.thread, super.key});

  final ConversationThread thread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: thread.dogPhotoUrl == null
                ? null
                : NetworkImage(thread.dogPhotoUrl!),
            child: thread.dogPhotoUrl == null
                ? const Icon(Icons.pets_rounded)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.displayDogName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  thread.displayShelterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
