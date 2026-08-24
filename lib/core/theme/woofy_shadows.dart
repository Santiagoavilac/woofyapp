import 'package:flutter/material.dart';

/// Very soft elevations. Separation comes mostly from surface + border,
/// these are only for gentle lift on floating elements and cards.
abstract final class WoofyShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x14202A33), // ~8% dark ink
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0F202A33), // ~6% dark ink
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
