import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_app/app/back_fallback_scope.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/core/errors/app_exception.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';
import 'package:mi_app/features/publisher/data/publisher_models.dart';
import 'package:mi_app/features/publisher/data/publisher_providers.dart';
import 'package:mi_app/shared/widgets/woofy_app_bar.dart';
import 'package:mi_app/shared/widgets/woofy_button.dart';
import 'package:mi_app/shared/widgets/woofy_card.dart';
import 'package:mi_app/shared/widgets/woofy_empty_state.dart';
import 'package:mi_app/shared/widgets/woofy_error.dart';
import 'package:mi_app/shared/widgets/woofy_loading.dart';

class PublisherPage extends ConsumerWidget {
  const PublisherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(shelterPortalSessionProvider);

    return BackFallbackScope(
      fallbackLocation: RoutePaths.landing,
      child: Scaffold(
        appBar: WoofyAppBar(
          title: 'Panel del refugio',
          actions: sessionState.value != null
              ? [
                  IconButton(
                    tooltip: 'Cerrar sesión del refugio',
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () => _confirmLogout(context, ref),
                  ),
                ]
              : null,
        ),
        body: SafeArea(
          child: sessionState.when(
            loading: () => const WoofyLoading(message: 'Cargando…'),
            error: (error, _) => WoofyError(
              message: error is AppException
                  ? error.message
                  : 'No pudimos cargar el panel.',
              onRetry: () => ref.invalidate(shelterPortalSessionProvider),
            ),
            data: (session) {
              if (session == null) {
                return WoofyEmptyState(
                  icon: Icons.pets,
                  title: 'Panel de refugio',
                  message:
                      'Ingresá con las credenciales de tu refugio para administrar perros.',
                  actionLabel: 'Ingresar refugio',
                  onAction: () => context.go(RoutePaths.shelterLogin),
                );
              }
              return _PublisherBody(session: session);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cerrar sesión del refugio'),
        content: const Text('¿Querés salir del panel del refugio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(shelterPortalSessionProvider.notifier).logout();
    if (context.mounted) context.go(RoutePaths.landing);
  }
}

class _PublisherBody extends ConsumerWidget {
  const _PublisherBody({required this.session});

  final ShelterPortalSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogs = ref.watch(shelterPortalDogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WoofyCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.home_work_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.shelterName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (session.shelterCity != null &&
                              session.shelterCity!.isNotEmpty)
                            Text(
                              session.shelterCity!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WoofyButton(
                label: 'Nuevo perro',
                icon: Icons.add,
                isExpanded: true,
                onPressed: () => context.push(RoutePaths.publisherNewDog),
              ),
            ],
          ),
        ),
        const Divider(height: 24),
        Expanded(
          child: dogs.when(
            loading: () => const WoofyLoading(message: 'Cargando perros…'),
            error: (_, _) => WoofyError(
              message: 'No pudimos cargar los perros.',
              onRetry: () => ref.invalidate(shelterPortalDogsProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const WoofyEmptyState(
                  icon: Icons.pets,
                  title: 'Todavía no publicaste perros.',
                  message: 'Usá "Nuevo perro" para empezar.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(shelterPortalDogsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _DogListTile(dog: items[index].dog),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DogListTile extends StatelessWidget {
  const _DogListTile({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = dog.coverPhoto?.publicUrl;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: url != null && url.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: url,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                )
              : Icon(
                  Icons.pets_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
        title: Text(dog.name),
        subtitle: Text(_statusLabel(dog.status)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(RoutePaths.publisherEditDog(dog.id)),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'draft' => 'Borrador',
    'published' => 'Publicado',
    'in_process' => 'En proceso',
    'adopted' => 'Adoptado',
    'hidden' => 'Oculto',
    _ => status,
  };
}
