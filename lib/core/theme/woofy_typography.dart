import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class WoofyTypography {
  static TextTheme textTheme(TextTheme base) {
    final bodyTheme = GoogleFonts.nunitoTextTheme(base);
    return bodyTheme.copyWith(
      displayLarge: GoogleFonts.fraunces(textStyle: bodyTheme.displayLarge),
      displayMedium: GoogleFonts.fraunces(textStyle: bodyTheme.displayMedium),
      displaySmall: GoogleFonts.fraunces(textStyle: bodyTheme.displaySmall),
      headlineLarge: GoogleFonts.fraunces(textStyle: bodyTheme.headlineLarge),
      headlineMedium: GoogleFonts.fraunces(textStyle: bodyTheme.headlineMedium),
      headlineSmall: GoogleFonts.fraunces(textStyle: bodyTheme.headlineSmall),
      titleLarge: GoogleFonts.fraunces(textStyle: bodyTheme.titleLarge),
    );
  }
}
