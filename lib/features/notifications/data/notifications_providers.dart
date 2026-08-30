import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/features/applications/data/application_models.dart';
import 'package:woofy/features/applications/data/applications_providers.dart';
import 'package:woofy/features/messages/data/message_models.dart';
import 'package:woofy/features/messages/data/messages_providers.dart';
import 'package:woofy/features/notifications/data/notification_models.dart';
import 'package:woofy/features/notifications/data/notifications_read_store.dart';

// Todo lo de acá se indexa por el id del usuario en vez de mirar la sesión.
//
// La campana vive en Inicio, así que estos providers quedan vivos mientras la
// pantalla está montada. Si escucharan al provider de sesión, cada recálculo
// de la sesión los invalidaría en medio del build de Inicio y Riverpod tiene
// que reprogramar todo el árbol desde adentro de un build. Quién es el usuario
// lo resuelve el widget, que sí puede reconstruirse tranquilo.

/// Marca de agua: hasta cuándo el usuario ya vio los cambios de postulación.
final notificationsSeenAtProvider = FutureProvider.family<DateTime?, String>(
  (ref, userId) => ref.watch(notificationsReadStoreProvider).lastSeenAt(userId),
);

final unreadThreadsProvider = FutureProvider.family<List<UnreadThread>, String>(
  (ref, userId) => ref.watch(messagesRepositoryProvider).fetchUnreadThreads(),
);

final myApplicationsProvider =
    FutureProvider.family<List<AdoptionApplication>, String>(
      (ref, userId) =>
          ref.watch(applicationsRepositoryProvider).fetchMyApplications(),
    );

final notificationThreadsProvider =
    FutureProvider.family<List<ConversationThread>, String>(
      (ref, userId) => ref.watch(messagesRepositoryProvider).fetchMyThreads(),
    );

/// Las novedades del panel de la campana, de la más reciente a la más vieja.
final notificationsProvider =
    FutureProvider.family<List<WoofyNotification>, String>((ref, userId) async {
      final unread = await ref.watch(unreadThreadsProvider(userId).future);
      final applications = await ref.watch(
        myApplicationsProvider(userId).future,
      );
      final seenAt = await ref.watch(
        notificationsSeenAtProvider(userId).future,
      );
      final threads = await ref.watch(
        notificationThreadsProvider(userId).future,
      );

      final byThreadId = {for (final thread in threads) thread.id: thread};

      return <WoofyNotification>[
        for (final item in unread) _fromUnread(item, byThreadId[item.threadId]),
        for (final application in applications)
          if (_isNews(application, seenAt)) _fromApplication(application),
      ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });

/// Cuántas novedades sin ver hay. Es lo que muestra el globito de la campana.
final unreadNotificationsCountProvider = Provider.family<int, String>((
  ref,
  userId,
) {
  final items = ref.watch(notificationsProvider(userId)).value;
  if (items == null) return 0;
  return items.where((item) => item.isUnread).length;
});

/// Deja todas las novedades de postulación como vistas.
///
/// No toca los mensajes a propósito: esos se marcan leídos al abrir la
/// conversación. Abrir el panel no es leer lo que dice adentro.
final notificationsSeenControllerProvider =
    NotifierProvider.family<NotificationsSeenController, bool, String>(
      NotificationsSeenController.new,
    );

class NotificationsSeenController extends Notifier<bool> {
  NotificationsSeenController(this.userId);

  final String userId;

  @override
  bool build() => false;

  Future<void> markAllSeen() async {
    await ref
        .read(notificationsReadStoreProvider)
        .markSeen(userId, DateTime.now());
    ref.invalidate(notificationsSeenAtProvider(userId));
  }
}

WoofyNotification _fromUnread(UnreadThread unread, ConversationThread? thread) {
  final shelter = thread?.displayShelterName ?? 'Un refugio';
  final dog = thread?.displayDogName;
  return WoofyNotification(
    id: 'msg:${unread.threadId}',
    kind: WoofyNotificationKind.message,
    title: dog == null ? shelter : '$shelter · $dog',
    body:
        thread?.lastMessagePreview ??
        (unread.count == 1
            ? 'Tenés un mensaje sin leer.'
            : 'Tenés ${unread.count} mensajes sin leer.'),
    timestamp: unread.latestAt,
    route: RoutePaths.conversation(unread.threadId),
    isUnread: true,
  );
}

WoofyNotification _fromApplication(AdoptionApplication application) {
  final dog = application.dogName ?? 'tu postulación';
  final slug = application.dogSlug;
  return WoofyNotification(
    id: 'app:${application.id}:${application.status.value}',
    kind: WoofyNotificationKind.applicationStatus,
    title: 'Novedades de $dog',
    body: _statusBody(application.status, dog),
    timestamp: application.updatedAt,
    // Sin slug no hay ficha a la que ir; los mensajes son el lugar donde el
    // refugio va a explicar el cambio, así que es el mejor destino de reserva.
    route: slug == null ? RoutePaths.messages : RoutePaths.dogDetail(slug),
    isUnread: true,
  );
}

String _statusBody(ApplicationStatus status, String dog) => switch (status) {
  ApplicationStatus.reviewing => 'El refugio está revisando tu postulación.',
  ApplicationStatus.interview => 'Te quieren conocer: hay una entrevista.',
  ApplicationStatus.approved => '¡Aprobada! $dog está más cerca de casa.',
  ApplicationStatus.rejected => 'Esta vez no salió. Hay muchos esperando.',
  ApplicationStatus.withdrawn => 'Tu postulación quedó retirada.',
  ApplicationStatus.completed => '¡$dog ya tiene hogar con vos!',
  ApplicationStatus.submitted => 'Tu postulación fue enviada.',
};

/// Una postulación es novedad si ya se movió de "enviada" y cambió después de
/// la última vez que el usuario abrió el panel.
bool _isNews(AdoptionApplication application, DateTime? seenAt) {
  if (application.status == ApplicationStatus.submitted) return false;
  if (seenAt == null) return true;
  return application.updatedAt.isAfter(seenAt);
}
