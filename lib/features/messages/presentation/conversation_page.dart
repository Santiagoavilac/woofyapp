import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/blocks/providers/blocks_providers.dart';
import 'package:woofy/features/reports/data/report_models.dart';
import 'package:woofy/features/reports/presentation/widgets/report_sheet.dart';
import 'package:woofy/features/messages/data/message_models.dart';
import 'package:woofy/features/messages/data/messages_providers.dart';
import 'package:woofy/features/messages/presentation/widgets/conversation_header.dart';
import 'package:woofy/features/messages/presentation/widgets/date_separator.dart';
import 'package:woofy/features/messages/presentation/widgets/message_bubble.dart';
import 'package:woofy/features/messages/presentation/widgets/message_input.dart';
import 'package:woofy/features/notifications/data/notifications_providers.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_refresh.dart';
import 'package:woofy/shared/widgets/woofy_reveal.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bloqueaste a $shelterName.')));
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
                PopupMenuItem(value: 'block', child: Text('Bloquear refugio')),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: thread.when(
            skipLoadingOnReload: true,
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
                    skipLoadingOnReload: true,
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
                      return _MessageList(
                        threadId: threadId,
                        messages: items,
                        userId: userId,
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

/// Lista de mensajes con el mismo gesto de recarga que el resto de la app.
///
/// Va aparte de [ConversationPage] porque el gesto necesita un [State] y la
/// página entera no tiene por qué volverse stateful por esto.
class _MessageList extends ConsumerStatefulWidget {
  const _MessageList({
    required this.threadId,
    required this.messages,
    required this.userId,
  });

  final String threadId;
  final List<Message> messages;
  final String? userId;

  @override
  ConsumerState<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<_MessageList>
    with WoofyRefreshMixin {
  /// Cuánto silencio corta una tanda del mismo autor.
  static const _groupWindow = Duration(minutes: 3);

  final _scroll = ScrollController();

  /// Los mensajes que ya estaban cuando se abrió la pantalla.
  ///
  /// Solo los que llegan después entran animados: si animara todo, cada
  /// recarga volvería a "escribir" la conversación entera y se vería falso.
  late final Set<String> _seen = {
    for (final message in widget.messages) message.id,
  };

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void didUpdateWidget(covariant _MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final arrived = widget.messages.length > oldWidget.messages.length;
    if (arrived) WidgetsBinding.instance.addPostFrameCallback(_followNew);
    // Lo viejo pasa a ser conocido recién después de que se animó una vez.
    if (!arrived) _seen.addAll(widget.messages.map((message) => message.id));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Baja al mensaje nuevo solo si ya estabas mirando el final.
  ///
  /// Si estabas leyendo más arriba, arrastrarte hasta abajo te hace perder el
  /// renglón: peor que no enterarte del mensaje.
  void _followNew(Duration _) {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    final distance = position.maxScrollExtent - position.pixels;
    if (distance > 160) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(position.maxScrollExtent);
      return;
    }
    _scroll.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// Se marca leído acá y no al abrir el panel de la campana: leer es abrir la
  /// conversación. Si falla no se le avisa a nadie — que el globito quede un
  /// rato de más es mucho menos molesto que un cartel de error encima de una
  /// charla.
  Future<void> _markRead() async {
    try {
      await ref
          .read(messagesRepositoryProvider)
          .markThreadRead(widget.threadId);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    ref.invalidate(unreadThreadsProvider);
  }

  @override
  Future<void> onWoofyRefresh() async {
    ref.invalidate(threadMessagesProvider(widget.threadId));
    await ref.read(threadMessagesProvider(widget.threadId).future);
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    final messages = widget.messages;

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        WoofyRefreshControl(onRefresh: refreshData),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final previous = index == 0 ? null : messages[index - 1];
              final next = index == messages.length - 1
                  ? null
                  : messages[index + 1];
              final isMine = userId != null && message.isMine(userId);

              final startsDay =
                  previous == null ||
                  DateSeparator.splits(previous.createdAt, message.createdAt);
              // Una tanda es el mismo autor sin un silencio largo en el medio.
              final continuesGroup =
                  !startsDay &&
                  previous.senderId == message.senderId &&
                  message.createdAt.difference(previous.createdAt) <
                      _groupWindow;
              final endsGroup =
                  next == null ||
                  next.senderId != message.senderId ||
                  next.createdAt.difference(message.createdAt) >=
                      _groupWindow ||
                  DateSeparator.splits(message.createdAt, next.createdAt);

              final bubble = Padding(
                padding: EdgeInsets.only(top: continuesGroup ? 3 : 10),
                child: MessageBubble(
                  message: message,
                  isMine: isMine,
                  showTime: endsGroup,
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (startsDay)
                    Padding(
                      padding: EdgeInsets.only(top: index == 0 ? 0 : 16),
                      child: DateSeparator(date: message.createdAt),
                    ),
                  if (_seen.contains(message.id))
                    bubble
                  else
                    WoofyEnteringReveal(
                      key: ValueKey('message-in-${message.id}'),
                      offset: const Offset(0, 0.08),
                      child: bubble,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
