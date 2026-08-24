import 'package:flutter/material.dart';
import 'package:mi_app/core/theme/woofy_colors.dart';
import 'package:mi_app/core/theme/woofy_radius.dart';
import 'package:mi_app/core/theme/woofy_shadows.dart';

/// The three primary destinations. Order matches the shell branch order.
enum WoofyTab { home, explore, profile }

/// Bottom navigation for the primary shell. Outline icon when inactive,
/// filled when active, soft indicator. Respects the bottom SafeArea.
class WoofyBottomNavigation extends StatelessWidget {
  const WoofyBottomNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
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
        child: ClipRRect(
          borderRadius: WoofyRadius.cardLargeAll,
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Explorar',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
