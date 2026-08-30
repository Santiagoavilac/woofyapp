import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/search/data/search_providers.dart';
import 'package:woofy/shared/widgets/woofy_app_bar.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';
import 'package:woofy/shared/widgets/woofy_empty_state.dart';
import 'package:woofy/shared/widgets/woofy_search_field.dart';
import 'package:woofy/shared/widgets/woofy_section_header.dart';

/// Buscador general: animales, tienda, veterinarias y servicios en una sola
/// pantalla.
///
/// El campo de Inicio antes no hacía nada — se podía escribir y no pasaba
/// nada. Ahora abre esta pantalla, que es la única que busca en todo Woofy a
/// la vez. Explorar sigue teniendo su propio buscador porque ahí se busca
/// dentro del catálogo, con los filtros puestos.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({this.initialQuery = '', super.key});

  final String initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  /// Atajos para el que abre el buscador sin saber qué escribir. Son las
  /// palabras que la gente usa, no las que guarda la base: de traducirlas se
  /// encarga el buscador.
  static const _suggestions = [
    'Perros',
    'Gatos',
    'Cachorros',
    'Poleras',
    'Veterinaria',
    'Peluquería',
  ];

  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );
  late String _query = widget.initialQuery;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() => _query = value);
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider(_query));
    final typed = _query.trim().isNotEmpty;

    return Scaffold(
      appBar: const WoofyAppBar(
        title: 'Buscar',
        backFallbackLocation: RoutePaths.landing,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WoofySpacing.lg,
                WoofySpacing.md,
                WoofySpacing.lg,
                WoofySpacing.md,
              ),
              child: WoofySearchField(
                key: const ValueKey('global-search-field'),
                controller: _controller,
                autofocus: widget.initialQuery.isEmpty,
                hintText: 'Buscar animales, poleras, veterinarias…',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: !typed
                  ? _Suggestions(suggestions: _suggestions, onTap: _search)
                  : _Results(results: results),
            ),
          ],
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.suggestions, required this.onTap});

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: WoofySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Búsquedas frecuentes', style: theme.textTheme.titleMedium),
          const SizedBox(height: WoofySpacing.md),
          Wrap(
            spacing: WoofySpacing.sm,
            runSpacing: WoofySpacing.sm,
            children: [
              for (final suggestion in suggestions)
                ActionChip(
                  key: ValueKey('search-suggestion-$suggestion'),
                  label: Text(suggestion),
                  onPressed: () => onTap(suggestion),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(WoofyRadius.pill),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      // Mientras falte alguna fuente, "no hay nada" sería mentira.
      if (results.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return const WoofyEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados',
        message:
            'No encontramos nada con esa búsqueda. '
            'Probá con otra palabra, más corta.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WoofySpacing.lg,
        0,
        WoofySpacing.lg,
        WoofySpacing.xxxl,
      ),
      children: [
        for (final kind in SearchHitKind.values)
          if (results.of(kind) case final hits when hits.isNotEmpty) ...[
            WoofySectionHeader(
              title: kind.plural,
              subtitle: hits.length == 1
                  ? '1 resultado'
                  : '${hits.length} resultados',
            ),
            const SizedBox(height: WoofySpacing.md),
            for (final hit in hits) ...[
              _HitTile(hit: hit),
              const SizedBox(height: WoofySpacing.sm),
            ],
            const SizedBox(height: WoofySpacing.lg),
          ],
      ],
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit});

  final SearchHit hit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WoofyCard(
      padding: const EdgeInsets.all(WoofySpacing.md),
      tapKey: ValueKey('search-hit-${hit.id}'),
      onTap: () => context.push(hit.route),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: WoofyRadius.controlAll,
            child: SizedBox.square(dimension: 56, child: _thumb()),
          ),
          const SizedBox(width: WoofySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                if (hit.subtitle case final subtitle?
                    when subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WoofyColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: WoofyColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _thumb() {
    final url = hit.imageUrl;
    if (url == null) {
      return ColoredBox(
        color: WoofyColors.primarySoft,
        child: Icon(hit.kind.icon, color: WoofyColors.primary),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) =>
          const ColoredBox(color: WoofyColors.surfaceMuted),
      errorWidget: (context, _, _) => ColoredBox(
        color: WoofyColors.primarySoft,
        child: Icon(hit.kind.icon, color: WoofyColors.primary),
      ),
    );
  }
}
