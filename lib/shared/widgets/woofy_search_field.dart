import 'package:flutter/material.dart';

/// Rounded search field with a leading search icon and an optional filters
/// button. Presentational: the parent owns the controller and callbacks.
class WoofySearchField extends StatelessWidget {
  const WoofySearchField({
    required this.controller,
    this.hintText = 'Buscar',
    this.onChanged,
    this.onFilterTap,
    this.filterActive = false,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final bool filterActive;

  /// Qué hacer cuando lo tocan.
  ///
  /// Junto con [readOnly] convierte el campo en un botón con cara de buscador.
  /// Es lo que usa Inicio para abrir la pantalla de búsqueda, en vez de tener
  /// dos buscadores distintos y uno de ellos a medias.
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final children = <Widget>[
              if (value.text.isNotEmpty)
                IconButton(
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
              if (onFilterTap != null)
                _FilterButton(active: filterActive, onTap: onFilterTap!),
            ];
            if (children.isEmpty) return const SizedBox.shrink();
            return Row(mainAxisSize: MainAxisSize.min, children: children);
          },
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: 'Filtros',
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.tune_rounded,
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          if (active)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
