import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/back_fallback_scope.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/features/favorites/data/favorites_providers.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/favorites/presentation/widgets/favorite_dog_card.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_button.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_refresh.dart';
import 'package:woofy/shared/widgets/woofy_reveal.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage>
    with WoofyRefreshMixin {
  @override
  Future<void> onWoofyRefresh() async {
    ref.invalidate(favoriteDogsProvider);
    await ref.read(favoriteDogsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
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
                return ColoredBox(
                  color: WoofyColors.primarySoft,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(WoofySpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 320,
                              maxWidth: 260,
                            ),
                            child: Image.asset(
                              'assets/images/nohayfavoritos.png',
                              key: const ValueKey('favorites-empty-image'),
                              fit: BoxFit.contain,
                              semanticLabel:
                                  'Un perro y un gato mostrando un corazón',
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.favorite_border_rounded,
                                    size: 72,
                                    color: WoofyColors.primary,
                                  ),
                            ),
                          ),
                          const SizedBox(height: WoofySpacing.lg),
                          Text(
                            'Todavía no guardaste favoritos',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: WoofySpacing.sm),
                          const Text(
                            'Marcá los animales que querés volver a encontrar.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: WoofySpacing.xl),
                          WoofyButton(
                            label: 'Ver animales',
                            onPressed: () => context.go(RoutePaths.dogs),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 2 : 1;
                  return CustomScrollView(
                    slivers: [
                      WoofyRefreshControl(onRefresh: refreshData),
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: WoofySliverStagger(
                          sliver: SliverGrid.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  mainAxisExtent: 448,
                                ),
                            itemCount: dogs.length,
                            itemBuilder: (context, index) {
                              final dog = dogs[index];
                              return WoofyReveal.indexed(
                                index: index,
                                child: FavoriteDogCard(
                                  dog: dog,
                                  onTap: () => context.push(
                                    RoutePaths.dogDetail(dog.slug),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
