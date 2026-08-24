import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/messages/data/messages_providers.dart';
import 'package:woofy/features/messages/presentation/widgets/conversation_header.dart';
import 'package:woofy/features/messages/presentation/widgets/message_bubble.dart';
import 'package:woofy/features/messages/presentation/widgets/message_input.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';

class ConversationPage extends ConsumerWidget {
  const ConversationPage({required this.threadId, super.key});

  final String threadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thread = ref.watch(threadProvider(threadId));
    final messages = ref.watch(threadMessagesProvider(threadId));
    final isSending = ref.watch(sendMessageControllerProvider(threadId));
    final userId = ref.watch(currentUserProvider)?.id;

    return BackFallbackScope(
      fallbackLocation: RoutePaths.messages,
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Conversación'),
        body: SafeArea(
          child: thread.when(
            loading: () =>
                const WoofyLoading(message: 'Cargando conversación…'),
            error: (_, _) => WoofyError(
              message: 'No pudimos abrir esta conversación.',
              onRetry: () {
                ref.invalidate(threadProvider(threadId));
                ref.invalidate(threadMessagesProvider(threadId));
              },
            ),
            data: (threadData) => Column(
              children: [
                ConversationHeader(thread: threadData),
                const Divider(height: 1),
                Expanded(
                  child: messages.when(
                    loading: () =>
                        const WoofyLoading(message: 'Cargando mensajes…'),
                    error: (_, _) => WoofyError(
                      message: 'No pudimos abrir esta conversación.',
                      onRetry: () =>
                          ref.invalidate(threadMessagesProvider(threadId)),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const WoofyEmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Todavía no hay mensajes.',
                          message:
                              'Escribí el primero para coordinar con el refugio.',
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(threadMessagesProvider(threadId)),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final message = items[index];
                            return MessageBubble(
                              message: message,
                              isMine: userId != null && message.isMine(userId),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                MessageInput(
                  isSending: isSending,
                  onSend: (body) => ref
                      .read(sendMessageControllerProvider(threadId).notifier)
                      .send(body),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
