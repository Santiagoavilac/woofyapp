import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single-family type system built on Inter.
/// Weights: 400 (body), 500 (labels), 600 (titles), 700 (display).
/// No serif. Modern and human, strong hierarchy, generous readability.
abstract final class WoofyTypography {
  static TextTheme textTheme(TextTheme base) {
    final inter = GoogleFonts.interTextTheme(base);
    return inter.copyWith(
      displayLarge: inter.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.08,
      ),
      displayMedium: inter.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      displaySmall: inter.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.12,
      ),
      headlineLarge: inter.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.15,
      ),
      headlineMedium: inter.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.18,
      ),
      headlineSmall: inter.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.2,
      ),
      titleLarge: inter.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleMedium: inter.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: inter.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: inter.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: inter.bodyMedium?.copyWith(height: 1.45),
      labelLarge: inter.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelMedium: inter.labelMedium?.copyWith(fontWeight: FontWeight.w500),
    );
  }
}
