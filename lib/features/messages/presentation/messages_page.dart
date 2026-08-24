import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_app/app/back_fallback_scope.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/features/messages/data/messages_providers.dart';
import 'package:mi_app/features/messages/presentation/widgets/thread_card.dart';
import 'package:mi_app/shared/widgets/woofy_app_bar.dart';
import 'package:mi_app/shared/widgets/woofy_empty_state.dart';
import 'package:mi_app/shared/widgets/woofy_error.dart';
import 'package:mi_app/shared/widgets/woofy_loading.dart';

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(myThreadsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
