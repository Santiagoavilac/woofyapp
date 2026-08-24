import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/app/app.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/app/router.dart';
import 'package:mi_app/features/auth/data/auth_models.dart';
import 'package:mi_app/features/auth/data/profile_repository.dart';
import 'package:mi_app/features/auth/providers/auth_providers.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';
import 'package:mi_app/features/publisher/data/publisher_models.dart';
import 'package:mi_app/features/publisher/data/publisher_providers.dart';
import 'package:mi_app/features/publisher/data/publisher_repository.dart';

import 'support/fake_auth_repository.dart';

const _session = ShelterPortalSession(
  sessionId: 'session-1',
  token: 'token-abc',
  expiresAt: '2099-01-01T00:00:00Z',
  shelterId: 'shelter-1',
  shelterName: 'Refugio Woofy',
);

void main() {
  testWidgets('publisher page shows shelter name when session is active', (
    tester,
  ) async {
    final container = await _pumpPublisher(tester, session: _session);
    await tester.pumpAndSettle();

    expect(find.text('Refugio Woofy'), findsOneWidget);
    expect(find.text('Nuevo perro'), findsOneWidget);
    container.dispose();
  });

  testWidgets('publisher page shows login prompt when no session is active', (
    tester,
  ) async {
    final container = await _pumpPublisher(tester, session: null);
    await tester.pumpAndSettle();

    expect(find.text('Panel de refugio'), findsOneWidget);
    expect(find.text('Ingresar refugio'), findsOneWidget);
    expect(find.text('Nuevo perro'), findsNothing);
    container.dispose();
  });

  testWidgets('publisher page shows dog list with status labels', (
    tester,
  ) async {
    final dogs = [
      _sampleDog(id: 'dog-1', name: 'Max', status: 'published'),
      _sampleDog(id: 'dog-2', name: 'Luna', status: 'draft'),
    ];
    final container = await _pumpPublisher(
      tester,
      session: _session,
      dogs: dogs,
    );
    await tester.pumpAndSettle();

    expect(find.text('Max'), findsOneWidget);
    expect(find.text('Publicado'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
    expect(find.text('Borrador'), findsOneWidget);
    container.dispose();
  });

  testWidgets('"Nuevo perro" navigates to create form', (tester) async {
    final container = await _pumpPublisher(tester, session: _session);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo perro'));
    await tester.pumpAndSettle();

    expect(find.text('Crear perro'), findsOneWidget);
    container.dispose();
  });

  testWidgets('tapping a dog in the list navigates to edit form', (
    tester,
  ) async {
    final dogs = [_sampleDog(id: 'dog-1', name: 'Max', status: 'draft')];
    final container = await _pumpPublisher(
      tester,
      session: _session,
      dogs: dogs,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Max'));
    await tester.pumpAndSettle();

    expect(find.text('Guardar cambios'), findsOneWidget);
    container.dispose();
  });

  testWidgets('"Ingresar refugio" in login prompt goes to shelter login', (
    tester,
  ) async {
    final container = await _pumpPublisher(tester, session: null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ingresar refugio'));
    await tester.pumpAndSettle();

    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RoutePaths.shelterLogin,
    );
    container.dispose();
  });
}

Dog _sampleDog({
  required String id,
  required String name,
  required String status,
}) => Dog(
  id: id,
  shelterId: 'shelter-1',
  name: name,
  slug: name.toLowerCase(),
  story: 'Historia de $name.',
  status: status,
);

Future<ProviderContainer> _pumpPublisher(
  WidgetTester tester, {
  required ShelterPortalSession? session,
  List<Dog> dogs = const [],
}) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      shelterPortalSessionProvider.overrideWith(
        () => _FakePortalNotifier(session: session),
      ),
      shelterPortalRepositoryProvider.overrideWithValue(
        _FakeShelterPortalRepository(dogs: dogs),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WoofyApp()),
  );
  container.read(routerProvider).go(RoutePaths.publisher);
  await tester.pump();
  await tester.pump();
  return container;
}

class _FakePortalNotifier extends ShelterPortalNotifier {
  _FakePortalNotifier({required this.session});

  final ShelterPortalSession? session;

  @override
  Future<ShelterPortalSession?> build() async => session;
}

class _FakeShelterPortalRepository implements ShelterPortalRepository {
  _FakeShelterPortalRepository({this.dogs = const []});

  final List<Dog> dogs;

  List<DogDetail> _dogsAsDetails() => dogs
      .map(
        (dog) => DogDetail.fromJson(
          dog: dog,
          detailsJson: null,
          medicalEventsJson: const [],
        ),
      )
      .toList();

  @override
  Future<ShelterPortalSession> login(String loginCode, String password) =>
      throw UnimplementedError();

  @override
  Future<void> logout(ShelterPortalSession session) async {}

  @override
  Future<ShelterPortalSession> refreshSession(ShelterPortalSession session) =>
      Future.value(session);

  @override
  Future<List<DogDetail>> fetchDogs(ShelterPortalSession session) async =>
      _dogsAsDetails();

  @override
  Future<String> saveDog(
    ShelterPortalSession session,
    DogFormData formData, {
    String? dogId,
  }) async => dogId ?? 'dog-created';

  @override
  Future<void> updateDogStatus(
    ShelterPortalSession session,
    String dogId,
    String status,
  ) async {}

  @override
  Future<String> uploadDogPhoto(
    ShelterPortalSession session,
    String dogId,
    String filePath,
    String mimeType,
  ) async => 'fake/path.jpg';

  @override
  Future<ShelterPortalSession> updateShelter(
    ShelterPortalSession session,
    ShelterProfileFormData data,
  ) async => session;

  @override
  Future<String> uploadShelterProfileImage(
    ShelterPortalSession session,
    String filePath,
    String mimeType,
  ) async => 'shelters/${session.shelterId}/profile/x.jpg';

  @override
  Future<ShelterPortalSession> updateShelterProfileImage(
    ShelterPortalSession session,
    String storagePath,
  ) async => session.copyWith(profileImagePath: storagePath);
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
