import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/features/applications/data/application_models.dart';
import 'package:woofy/features/applications/data/applications_providers.dart';
import 'package:woofy/features/applications/data/applications_repository.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/data/auth_repository.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/messages/data/message_models.dart';
import 'package:woofy/features/messages/data/messages_providers.dart';
import 'package:woofy/features/messages/data/messages_repository.dart';
import 'package:woofy/features/notifications/data/notification_models.dart';
import 'package:woofy/features/notifications/data/notifications_providers.dart';
import 'package:woofy/features/notifications/data/notifications_read_store.dart';
import 'package:woofy/features/notifications/presentation/widgets/notifications_bell.dart';

const _user = AppUser(id: 'user-1', email: 'ana@example.com');

ProviderContainer _container({
  List<UnreadThread> unread = const [],
  List<AdoptionApplication> applications = const [],
  DateTime? seenAt,
  AppUser? user = _user,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user)),
      messagesRepositoryProvider.overrideWithValue(
        _FakeMessagesRepository(unread: unread),
      ),
      applicationsRepositoryProvider.overrideWithValue(
        _FakeApplicationsRepository(applications),
      ),
      notificationsReadStoreProvider.overrideWithValue(
        _MemoryReadStore(seenAt: seenAt),
      ),
    ],
  );
  return container;
}

Future<void> _pumpBell(
  WidgetTester tester, {
  List<UnreadThread> unread = const [],
  List<AdoptionApplication> applications = const [],
  DateTime? seenAt,
  AppUser? user = _user,
  Size size = const Size(412, 915),
  bool reduceMotion = false,
  Widget? trailing,
}) async {
  final container = _container(
    unread: unread,
    applications: applications,
    seenAt: seenAt,
    user: user,
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          // Arriba a la derecha, como en Inicio: el panel crece desde ahí.
          body: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NotificationsBell(),
                  // En Inicio la campana tiene el botón de perfil a su derecha:
                  // no está pegada al borde, y de ahí salía el desborde.
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/mensajes/:threadId',
        builder: (context, state) => const Scaffold(body: Text('conversación')),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const Scaffold(body: Text('ingresar')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

UnreadThread _unread(String threadId, {int count = 1}) => UnreadThread(
  threadId: threadId,
  count: count,
  latestAt: DateTime(2026, 8, 29, 10),
);

AdoptionApplication _application(
  ApplicationStatus status, {
  DateTime? updatedAt,
}) => AdoptionApplication(
  id: 'application-1',
  dogId: 'dog-1',
  adopterId: 'user-1',
  shelterId: 'shelter-1',
  status: status,
  createdAt: DateTime(2026, 8, 20),
  updatedAt: updatedAt ?? DateTime(2026, 8, 28),
  dogName: 'Milo',
  dogSlug: 'milo-demo',
);

/// El [ScaleTransition] del panel, no el del globito de la campana.
final _panelScale = find
    .ancestor(
      of: find.byKey(const ValueKey('notifications-panel')),
      matching: find.byType(ScaleTransition),
    )
    .first;

void main() {
  group('qué cuenta como novedad', () {
    test('un mensaje sin leer trae el refugio y el perro del hilo', () async {
      final container = _container(unread: [_unread('thread-1')]);
      addTearDown(container.dispose);

      final items = await container.read(
        notificationsProvider('user-1').future,
      );
      expect(items, hasLength(1));
      expect(items.single.id, 'msg:thread-1');
      expect(items.single.kind, WoofyNotificationKind.message);
      expect(items.single.title, contains('Milo'));
      expect(items.single.route, '/mensajes/thread-1');
    });

    test('una postulación recién enviada no es novedad', () async {
      final container = _container(
        applications: [_application(ApplicationStatus.submitted)],
      );
      addTearDown(container.dispose);

      expect(await container.read(notificationsProvider('user-1').future), []);
    });

    test('un cambio de estado sí lo es, y lleva a la ficha', () async {
      final container = _container(
        applications: [_application(ApplicationStatus.approved)],
      );
      addTearDown(container.dispose);

      final items = await container.read(
        notificationsProvider('user-1').future,
      );
      expect(items.single.id, 'app:application-1:approved');
      expect(items.single.route, '/perros/milo-demo');
      expect(items.single.body, contains('Milo'));
    });

    test('un cambio anterior a la marca de agua ya no molesta', () async {
      final container = _container(
        applications: [
          _application(
            ApplicationStatus.approved,
            updatedAt: DateTime(2026, 8, 20),
          ),
        ],
        seenAt: DateTime(2026, 8, 25),
      );
      addTearDown(container.dispose);

      expect(await container.read(notificationsProvider('user-1').future), []);
    });

    test('las novedades salen de la más nueva a la más vieja', () async {
      final container = _container(
        unread: [_unread('thread-1')],
        applications: [
          _application(
            ApplicationStatus.interview,
            updatedAt: DateTime(2026, 8, 30),
          ),
        ],
      );
      addTearDown(container.dispose);

      final items = await container.read(
        notificationsProvider('user-1').future,
      );
      expect(items.map((item) => item.id), [
        'app:application-1:interview',
        'msg:thread-1',
      ]);
    });
  });

  group('la campana', () {
    testWidgets('muestra el contador y abre el panel', (tester) async {
      await _pumpBell(tester, unread: [_unread('thread-1', count: 3)]);

      expect(find.text('1'), findsOneWidget);
      expect(find.byKey(const ValueKey('notifications-panel')), findsNothing);

      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('notifications-panel')), findsOneWidget);
      expect(find.text('Novedades'), findsOneWidget);
    });

    testWidgets('el panel crece desde la campana', (tester) async {
      await _pumpBell(tester, unread: [_unread('t-1')]);

      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final scale = tester.widget<ScaleTransition>(_panelScale);
      expect(scale.scale.value, lessThan(1));

      await tester.pumpAndSettle();
      expect(scale.scale.value, 1);
    });

    testWidgets('tocar una novedad cierra el panel y abre el destino', (
      tester,
    ) async {
      await _pumpBell(tester, unread: [_unread('thread-1')]);

      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('notification-msg:thread-1')));
      await tester.pumpAndSettle();

      expect(find.text('conversación'), findsOneWidget);
      expect(find.byKey(const ValueKey('notifications-panel')), findsNothing);
    });

    testWidgets('tocar el fondo lo cierra', (tester) async {
      await _pumpBell(tester, unread: [_unread('t-1')]);

      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 800));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('notifications-panel')), findsNothing);
    });

    testWidgets('sin novedades dice que está todo al día', (tester) async {
      await _pumpBell(tester);

      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();

      expect(find.text('Todo al día'), findsOneWidget);
    });

    testWidgets('sin sesión la campana lleva a iniciar sesión', (tester) async {
      await _pumpBell(tester, user: null);

      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();

      expect(find.text('ingresar'), findsOneWidget);
    });

    testWidgets('con movimiento reducido el panel está entero de una', (
      tester,
    ) async {
      await _pumpBell(
        tester,
        unread: [_unread('thread-1')],
        reduceMotion: true,
      );

      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pump();
      await tester.pump();

      final scale = tester.widget<ScaleTransition>(_panelScale);
      expect(scale.scale.value, 1);
      expect(find.text('Novedades'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('el panel entra en una pantalla de 320x568', (tester) async {
      await _pumpBell(
        tester,
        unread: [_unread('thread-1'), _unread('thread-2')],
        size: const Size(320, 568),
      );

      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('notifications-panel')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final size in <Size>[const Size(320, 568), const Size(412, 915)]) {
      testWidgets('con un botón al lado el panel no se sale por la izquierda '
          'en ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        // La campana no está pegada al borde: tiene el botón de perfil a su
        // derecha. El panel cuelga de la campana y crece hacia la izquierda,
        // así que si no mide ese espacio se sale y corta el título.
        await _pumpBell(
          tester,
          unread: [_unread('thread-1')],
          size: size,
          trailing: const SizedBox.square(dimension: 48),
        );

        await tester.tap(find.byTooltip('Notificaciones'));
        await tester.pumpAndSettle();

        final panel = tester.getRect(
          find.byKey(const ValueKey('notifications-panel')),
        );
        expect(panel.left, greaterThanOrEqualTo(0));
        expect(panel.right, lessThanOrEqualTo(size.width));
        expect(find.text('Novedades'), findsOneWidget);
      });
    }
  });
}

class _MemoryReadStore implements NotificationsReadStore {
  _MemoryReadStore({this.seenAt});

  DateTime? seenAt;

  @override
  Future<DateTime?> lastSeenAt(String userId) async => seenAt;

  @override
  Future<void> markSeen(String userId, DateTime at) async => seenAt = at;
}

class _FakeMessagesRepository implements MessagesRepository {
  _FakeMessagesRepository({this.unread = const []});

  final List<UnreadThread> unread;

  @override
  Future<List<UnreadThread>> fetchUnreadThreads() async => unread;

  @override
  Future<void> markThreadRead(String threadId) async {}

  @override
  Future<List<ConversationThread>> fetchMyThreads() async => [
    for (final item in unread)
      ConversationThread(
        id: item.threadId,
        dogId: 'dog-1',
        shelterId: 'shelter-1',
        adopterId: 'user-1',
        status: 'open',
        createdAt: DateTime(2026, 8, 20),
        updatedAt: DateTime(2026, 8, 20),
        dogName: 'Milo',
        shelterName: 'Refugio Woofy',
      ),
  ];

  @override
  Future<List<Message>> fetchMessages(String threadId) async => const [];

  @override
  Future<ConversationThread> fetchThreadById(String threadId) =>
      throw UnimplementedError();

  @override
  Future<ConversationThread?> fetchThreadForDog(String dogId) async => null;

  @override
  Future<ConversationThread> getOrCreateInquiryThreadForDog(String dogId) =>
      throw UnimplementedError();

  @override
  Future<ConversationThread> getOrCreateThreadForDog(String dogId) =>
      throw UnimplementedError();

  @override
  Future<void> sendMessage(String threadId, String body) async {}
}

class _FakeApplicationsRepository implements ApplicationsRepository {
  _FakeApplicationsRepository(this.applications);

  final List<AdoptionApplication> applications;

  @override
  Future<List<AdoptionApplication>> fetchMyApplications() async => applications;

  @override
  Future<AdoptionApplication?> fetchMyApplicationForDog(String dogId) async =>
      null;

  @override
  Future<AdoptionApplication> createApplication(
    Dog dog,
    ApplicationFormData formData,
  ) => throw UnimplementedError();
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  final AppUser? user;

  @override
  AppUser? get currentUser => user;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(user);

  @override
  Stream<AuthLifecycleEvent> get authEvents => const Stream.empty();

  @override
  bool get hasAppleIdentity => false;

  @override
  Future<AppUser> signInWithApple() => throw UnimplementedError();

  @override
  Future<String> reauthenticateWithApple() => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> resendConfirmationEmail({required String email}) async {}

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<RegistrationResult> signUpWithEmailAndPassword({
    required String fullName,
    required String? phone,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}
