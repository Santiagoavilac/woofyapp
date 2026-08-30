import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/services/secure_storage_service.dart';

/// Hasta cuándo el usuario ya vio sus novedades.
///
/// Los mensajes tienen `read_at` en la base, pero los cambios de estado de
/// postulación no tienen dónde anotarse. En vez de crear una tabla se guarda
/// una marca de agua local: todo cambio anterior a esa marca ya fue visto.
///
/// Va detrás de una interfaz para poder mudarla al servidor más adelante sin
/// tocar el resto de la feature.
abstract interface class NotificationsReadStore {
  Future<DateTime?> lastSeenAt(String userId);

  Future<void> markSeen(String userId, DateTime at);
}

class SecureNotificationsReadStore implements NotificationsReadStore {
  const SecureNotificationsReadStore(this._storage);

  final SecureStorageService _storage;

  String _key(String userId) => 'notifications_seen_at:$userId';

  @override
  Future<DateTime?> lastSeenAt(String userId) async {
    final raw = await _storage.read(_key(userId));
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> markSeen(String userId, DateTime at) =>
      _storage.write(_key(userId), at.toUtc().toIso8601String());
}

final notificationsReadStoreProvider = Provider<NotificationsReadStore>(
  (ref) =>
      SecureNotificationsReadStore(ref.watch(secureStorageServiceProvider)),
);
