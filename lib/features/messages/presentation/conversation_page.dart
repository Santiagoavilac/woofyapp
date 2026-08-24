import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/blocks/providers/blocks_providers.dart';
import 'package:woofy/features/reports/data/report_models.dart';
import 'package:woofy/features/reports/presentation/widgets/report_sheet.dart';
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

  Future<void> _blockShelter(
    BuildContext context,
    WidgetRef ref,
    String shelterId,
    String shelterName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Bloquear refugio'),
        content: Text(
          'No vas a recibir más mensajes de $shelterName y la conversación '
          'desaparece de tu bandeja. Podés desbloquearlo desde tu perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(blockControllerProvider.notifier).blockShelter(shelterId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bloqueaste a $shelterName.')),
      );
      context.go(RoutePaths.messages);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos bloquear al refugio.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thread = ref.watch(threadProvider(threadId));
    final messages = ref.watch(threadMessagesProvider(threadId));
    final isSending = ref.watch(sendMessageControllerProvider(threadId));
    final userId = ref.watch(currentUserProvider)?.id;

    return BackFallbackScope(
      fallbackLocation: RoutePaths.messages,
      child: Scaffold(
        appBar: WoofyAppBar(
          title: 'Conversación',
          actions: [
            PopupMenuButton<String>(
              key: const ValueKey('conversation-menu'),
              onSelected: (value) {
                final threadData = thread.value;
                if (threadData == null) return;
                switch (value) {
                  case 'report':
                    showReportSheet(
                      context,
                      targetType: ReportTargetType.conversation,
                      targetId: threadId,
                      title: 'Denunciar conversación',
                    );
                  case 'block':
                    _blockShelter(
                      context,
                      ref,
                      threadData.shelterId,
                      threadData.displayShelterName,
                    );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'report',
                  child: Text('Denunciar conversación'),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Text('Bloquear refugio'),
                ),
              ],
            ),
          ],
        ),
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
