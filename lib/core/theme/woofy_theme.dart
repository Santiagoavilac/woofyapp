import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_typography.dart';

abstract final class WoofyTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: WoofyColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: WoofyColors.primary,
          onPrimary: WoofyColors.white,
          primaryContainer: WoofyColors.primarySoft,
          onPrimaryContainer: WoofyColors.textPrimary,
          secondary: WoofyColors.secondary,
          onSecondary: WoofyColors.white,
          secondaryContainer: WoofyColors.secondarySoft,
          onSecondaryContainer: WoofyColors.textPrimary,
          tertiary: WoofyColors.accent,
          onTertiary: WoofyColors.white,
          tertiaryContainer: WoofyColors.accentSoft,
          onTertiaryContainer: WoofyColors.textPrimary,
          surface: WoofyColors.surface,
          onSurface: WoofyColors.textPrimary,
          surfaceContainerHighest: WoofyColors.surfaceMuted,
          onSurfaceVariant: WoofyColors.textSecondary,
          error: WoofyColors.error,
          outline: WoofyColors.border,
          outlineVariant: WoofyColors.border,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: WoofyColors.background,
    );

    return base.copyWith(
      textTheme: WoofyTypography.textTheme(base.textTheme).apply(
        bodyColor: WoofyColors.textPrimary,
        displayColor: WoofyColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: WoofyColors.background,
        foregroundColor: WoofyColors.textPrimary,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: WoofyColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      cardTheme: const CardThemeData(
        color: WoofyColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: WoofyRadius.cardAll,
          side: BorderSide(color: WoofyColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: WoofyColors.surface,
        side: const BorderSide(color: WoofyColors.border),
        shape: const RoundedRectangleBorder(
          borderRadius: WoofyRadius.controlAll,
        ),
        labelStyle: const TextStyle(
          color: WoofyColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WoofyColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: const OutlineInputBorder(
          borderRadius: WoofyRadius.fieldAll,
          borderSide: BorderSide(color: WoofyColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: WoofyRadius.fieldAll,
          borderSide: BorderSide(color: WoofyColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: WoofyRadius.fieldAll,
          borderSide: BorderSide(color: WoofyColors.primary, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: WoofyRadius.fieldAll,
          borderSide: BorderSide(color: WoofyColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: WoofyRadius.fieldAll,
          borderSide: BorderSide(color: WoofyColors.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          backgroundColor: WoofyColors.primary,
          foregroundColor: WoofyColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WoofyRadius.field),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          foregroundColor: WoofyColors.primary,
          side: const BorderSide(color: WoofyColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WoofyRadius.field),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: WoofyColors.primary),
      ),
      dividerTheme: const DividerThemeData(
        color: WoofyColors.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: WoofyColors.surface,
        indicatorColor: WoofyColors.primarySoft,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? WoofyColors.primary
                : WoofyColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? WoofyColors.primary
                : WoofyColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
