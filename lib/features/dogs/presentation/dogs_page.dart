import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/data/dog_repository_provider.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_card.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_filter_chips.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_search_field.dart';
import 'package:woofy/features/favorites/presentation/widgets/favorite_toggle_button.dart';

/// The adoption catalog: browse every published animal with a live text
/// search and client-side filters (size / sex) over data already loaded.
class DogsPage extends ConsumerStatefulWidget {
  const DogsPage({super.key});

  @override
  ConsumerState<DogsPage> createState() => _DogsPageState();
}

class _DogsPageState extends ConsumerState<DogsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _size = _all;
  String _sex = _all;
  Future<void>? _refreshFuture;

  static const _all = 'todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    final existing = _refreshFuture;
    if (existing != null) return existing;
    final future = _runRefresh();
    _refreshFuture = future;
    future.whenComplete(() {
      if (mounted && identical(_refreshFuture, future)) {
        setState(() => _refreshFuture = null);
      } else {
        _refreshFuture = null;
      }
    });
    return future;
  }

  Future<void> _runRefresh() async {
    HapticFeedback.mediumImpact();
    final started = DateTime.now();
    ref.invalidate(publishedDogsProvider);
    try {
      await ref.read(publishedDogsProvider.future);
    } catch (_) {}
    const minVisible = Duration(milliseconds: 1600);
    final elapsed = DateTime.now().difference(started);
    if (elapsed < minVisible) {
      await Future<void>.delayed(minVisible - elapsed);
    }
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  List<Dog> _applyFilters(List<Dog> dogs) {
    final query = _query.trim().toLowerCase();
    return dogs.where((dog) {
      if (query.isNotEmpty) {
        final haystack = [
          dog.name,
          dog.shelter?.name ?? '',
          dog.shelter?.city ?? '',
          dog.size ?? '',
          dog.sex ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      if (_size != _all && dog.size != _size) return false;
      if (_sex != _all && dog.sex != _sex) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dogs = ref.watch(publishedDogsProvider);
    return PopScope<Object?>(
      // Explorar is a shell branch, not a pushed route: the system back must
      // return to Home. Intercepting here (inside the branch navigator) makes
      // Flutter report canHandlePop=true, so Android hands the back to us
      // instead of exiting the app.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RoutePaths.landing);
      },
      child: Scaffold(
        appBar: WoofyAppBar(
          title: 'Animales en adopción',
          actions: [
            IconButton(
              tooltip: 'Mis mensajes',
              onPressed: () => context.push(RoutePaths.messages),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
            IconButton(
              tooltip: 'Mis favoritos',
              onPressed: () => context.push(RoutePaths.favorites),
              icon: const Icon(Icons.favorite_outline_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: dogs.when(
            skipLoadingOnRefresh: true,
            loading: () => const WoofyLoading(message: 'Cargando animales…'),
            error: (error, stackTrace) => WoofyError(
              message: 'No pudimos cargar los animales.',
              onRetry: () => ref.invalidate(publishedDogsProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const WoofyEmptyState(
                  title: 'Todavía no hay animales',
                  message: 'No encontramos animales publicados todavía.',
                );
              }
              final sizes = _distinct(items.map((d) => d.size));
              final sexes = _distinct(items.map((d) => d.sex));
              final results = _applyFilters(items);
              final filterActive = _size != _all || _sex != _all;
              final hasFilters = sizes.isNotEmpty || sexes.isNotEmpty;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 2 : 1;
                  final horizontal = constraints.maxWidth >= 600
                      ? WoofySpacing.xxxl
                      : WoofySpacing.lg;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          CupertinoSliverRefreshControl(
                            refreshTriggerPullDistance: 180,
                            refreshIndicatorExtent: 120,
                            onRefresh: _refresh,
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontal,
                              WoofySpacing.xl,
                              horizontal,
                              WoofySpacing.md,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Encontrá a tu compañero ideal',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: WoofySpacing.xs),
                                  Text(
                                    'Conocé a los animales que hoy buscan un hogar.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: WoofySpacing.lg),
                                  WoofySearchField(
                                    controller: _searchController,
                                    hintText:
                                        'Buscar por nombre, refugio, tamaño o sexo',
                                    onChanged: (value) =>
                                        setState(() => _query = value),
                                    onFilterTap: hasFilters
                                        ? () => _openFilterSheet(sizes, sexes)
                                        : null,
                                    filterActive: filterActive,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (results.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: WoofyEmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'Sin resultados',
                                message:
                                    'No encontramos animales con esos filtros. '
                                    'Probá ajustar la búsqueda.',
                                actionLabel: 'Limpiar filtros',
                                onAction: _clearFilters,
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontal,
                                0,
                                horizontal,
                                WoofySpacing.xxl,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      mainAxisSpacing: WoofySpacing.lg,
                                      crossAxisSpacing: WoofySpacing.lg,
                                      mainAxisExtent: 480,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final dog = results[index];
                                  return DogCard(
                                    dog: dog,
                                    overlay: FavoriteToggleButton(
                                      dogId: dog.id,
                                    ),
                                    onTap: () => context.push(
                                      RoutePaths.dogDetail(dog.slug),
                                    ),
                                  );
                                }, childCount: results.length),
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _size = _all;
      _sex = _all;
    });
  }

  Future<void> _openFilterSheet(
    List<WoofyFilterOption> sizes,
    List<WoofyFilterOption> sexes,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void select(void Function() apply) {
              setState(apply);
              setSheetState(() {});
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WoofySpacing.lg,
                  0,
                  WoofySpacing.lg,
                  WoofySpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtros',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () => select(() {
                            _size = _all;
                            _sex = _all;
                          }),
                          child: const Text('Limpiar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: WoofySpacing.sm),
                    if (sizes.isNotEmpty)
                      _FilterRow(
                        label: 'Tamaño',
                        options: sizes,
                        selected: _size,
                        onSelected: (value) => select(() => _size = value),
                      ),
                    if (sexes.isNotEmpty)
                      _FilterRow(
                        label: 'Sexo',
                        options: sexes,
                        selected: _sex,
                        onSelected: (value) => select(() => _sex = value),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static List<WoofyFilterOption> _distinct(Iterable<String?> values) {
    final seen = <String>{};
    final options = <WoofyFilterOption>[];
    for (final value in values) {
      if (value == null || value.isEmpty) continue;
      if (seen.add(value)) {
        options.add(WoofyFilterOption(value: value, label: value));
      }
    }
    if (options.isEmpty) return const [];
    return [const WoofyFilterOption(value: _all, label: 'Todos'), ...options];
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<WoofyFilterOption> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            WoofySpacing.lg,
            WoofySpacing.sm,
            WoofySpacing.lg,
            WoofySpacing.xs,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        WoofyFilterChips(
          options: options,
          selected: selected,
          onSelected: onSelected,
        ),
      ],
    );
  }
}
