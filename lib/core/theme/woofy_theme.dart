import 'package:flutter/material.dart';
import 'package:mi_app/core/theme/woofy_colors.dart';
import 'package:mi_app/core/theme/woofy_typography.dart';

abstract final class WoofyTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: WoofyColors.primaryButton,
          brightness: Brightness.light,
        ).copyWith(
          primary: WoofyColors.primaryButton,
          onPrimary: WoofyColors.white,
          secondary: WoofyColors.pastelBlue,
          surface: WoofyColors.white,
          onSurface: WoofyColors.textDark,
          error: WoofyColors.error,
          outline: WoofyColors.border,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: WoofyColors.background,
    );

    return base.copyWith(
      textTheme: WoofyTypography.textTheme(base.textTheme).apply(
        bodyColor: WoofyColors.textDark,
        displayColor: WoofyColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: WoofyColors.background,
        foregroundColor: WoofyColors.textDark,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: WoofyColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: WoofyColors.border),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: WoofyColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: WoofyColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: WoofyColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: WoofyColors.primaryButton),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
