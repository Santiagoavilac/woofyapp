import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WoofyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WoofyAppBar({
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.backFallbackLocation,
    super.key,
  });

  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  /// Where the back button goes when there is nothing to pop.
  ///
  /// Pages reached with `go` (a redirect, or a tab that bounces elsewhere)
  /// have an empty navigator stack, so Material draws no back arrow and a
  /// top-level route leaves the user with no visible way out. Setting this
  /// draws one anyway, mirroring [BackFallbackScope] so the button and the
  /// system back gesture end up in the same place.
  final String? backFallbackLocation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final fallback = backFallbackLocation;
    final needsManualBack =
        fallback != null &&
        automaticallyImplyLeading &&
        !Navigator.canPop(context);

    return AppBar(
      title: Text(title),
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: needsManualBack
          ? IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go(fallback),
            )
          : null,
    );
  }
}
