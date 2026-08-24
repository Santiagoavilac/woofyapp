import 'package:flutter/widgets.dart';

/// Consistent corner radius scale.
abstract final class WoofyRadius {
  static const control = 12.0; // small controls, chips
  static const field = 16.0; // inputs, buttons
  static const card = 22.0; // cards
  static const cardLarge = 26.0; // hero / photo cards
  static const pill = 999.0; // fully rounded

  static const BorderRadius controlAll = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius fieldAll = BorderRadius.all(Radius.circular(field));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius cardLargeAll = BorderRadius.all(
    Radius.circular(cardLarge),
  );
}
