import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/features/messages/data/messages_providers.dart';
import 'package:woofy/features/messages/presentation/widgets/thread_card.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_refresh.dart';

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

  @override
  Widget build(BuildContext context) {
    final threads = ref.watch(myThreadsProvider);
    return BackFallbackScope(
      fallbackLocation: RoutePaths.profile,
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Mensajes'),
        body: SafeArea(
          child: threads.when(
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
              return CustomScrollView(
                slivers: [
                  WoofyRefreshControl(onRefresh: refreshData),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final thread = items[index];
                        return ThreadCard(
                          thread: thread,
                          onTap: () =>
                              context.push(RoutePaths.conversation(thread.id)),
                        );
                      },
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
