import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';

class WoofyFilterOption {
  const WoofyFilterOption({required this.value, required this.label});

  final String value;
  final String label;
}

/// Horizontal, single-select filter chips. Purely presentational — the parent
/// owns the selected value and reacts to [onSelected].
class WoofyFilterChips extends StatelessWidget {
  const WoofyFilterChips({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: WoofySpacing.lg),
    super.key,
  });

  final List<WoofyFilterOption> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: WoofySpacing.sm),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selected;
          return ChoiceChip(
            label: Text(option.label),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(option.value),
            backgroundColor: theme.colorScheme.surface,
            selectedColor: theme.colorScheme.primary,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(
              horizontal: WoofySpacing.md,
              vertical: WoofySpacing.sm,
            ),
          );
        },
      ),
    );
  }
}
