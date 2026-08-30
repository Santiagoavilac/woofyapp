import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/search/woofy_search.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/banners/data/banner_models.dart';
import 'package:woofy/features/banners/presentation/widgets/banner_carousel.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/data/dog_repository_provider.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_card.dart';
import 'package:woofy/features/dogs/presentation/widgets/species_tiles.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_bottom_navigation.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_error.dart';
import 'package:woofy/shared/widgets/woofy_filter_chips.dart';
import 'package:woofy/shared/widgets/woofy_loading.dart';
import 'package:woofy/shared/widgets/woofy_refresh.dart';
import 'package:woofy/shared/widgets/woofy_search_field.dart';
import 'package:woofy/shared/widgets/woofy_section_header.dart';
import 'package:woofy/features/favorites/presentation/widgets/favorite_toggle_button.dart';

/// El catálogo de adopción: todos los animales publicados, con búsqueda en vivo
/// y filtros que se aplican sobre lo que ya está en memoria.
///
/// La pantalla se ordena de lo general a lo particular: primero qué tipo de
/// animal, después la edad, después el resto. Antes arrancaba directamente con
/// una grilla de tarjetas y no había forma de saber qué había sin scrollear
/// todo.
class DogsPage extends ConsumerStatefulWidget {
  const DogsPage({super.key});

  @override
  ConsumerState<DogsPage> createState() => _DogsPageState();
}

class _DogsPageState extends ConsumerState<DogsPage> with WoofyRefreshMixin {
  final _searchController = TextEditingController();
  String _query = '';
  String _size = _all;
  String _sex = _all;

  /// `null` en los dos quiere decir "sin filtrar".
  AnimalSpecies? _species;
  AgeGroup? _age;

  static const _all = 'todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Future<void> onWoofyRefresh() async {
    ref.invalidate(publishedDogsProvider);
    await ref.read(publishedDogsProvider.future);
  }

  /// Todo menos la especie, para poder contar cuántos hay de cada tipo sin que
  /// el propio filtro de especie deje los otros mosaicos en cero.
  bool _matchesExceptSpecies(Dog dog, String? city) {
    if (city != null && dog.shelter?.city != city) return false;
    if (_age != null && dog.ageGroup != _age) return false;
    if (_size != _all && dog.size != _size) return false;
    if (_sex != _all && dog.sex != _sex) return false;
    final query = _query.trim();
    if (query.isEmpty) return true;
    // La especie entra en lo buscable: ahora "gato" tiene que encontrar gatos,
    // igual que un nombre o una ciudad.
    return woofyMatches(query, [
      dog.name,
      dog.species.label,
      dog.shelter?.name,
      dog.shelter?.city,
      dog.size,
      dog.sex,
      dog.temperament,
      dog.ageGroup?.label,
    ]);
  }

  List<Dog> _applyFilters(List<Dog> dogs) {
    final city = ref.watch(selectedCityProvider);
    return dogs
        .where(
          (dog) =>
              _matchesExceptSpecies(dog, city) &&
              (_species == null || dog.species == _species),
        )
        .toList();
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
            skipLoadingOnReload: true,
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
              final cities = _distinct(items.map((d) => d.shelter?.city));
              final results = _applyFilters(items);
              final filterActive =
                  _size != _all ||
                  _sex != _all ||
                  _age != null ||
                  _species != null ||
                  ref.watch(selectedCityProvider) != null;
              final hasFilters =
                  sizes.isNotEmpty || sexes.isNotEmpty || cities.isNotEmpty;

              final city = ref.watch(selectedCityProvider);
              // Los mosaicos y las píldoras se calculan sobre lo que pasa el
              // resto de los filtros: el número que muestran es exactamente lo
              // que se va a ver al tocarlos.
              final candidates = items
                  .where((dog) => _matchesExceptSpecies(dog, city))
                  .toList();
              final counts = <AnimalSpecies, int>{};
              final covers = <AnimalSpecies, String>{};
              for (final dog in candidates) {
                counts[dog.species] = (counts[dog.species] ?? 0) + 1;
                final photo = dog.coverPhoto?.publicUrl;
                if (photo != null) covers.putIfAbsent(dog.species, () => photo);
              }
              // Las edades salen de todo el catálogo y no de `candidates`,
              // porque si no elegir "Cachorro" apagaría todas las demás
              // píldoras y no habría cómo volver.
              final ages = items
                  .map((dog) => dog.ageGroup)
                  .whereType<AgeGroup>()
                  .toSet();

              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 3 : 2;
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
                          WoofyRefreshControl(onRefresh: refreshData),
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
                                        'Buscar perro, gato, refugio o ciudad',
                                    onChanged: (value) =>
                                        setState(() => _query = value),
                                    onFilterTap: hasFilters
                                        ? () => _openFilterSheet(
                                            sizes,
                                            sexes,
                                            cities,
                                          )
                                        : null,
                                    filterActive: filterActive,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Tipo de animal primero: es la decisión más grande y
                          // la que más achica la lista.
                          SliverToBoxAdapter(
                            child: SpeciesTiles(
                              counts: counts,
                              covers: covers,
                              selected: _species,
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontal,
                              ),
                              onSelected: (value) =>
                                  setState(() => _species = value),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: WoofySpacing.md,
                              ),
                              child: AgePills(
                                selected: _age,
                                available: ages,
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontal,
                                ),
                                onSelected: (value) =>
                                    setState(() => _age = value),
                              ),
                            ),
                          ),
                          if (sizes.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: WoofySpacing.sm,
                                ),
                                child: WoofyFilterChips(
                                  options: sizes,
                                  selected: _size,
                                  onSelected: (value) =>
                                      setState(() => _size = value),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontal,
                                  ),
                                ),
                              ),
                            ),
                          // La publicidad va después de los filtros y antes de
                          // los resultados: no se interpone entre buscar y
                          // encontrar, pero tampoco queda enterrada al final.
                          SliverToBoxAdapter(
                            child: BannerCarousel(
                              slot: BannerSlot.explore,
                              padding: EdgeInsets.fromLTRB(
                                horizontal,
                                WoofySpacing.lg,
                                horizontal,
                                0,
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: WoofySpacing.lg),
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
                                WoofySpacing.xxl +
                                    WoofyBottomNavigation.reservedHeight +
                                    MediaQuery.paddingOf(context).bottom,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _ResultSections(
                                  results: results,
                                  columns: columns,
                                  groupBySpecies: _species == null,
                                ),
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
    ref.read(selectedCityProvider.notifier).select(null);
    setState(() {
      _searchController.clear();
      _query = '';
      _size = _all;
      _sex = _all;
      _species = null;
      _age = null;
    });
  }

  Future<void> _openFilterSheet(
    List<WoofyFilterOption> sizes,
    List<WoofyFilterOption> sexes,
    List<WoofyFilterOption> cities,
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
                            _species = null;
                            _age = null;
                            ref
                                .read(selectedCityProvider.notifier)
                                .select(null);
                          }),
                          child: const Text('Limpiar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: WoofySpacing.sm),
                    // La ciudad vivía en el header de Home. Se mudó acá, junto
                    // al resto de los filtros del catálogo, que es donde se
                    // aplica.
                    if (cities.isNotEmpty)
                      _FilterRow(
                        key: const ValueKey('city-filter'),
                        label: 'Ciudad',
                        options: cities,
                        selected: ref.read(selectedCityProvider) ?? _all,
                        onSelected: (value) => select(
                          () => ref
                              .read(selectedCityProvider.notifier)
                              .select(value == _all ? null : value),
                        ),
                      ),
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

/// Los resultados, partidos en secciones con título.
///
/// Cuando no hay una especie elegida se agrupa por tipo de animal: la pantalla
/// deja de ser una grilla larga e indiferenciada y se lee como "acá están los
/// perros, acá los gatos". Cada animal aparece en una sola sección, nunca
/// repetido.
class _ResultSections extends StatelessWidget {
  const _ResultSections({
    required this.results,
    required this.columns,
    required this.groupBySpecies,
  });

  final List<Dog> results;
  final int columns;
  final bool groupBySpecies;

  @override
  Widget build(BuildContext context) {
    final grouped = <AnimalSpecies, List<Dog>>{};
    for (final dog in results) {
      grouped.putIfAbsent(dog.species, () => []).add(dog);
    }
    // Con un solo grupo, un título por especie no informa nada que el mosaico
    // seleccionado no diga ya. En su lugar se dice cuántos hay, que sí sirve.
    final bySpecies = groupBySpecies && grouped.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!bySpecies) ...[
          WoofySectionHeader(
            title: results.length == 1
                ? '1 animal disponible'
                : '${results.length} animales disponibles',
          ),
          const SizedBox(height: WoofySpacing.md),
          _DogsMasonry(dogs: results, columns: columns),
        ] else
          for (final species in AnimalSpecies.values)
            if (grouped[species] case final dogs?) ...[
              WoofySectionHeader(
                title: species.plural,
                subtitle: dogs.length == 1
                    ? '1 esperando un hogar'
                    : '${dogs.length} esperando un hogar',
              ),
              const SizedBox(height: WoofySpacing.md),
              _DogsMasonry(dogs: dogs, columns: columns),
              const SizedBox(height: WoofySpacing.xxxl),
            ],
      ],
    );
  }
}

/// Staggered catalog grid: cards are dealt round-robin into [columns] columns
/// and photos alternate shape, so neighbouring cards never line up.
///
/// Not a sliver: it builds every card at once. That is fine here because
/// `publishedDogsProvider` already holds the whole catalog in memory and
/// `_applyFilters` runs client-side. Revisit with a staggered sliver package
/// if the catalog ever grows past a few hundred animals.
class _DogsMasonry extends StatelessWidget {
  const _DogsMasonry({required this.dogs, required this.columns});

  static const _aspects = [16 / 11, 1.0, 16 / 11, 4 / 5];

  final List<Dog> dogs;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final buckets = List.generate(columns, (_) => <Widget>[]);
    for (final (index, dog) in dogs.indexed) {
      final column = buckets[index % columns];
      if (column.isNotEmpty) {
        column.add(const SizedBox(height: WoofySpacing.lg));
      }
      column.add(
        DogCard(
          dog: dog,
          compact: true,
          // Solo el catálogo prende el vuelo de la foto: acá cada perro
          // aparece una sola vez, así que no hay etiquetas repetidas.
          flyPhotoToDetail: true,
          aspectRatio: _aspects[index % _aspects.length],
          overlay: FavoriteToggleButton(dogId: dog.id),
          onTap: () => context.push(RoutePaths.dogDetail(dog.slug)),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, column) in buckets.indexed) ...[
          if (index > 0) const SizedBox(width: WoofySpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: column,
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
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
