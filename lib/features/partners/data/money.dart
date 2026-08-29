import 'package:intl/intl.dart';

/// Formateo de dinero de la sección Veterinarias.
///
/// Vive acá y no en `core/` a propósito: la adopción es gratis y no debe tener
/// ningún helper de precios a mano. Si esto estuviera en `shared/`, tarde o
/// temprano alguien pinta un precio en una tarjeta de perro.
abstract final class Money {
  static final _format = NumberFormat.currency(
    locale: 'es_BO',
    symbol: 'Bs',
    decimalDigits: 2,
  );

  /// `15000` -> `Bs 150,00`. Entra en centavos, siempre.
  static String fromCents(int cents) => _format.format(cents / 100);
}
