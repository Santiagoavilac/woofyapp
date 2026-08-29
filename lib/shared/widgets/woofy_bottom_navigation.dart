import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_shadows.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';

/// The four primary destinations. Order matches the shell branch order.
enum WoofyTab { home, explore, vets, profile }

/// Floating bottom navigation for the primary shell.
///
/// The destinations sit in slots of equal width and a single coral pill slides
/// between them. La posición de la pastilla se recibe como `double`, no como
/// índice: mientras el dedo arrastra, el shell la mueve en fracciones y el
/// color de cada ítem se interpola, así el selector sigue al dedo en vez de
/// saltar recién al soltar.
///
/// Material's [NavigationBar] can't do a sliding indicator over custom slots,
/// so the row is built by hand. Respects the bottom SafeArea.
class WoofyBottomNavigation extends StatelessWidget {
  const WoofyBottomNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
    this.indicatorPosition,
    super.key,
  });

  static const _destinations = <_Destination>[
    _Destination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Inicio',
      slug: 'inicio',
    ),
    _Destination(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore_rounded,
      label: 'Explorar',
      slug: 'explorar',
    ),
    _Destination(
      icon: Icons.local_hospital_outlined,
      selectedIcon: Icons.local_hospital_rounded,
      label: 'Veterinarias',
      slug: 'veterinarias',
    ),
    _Destination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Perfil',
      slug: 'perfil',
    ),
  ];

  /// Vertical room the floating bar occupies, excluding the system inset.
  /// Scrollable pages under `extendBody: true` reserve this at the bottom so
  /// their last item can scroll clear of the bar.
  static const reservedHeight = 80.0;

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Posición de la pastilla en unidades de slot. `null` la deja sobre
  /// [currentIndex], que es lo que corresponde cuando no hay arrastre.
  final double? indicatorPosition;

  @override
  Widget build(BuildContext context) {
    final position = indicatorPosition ?? currentIndex.toDouble();

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: WoofyColors.surface,
          borderRadius: WoofyRadius.cardLargeAll,
          border: Border.fromBorderSide(BorderSide(color: WoofyColors.border)),
          boxShadow: WoofyShadows.soft,
        ),
        child: Padding(
          padding: const EdgeInsets.all(WoofySpacing.sm),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / _destinations.length;
              return Stack(
                children: [
                  Positioned(
                    left: slotWidth * position,
                    top: 0,
                    bottom: 0,
                    width: slotWidth,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: WoofyColors.accent,
                        borderRadius: WoofyRadius.cardLargeAll,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final (index, destination)
                          in _destinations.indexed)
                        SizedBox(
                          width: slotWidth,
                          child: _NavItem(
                            destination: destination,
                            isSelected: index == currentIndex,
                            // 1 cuando la pastilla está justo encima, 0 cuando
                            // está a un slot o más de distancia.
                            selection: (1 - (position - index).abs()).clamp(
                              0.0,
                              1.0,
                            ),
                            onTap: () => onDestinationSelected(index),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.slug,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Stable handle for tests and for semantics.
  final String slug;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.selection,
    required this.onTap,
  });

  final _Destination destination;
  final bool isSelected;

  /// Cuánto de la pastilla cubre este slot, de 0 a 1.
  final double selection;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        Color.lerp(WoofyColors.textSecondary, WoofyColors.white, selection) ??
        WoofyColors.textSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('nav-item-${destination.slug}'),
        onTap: onTap,
        borderRadius: WoofyRadius.cardLargeAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: WoofySpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selection > 0.5 ? destination.selectedIcon : destination.icon,
                color: foreground,
                size: 24,
              ),
              const SizedBox(height: WoofySpacing.xs),
              Text(
                destination.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
