import 'package:intl/intl.dart';
import 'package:woofy/features/partners/data/money.dart';
import 'package:woofy/features/partners/data/partner_models.dart';

/// Armado de los enlaces de WhatsApp para pedidos y reservas.
///
/// El pedido ya quedó guardado en la base antes de llegar acá: este mensaje es
/// el aviso a la veterinaria, no el registro.
abstract final class WhatsappMessage {
  static const _boliviaCode = '591';

  /// Normaliza un número boliviano a formato internacional sin `+`.
  ///
  /// Las veterinarias cargan el número como se les ocurre (`70123456`,
  /// `+591 70-123456`, `(591) 70123456`), así que se limpia todo lo que no sea
  /// dígito y se antepone el código de país solo si falta.
  /// Devuelve `null` si no queda un número plausible.
  static String? normalizePhone(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.startsWith(_boliviaCode)) {
      final rest = digits.substring(_boliviaCode.length);
      return rest.length == 8 ? digits : null;
    }
    // Un 0 de prefijo nacional no viaja al formato internacional.
    final local = digits.startsWith('0') ? digits.substring(1) : digits;
    return local.length == 8 ? '$_boliviaCode$local' : null;
  }

  /// `https://wa.me/591XXXXXXXX?text=...` o `null` si el número no sirve.
  static Uri? buildUri({required String? phone, required String message}) {
    final normalized = normalizePhone(phone);
    if (normalized == null) return null;
    return Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );
  }

  static String orderText({
    required String partnerName,
    required List<({String name, int quantity, int unitPriceCents})> lines,
    required int totalCents,
    String? customerName,
    String? notes,
  }) {
    final buffer = StringBuffer()
      ..writeln('¡Hola $partnerName! Te hago un pedido desde Woofy.')
      ..writeln();
    for (final line in lines) {
      buffer.writeln(
        '• ${line.quantity}x ${line.name} — '
        '${Money.fromCents(line.unitPriceCents * line.quantity)}',
      );
    }
    buffer
      ..writeln()
      ..writeln('Total: ${Money.fromCents(totalCents)}');
    if (customerName != null && customerName.trim().isNotEmpty) {
      buffer.writeln('A nombre de: ${customerName.trim()}');
    }
    if (notes != null && notes.trim().isNotEmpty) {
      buffer.writeln('Nota: ${notes.trim()}');
    }
    buffer
      ..writeln()
      ..write('El pedido ya quedó registrado en tu panel de Woofy.');
    return buffer.toString();
  }

  static String reservationText({
    required String partnerName,
    required String serviceName,
    required int priceCents,
    required DateTime scheduledFor,
    String? petName,
    String? customerName,
    String? notes,
  }) {
    final when = DateFormat(
      "EEEE d 'de' MMMM 'a las' HH:mm",
      'es',
    ).format(scheduledFor);
    final buffer = StringBuffer()
      ..writeln('¡Hola $partnerName! Quiero reservar un turno desde Woofy.')
      ..writeln()
      ..writeln('Servicio: $serviceName')
      ..writeln('Fecha: $when')
      ..writeln('Precio: ${Money.fromCents(priceCents)}');
    if (petName != null && petName.trim().isNotEmpty) {
      buffer.writeln('Mascota: ${petName.trim()}');
    }
    if (customerName != null && customerName.trim().isNotEmpty) {
      buffer.writeln('A nombre de: ${customerName.trim()}');
    }
    if (notes != null && notes.trim().isNotEmpty) {
      buffer.writeln('Nota: ${notes.trim()}');
    }
    buffer
      ..writeln()
      ..write('La reserva ya quedó registrada en tu panel de Woofy.');
    return buffer.toString();
  }

  /// Enlace a Google Maps sin sumar un paquete de mapas.
  ///
  /// Va por búsqueda de texto y no por coordenadas: ninguna veterinaria sabe
  /// su latitud, pero todas saben su dirección, y Maps resuelve bien un nombre
  /// con calle y ciudad.
  static Uri mapsUri(Partner partner) {
    final query = [
      partner.name,
      partner.address,
      partner.city,
    ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
  }
}
