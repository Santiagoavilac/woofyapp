import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_app/app/back_fallback_scope.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/features/favorites/data/favorites_providers.dart';
import 'package:mi_app/features/favorites/presentation/widgets/favorite_dog_card.dart';
import 'package:mi_app/shared/widgets/woofy_app_bar.dart';
import 'package:mi_app/shared/widgets/woofy_empty_state.dart';
import 'package:mi_app/shared/widgets/woofy_error.dart';
import 'package:mi_app/shared/widgets/woofy_loading.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteDogsProvider);
    return BackFallbackScope(
      fallbackLocation: RoutePaths.dogs,
      child: Scaffold(
        appBar: const WoofyAppBar(title: 'Mis favoritos'),
        body: SafeArea(
          child: favorites.when(
            loading: () => const WoofyLoading(message: 'Cargando favoritos…'),
            error: (_, _) => WoofyError(
              message: 'No pudimos cargar tus favoritos.',
              onRetry: () => ref.invalidate(favoriteDogsProvider),
            ),
            data: (dogs) {
              if (dogs.isEmpty) {
                return WoofyEmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'Todavía no guardaste favoritos',
                  message: 'Marcá los perritos que querés volver a encontrar.',
                  actionLabel: 'Ver perros',
                  onAction: () => context.go(RoutePaths.dogs),
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 2 : 1;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 448,
                    ),
                    itemCount: dogs.length,
                    itemBuilder: (context, index) {
                      final dog = dogs[index];
                      return FavoriteDogCard(
                        dog: dog,
                        onTap: () =>
                            context.push(RoutePaths.dogDetail(dog.slug)),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
