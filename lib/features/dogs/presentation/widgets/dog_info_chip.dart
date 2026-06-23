import 'package:flutter/material.dart';

class DogInfoChip extends StatelessWidget {
  const DogInfoChip({required this.label, required this.icon, super.key});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(label),
      side: BorderSide(color: Theme.of(context).colorScheme.outline),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
