import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/messages/data/messages_providers.dart';
import 'package:woofy/features/messages/presentation/widgets/thread_card.dart';
import 'package:woofy/features/notifications/data/notifications_providers.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_refresh.dart';
import 'package:woofy/shared/widgets/woofy_reveal.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage>
    with WoofyRefreshMixin {
  @override
  Future<void> onWoofyRefresh() async {
    ref.invalidate(myThreadsProvider);
    await ref.read(myThreadsProvider.future);
  }

  /// Cuántos mensajes sin abrir tiene cada conversación.
  ///
  /// Si todavía no cargó, la bandeja se dibuja sin globitos en vez de esperar:
  /// la lista es lo importante, el contador es un extra.
  Map<String, int> _unreadByThread(WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return const {};
    final unread = ref.watch(unreadThreadsProvider(userId)).value;
    if (unread == null) return const {};
    return {for (final item in unread) item.threadId: item.count};
  }

  @override
  Widget build(BuildContext context) {
    final threads = ref.watch(myThreadsProvider);
    return BackFallbackScope(
      fallbackLocation: RoutePaths.profile,
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Mensajes'),
        body: SafeArea(
          child: threads.when(
            skipLoadingOnReload: true,
            loading: () => const WoofyLoading(message: 'Cargando mensajes…'),
            error: (_, _) => WoofyError(
              message: 'No pudimos cargar tus mensajes.',
              onRetry: () => ref.invalidate(myThreadsProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return WoofyEmptyState(
                  icon: Icons.forum_outlined,
                  title: 'Todavía no tenés conversaciones.',
                  message:
                      'Cuando tengas conversaciones con refugios, van a aparecer acá.',
                  actionLabel: 'Ver perritos',
                  onAction: () => context.go(RoutePaths.dogs),
                );
              }
              final unread = _unreadByThread(ref);
              return CustomScrollView(
                slivers: [
                  WoofyRefreshControl(onRefresh: refreshData),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: WoofySliverStagger(
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final thread = items[index];
                          return WoofyReveal.indexed(
                            index: index,
                            child: ThreadCard(
                              thread: thread,
                              unreadCount: unread[thread.id] ?? 0,
                              onTap: () => context.push(
                                RoutePaths.conversation(thread.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
