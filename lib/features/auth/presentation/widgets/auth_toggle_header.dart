import 'package:flutter/material.dart';

class AuthToggleHeader extends StatelessWidget {
  const AuthToggleHeader({
    required this.isRegistering,
    required this.onChanged,
    super.key,
  });

  final bool isRegistering;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, label: Text('Ingresar')),
        ButtonSegment(value: true, label: Text('Crear cuenta')),
      ],
      selected: {isRegistering},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
    );
  }
}
