import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_app/app/back_fallback_scope.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/features/dogs/data/dog_repository_provider.dart';
import 'package:mi_app/features/dogs/presentation/widgets/dog_card.dart';
import 'package:mi_app/shared/widgets/woofy_app_bar.dart';
import 'package:mi_app/shared/widgets/woofy_empty_state.dart';
import 'package:mi_app/shared/widgets/woofy_error.dart';
import 'package:mi_app/shared/widgets/woofy_loading.dart';
import 'package:mi_app/features/favorites/presentation/widgets/favorite_toggle_button.dart';

class DogsPage extends ConsumerWidget {
  const DogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogs = ref.watch(publishedDogsProvider);
    return BackFallbackScope(
      fallbackLocation: RoutePaths.landing,
      child: Scaffold(
        appBar: WoofyAppBar(
          title: 'Perritos en adopción',
          actions: [
            IconButton(
              tooltip: 'Mis favoritos',
              onPressed: () => context.push(RoutePaths.favorites),
              icon: const Icon(Icons.favorite_outline_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: dogs.when(
            loading: () => const WoofyLoading(message: 'Cargando perritos…'),
            error: (error, stackTrace) => WoofyError(
              message: 'No pudimos cargar los perritos.',
              onRetry: () => ref.invalidate(publishedDogsProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const WoofyEmptyState(
                  title: 'Todavía no hay perritos',
                  message: 'No encontramos perritos publicados todavía.',
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 2 : 1;
                  final horizontal = constraints.maxWidth >= 600 ? 32.0 : 16.0;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontal,
                              20,
                              horizontal,
                              16,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Encontrá a tu compañero',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Conocé a los perritos que hoy buscan un hogar.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontal,
                              0,
                              horizontal,
                              28,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    mainAxisExtent: 448,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final dog = items[index];
                                return DogCard(
                                  dog: dog,
                                  overlay: FavoriteToggleButton(dogId: dog.id),
                                  onTap: () => context.push(
                                    RoutePaths.dogDetail(dog.slug),
                                  ),
                                );
                              }, childCount: items.length),
                            ),
                          ),
                        ],
                      ),
                    ),
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
