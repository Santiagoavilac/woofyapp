import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/app/app.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/app/router.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/data/profile_repository.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/data/dog_repository.dart';
import 'package:woofy/features/dogs/data/dog_repository_provider.dart';
import 'package:woofy/features/publisher/data/publisher_models.dart';
import 'package:woofy/features/publisher/data/publisher_providers.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('landing presents a compact mobile home for visitors', (
    tester,
  ) async {
    await _pumpApp(tester, dogs: _sampleDogs);

    expect(find.text('Hola 👋'), findsOneWidget);
    expect(find.text('Buscar animales, refugios o razas'), findsOneWidget);
    expect(
      find.text('Adoptá felicidad,\nuna patita a la vez.'),
      findsOneWidget,
    );
    expect(find.text('Ver animales'), findsOneWidget);
    expect(find.text('Conocé a estos peluditos'), findsOneWidget);
    expect(find.text('Ver todos'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('Mora'), findsOneWidget);
    expect(find.text('Ir al panel'), findsNothing);
    expect(find.text('Ingresar refugio'), findsNothing);
  });

  testWidgets('primary action and preview action open the expected routes', (
    tester,
  ) async {
    final container = await _pumpApp(tester, dogs: _sampleDogs);

    await tester.tap(find.text('Ver animales'));
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RoutePaths.dogs,
    );

    container.read(routerProvider).go(RoutePaths.landing);
    await tester.pumpAndSettle();
    final recentDog = find.byKey(const ValueKey('recent-dog-luna-tap'));
    await tester.ensureVisible(recentDog);
    await tester.pumpAndSettle();
    await tester.tap(recentDog);
    await tester.pumpAndSettle();
    expect(find.text('Este perrito no está disponible.'), findsOneWidget);
  });

  testWidgets('landing keeps refuge access secondary when session is active', (
    tester,
  ) async {
    final container = await _pumpApp(
      tester,
      dogs: _sampleDogs,
      shelterSession: _sampleShelterSession,
    );

    expect(find.text('Ver animales'), findsOneWidget);
    expect(find.text('Refugio'), findsOneWidget);
    expect(find.text('Refugio Woofy'), findsOneWidget);
    expect(find.text('Ir al panel'), findsOneWidget);

    await tester.tap(find.text('Ir al panel'));
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RoutePaths.publisher,
    );
  });

  testWidgets('landing offers account access from its compact header', (
    tester,
  ) async {
    final container = await _pumpApp(tester, dogs: _sampleDogs);

    await tester.tap(find.byTooltip('Mi cuenta'));
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RoutePaths.auth,
    );
  });

  testWidgets('recent dogs has a compact empty state', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Todavía no hay animales publicados.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recent-dogs-action-Ver animales')),
      findsOneWidget,
    );
  });

  testWidgets('recent dogs has a compact error state with retry', (
    tester,
  ) async {
    await _pumpApp(tester, dogsShouldError: true);

    expect(find.text('No pudimos cargar los recién llegados.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('recent dogs has a compact loading state', (tester) async {
    final completer = Completer<List<Dog>>();
    await _pumpApp(
      tester,
      repository: _PendingDogRepository(completer.future),
      settle: false,
    );

    expect(find.text('Conocé a estos peluditos'), findsOneWidget);
    expect(find.text('Todavía no hay animales publicados.'), findsNothing);
    expect(tester.takeException(), isNull);
    completer.complete(const []);
  });

  const phoneSizes = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(412, 915),
  ];

  for (final size in phoneSizes) {
    testWidgets('landing has no overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        dogs: _sampleDogs,
        shelterSession: _sampleShelterSession,
        viewSize: size,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Ver animales'), findsOneWidget);
      // Home is the selected tab, so only its pill renders a label; the other
      // two destinations are icon-only and are matched by key.
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-item-explorar')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-item-perfil')), findsOneWidget);
    });
  }
}

const _sampleShelterSession = ShelterPortalSession(
  sessionId: 'session-1',
  token: 'token-abc',
  expiresAt: '2099-01-01T00:00:00Z',
  shelterId: 'shelter-1',
  shelterName: 'Refugio Woofy',
);

const _sampleDogs = [
  Dog(
    id: 'dog-1',
    shelterId: 'shelter-1',
    name: 'Luna',
    slug: 'luna',
    story: 'Busca un hogar.',
    status: 'published',
    shelter: DogShelter(id: 'shelter-1', name: 'Patitas', city: 'La Paz'),
  ),
  Dog(
    id: 'dog-2',
    shelterId: 'shelter-1',
    name: 'Bruno',
    slug: 'bruno',
    story: 'Busca un hogar.',
    status: 'published',
    shelter: DogShelter(id: 'shelter-1', name: 'Patitas', city: 'La Paz'),
  ),
  Dog(
    id: 'dog-3',
    shelterId: 'shelter-1',
    name: 'Mora',
    slug: 'mora',
    story: 'Busca un hogar.',
    status: 'published',
    shelter: DogShelter(id: 'shelter-1', name: 'Patitas', city: 'La Paz'),
  ),
  Dog(
    id: 'dog-4',
    shelterId: 'shelter-1',
    name: 'Simón',
    slug: 'simon',
    story: 'Busca un hogar.',
    status: 'published',
  ),
];

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  List<Dog> dogs = const [],
  DogRepository? repository,
  ShelterPortalSession? shelterSession,
  bool dogsShouldError = false,
  bool settle = true,
  Size viewSize = const Size(420, 2000),
}) async {
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  final container = ProviderContainer(
    overrides: [
      dogRepositoryProvider.overrideWithValue(
        repository ?? _DogRepository(dogs),
      ),
      if (dogsShouldError)
        publishedDogsProvider.overrideWith(
          (ref) => Future<List<Dog>>.error(StateError('offline')),
        ),
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      if (shelterSession != null)
        shelterPortalSessionProvider.overrideWith(
          () => _FakePortalNotifier(session: shelterSession),
        ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WoofyApp()),
  );
  container.read(routerProvider).go(RoutePaths.landing);
  if (settle) await tester.pumpAndSettle();
  return container;
}

class _FakePortalNotifier extends ShelterPortalNotifier {
  _FakePortalNotifier({required this.session});

  final ShelterPortalSession? session;

  @override
  Future<ShelterPortalSession?> build() async => session;
}

class _DogRepository implements DogRepository {
  const _DogRepository(this.dogs);

  final List<Dog> dogs;

  @override
  Future<List<Dog>> fetchPublishedDogs() async => dogs;

  @override
  Future<DogDetail?> fetchPublishedDogBySlug(String slug) async => null;
}

class _PendingDogRepository implements DogRepository {
  const _PendingDogRepository(this.future);

  final Future<List<Dog>> future;

  @override
  Future<List<Dog>> fetchPublishedDogs() => future;

  @override
  Future<DogDetail?> fetchPublishedDogBySlug(String slug) async => null;
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile?> fetchCurrentProfile(AppUser user) async => null;

  @override
  Future<UserProfile> ensureCurrentUserProfile(AppUser user) async =>
      UserProfile(id: user.id, role: 'adopter', email: user.email);

  @override
  Future<String?> fetchEmailByFullName(String name) async => null;

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async => UserProfile(id: userId, role: 'adopter');
}
