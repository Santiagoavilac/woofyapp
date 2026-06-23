import 'package:flutter/material.dart';

class WoofyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WoofyAppBar({
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    super.key,
  });

  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}
