import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/shared/widgets/woofy_press.dart';

/// Fila de categorías por tipo de animal, arriba de todo en Explorar.
///
/// Antes lo primero que se veía era una grilla de tarjetas sueltas: no había
/// forma de entender de un vistazo qué hay ni de acotar la búsqueda sin abrir
/// el panel de filtros. Con los mosaicos, la primera decisión ("¿perro o
/// gato?") se toma en un toque y la pantalla deja de sentirse vacía.
///
/// La imagen de cada mosaico es la foto de uno de los animales de esa
/// categoría, no un ícono genérico: no hace falta agregar ilustraciones al
/// bundle y lo que se ve es lo que hay realmente.
class SpeciesTiles extends StatelessWidget {
  const SpeciesTiles({
    required this.counts,
    required this.covers,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: WoofySpacing.lg),
    super.key,
  });

  /// Piezas del alto del mosaico: la foto, el aro de selección que la rodea y
  /// las dos líneas de texto.
  ///
  /// El alto lo tiene que fijar el `ListView` horizontal, así que no puede
  /// salir del contenido. Con un número fijo el mosaico se cortaba abajo apenas
  /// alguien agrandaba la tipografía del sistema; por eso solo la parte de
  /// texto se escala.
  static const _photo = 64.0;
  static const _ring = 3.0;
  static const _text = 40.0;
  static const _width = 96.0;

  static double _heightOf(BuildContext context) =>
      _photo +
      _ring * 2 +
      WoofySpacing.xs +
      MediaQuery.textScalerOf(context).scale(_text);

  /// Cuántos animales hay de cada especie con el resto de los filtros puestos.
  /// Lo que dice el número es lo que se va a ver al tocar.
  final Map<AnimalSpecies, int> counts;

  /// Foto de portada por especie, si alguno tiene.
  final Map<AnimalSpecies, String> covers;

  /// `null` quiere decir "todos".
  final AnimalSpecies? selected;

  final ValueChanged<AnimalSpecies?> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // Están siempre las tres, incluso en cero. No son un filtro más: son lo
    // primero que se ve al entrar y lo que dice de qué se trata Woofy. Mostrar
    // solo lo que hay hoy —puros perros— haría creer que la app es de perros, y
    // el contador en cero es información honesta, no una promesa incumplida:
    // dice "todavía no hay gatos", no "acá no van gatos".
    const species = AnimalSpecies.values;
    final total = counts.values.fold(0, (sum, value) => sum + value);
    return SizedBox(
      height: _heightOf(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: species.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: WoofySpacing.md),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Tile(
              key: const ValueKey('species-tile-todos'),
              label: 'Todos',
              count: total,
              imageUrl:
                  covers[AnimalSpecies.perro] ?? covers.values.firstOrNull,
              isSelected: selected == null,
              onTap: () => onSelected(null),
            );
          }
          final item = species[index - 1];
          return _Tile(
            key: ValueKey('species-tile-${item.value}'),
            label: item.plural,
            count: counts[item] ?? 0,
            imageUrl: covers[item],
            isSelected: selected == item,
            onTap: () => onSelected(selected == item ? null : item),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.count,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final int count;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: WoofyPressable(
        child: SizedBox(
          width: SpeciesTiles._width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // El borde de selección va por fuera de la foto y no encima:
              // sobre una imagen oscura un borde interior no se distingue.
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(SpeciesTiles._ring),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? WoofyColors.primary : Colors.transparent,
                ),
                child: ClipOval(
                  child: SizedBox.square(
                    dimension: SpeciesTiles._photo,
                    child: _cover(),
                  ),
                ),
              ),
              const SizedBox(height: WoofySpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  // Una especie sin animales se ve apagada: sigue estando y se
                  // puede tocar, pero no compite con las que tienen algo.
                  color: isSelected
                      ? WoofyColors.primary
                      : count == 0
                      ? WoofyColors.textSecondary
                      : WoofyColors.textPrimary,
                ),
              ),
              Text(
                '$count',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: WoofyColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cover() {
    final url = imageUrl;
    if (url == null) {
      // Sin foto propia queda la huella. Apagada cuando no hay ningún animal de
      // esa especie, para que el mosaico se lea como "acá todavía no hay nada".
      return ColoredBox(
        color: count == 0 ? WoofyColors.surfaceMuted : WoofyColors.primarySoft,
        child: Icon(
          Icons.pets_rounded,
          color: count == 0 ? WoofyColors.textSecondary : WoofyColors.primary,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) =>
          const ColoredBox(color: WoofyColors.surfaceMuted),
      errorWidget: (context, _, _) => const ColoredBox(
        color: WoofyColors.primarySoft,
        child: Icon(Icons.pets_rounded, color: WoofyColors.primary),
      ),
    );
  }
}

/// Ficha compacta de un filtro rápido, con la forma de píldora del resto de la
/// app. Se usa para las edades: son cuatro opciones y no merecen abrir un panel.
class AgePills extends StatelessWidget {
  const AgePills({
    required this.selected,
    required this.available,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: WoofySpacing.lg),
    super.key,
  });

  /// `null` quiere decir "todas las edades".
  final AgeGroup? selected;

  /// Etapas que hoy tienen al menos un animal. Ofrecer una que devuelve cero
  /// resultados es mandar a la persona contra una pared.
  final Set<AgeGroup> available;

  final ValueChanged<AgeGroup?> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (available.length < 2) return const SizedBox.shrink();
    final groups = AgeGroup.values.where(available.contains).toList();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: groups.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: WoofySpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _pill(
              context,
              key: const ValueKey('age-pill-todas'),
              label: 'Todas las edades',
              isSelected: selected == null,
              onTap: () => onSelected(null),
            );
          }
          final group = groups[index - 1];
          return _pill(
            context,
            key: ValueKey('age-pill-${group.value}'),
            label: group.label,
            isSelected: selected == group,
            onTap: () => onSelected(selected == group ? null : group),
          );
        },
      ),
    );
  }

  Widget _pill(
    BuildContext context, {
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(WoofyRadius.pill)),
      ),
    );
  }
}
