/// De qué habla una novedad.
enum WoofyNotificationKind {
  /// Alguien te escribió y todavía no lo leíste.
  message,

  /// Una postulación tuya cambió de estado.
  applicationStatus,
}

/// Una novedad del panel de la campana.
///
/// No hay tabla de notificaciones: cada novedad se deriva de datos que ya
/// existen (mensajes sin leer, postulaciones que cambiaron). Por eso el [id]
/// es determinístico y no autogenerado: es lo único que permite reconocer la
/// misma novedad entre dos cargas.
class WoofyNotification {
  const WoofyNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.route,
    required this.isUnread,
  });

  final String id;
  final WoofyNotificationKind kind;
  final String title;
  final String body;
  final DateTime timestamp;

  /// A dónde lleva el tap.
  final String route;

  final bool isUnread;
}
