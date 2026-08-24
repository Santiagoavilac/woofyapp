import 'package:flutter/material.dart';

/// Woofy visual palette. Warm, calm and multi-species friendly.
///
/// Soft blue is the functional primary, sage green the secondary,
/// coral/peach the emotional accent. Backgrounds sit close to warm ivory.
abstract final class WoofyColors {
  // Surfaces
  static const background = Color(0xFFFBF8F4); // warm ivory
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF3EFE8); // subtle warm panel
  static const white = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF1B2A33); // dark ink, not pure black
  static const textSecondary = Color(0xFF6B7683); // blue-gray secondary

  // Brand
  static const primary = Color(0xFF4F86C7); // soft medium blue
  static const primarySoft = Color(0xFFDCE8F5); // primary container (celeste)
  static const secondary = Color(0xFF8FB39B); // sage green
  static const secondarySoft = Color(0xFFE2ECE4); // sage container
  static const accent = Color(0xFFF0A085); // coral / peach
  static const accentSoft = Color(0xFFF9E4DA); // coral container

  // Feedback
  static const error = Color(0xFFC9564E); // moderate red
  static const success = Color(0xFF6FA98B); // light green

  // Lines
  static const border = Color(0xFFECE6DD); // very tenuous warm gray
}
