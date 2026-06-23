import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/app/app.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/app/router.dart';
import 'package:mi_app/features/applications/data/application_models.dart';
import 'package:mi_app/features/applications/data/applications_providers.dart';
import 'package:mi_app/features/applications/data/applications_repository.dart';
import 'package:mi_app/features/auth/data/auth_models.dart';
import 'package:mi_app/features/auth/data/profile_repository.dart';
import 'package:mi_app/features/auth/providers/auth_providers.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';
import 'package:mi_app/features/dogs/data/dog_repository.dart';
import 'package:mi_app/features/dogs/data/dog_repository_provider.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('router exposes public routes and protects profile', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final container = _container(auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Encontrá a tu próximo mejor amigo'), findsOneWidget);
    final router = container.read(routerProvider);

    router.go(RoutePaths.dogs);
    await tester.pumpAndSettle();
    expect(
      find.text('No encontramos perritos publicados todavía.'),
      findsOneWidget,
    );

    router.go(RoutePaths.dogDetail('luna'));
    await tester.pumpAndSettle();
    expect(find.text('Este perrito no está disponible.'), findsOneWidget);

    router.go(RoutePaths.profile);
    await tester.pumpAndSettle();
    expect(find.text('Ingresar a Woofy'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.auth);

    router.go(RoutePaths.favorites);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.auth);

    router.go(RoutePaths.applicationForm('milo-demo'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.auth);
  });

  testWidgets('authenticated users are redirected from auth to profile', (
    tester,
  ) async {
    const user = AppUser(id: 'user-1', email: 'ana@example.com');
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final container = _container(auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );

    final router = container.read(routerProvider);
    router.go(RoutePaths.auth);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, RoutePaths.profile);
    expect(find.text('Tu perfil todavía no está completo.'), findsOneWidget);

    await _androidBack(tester);

    expect(router.routeInformationProvider.value.uri.path, RoutePaths.dogs);
    expect(
      find.text('No encontramos perritos publicados todavía.'),
      findsOneWidget,
    );
  });

  testWidgets('auth stream refreshes the same router without redirect loops', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final container = _container(auth);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    final router = container.read(routerProvider);
    router.go(RoutePaths.auth);
    await tester.pumpAndSettle();

    auth.setUser(const AppUser(id: 'user-1', email: 'ana@example.com'));
    await tester.pumpAndSettle();

    expect(identical(router, container.read(routerProvider)), isTrue);
    expect(router.routeInformationProvider.value.uri.path, RoutePaths.profile);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auth stream ensures an authenticated profile only once', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final profiles = _EmptyProfileRepository();
    final container = _container(auth, profiles: profiles);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    await tester.pumpAndSettle();
    const user = AppUser(
      id: 'user-1',
      email: 'ana@example.com',
      fullName: 'Ana Pérez',
    );

    auth.setUser(user);
    await tester.pumpAndSettle();
    auth.setUser(user);
    await tester.pumpAndSettle();

    expect(profiles.ensureCalls, 1);
  });

  testWidgets('application form Android back returns to dog detail', (
    tester,
  ) async {
    const user = AppUser(id: 'user-1', email: 'ana@example.com');
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final dog = _sampleDog();
    final container = _container(
      auth,
      dogRepository: _SingleDogRepository(dog),
      applications: _EmptyApplicationsRepository(),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WoofyApp()),
    );
    final router = container.read(routerProvider);

    router.go(RoutePaths.dogDetail(dog.slug));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Postular a Milo'));
    await tester.tap(find.widgetWithText(FilledButton, 'Postular a Milo'));
    await tester.pumpAndSettle();

    expect(find.text('Postular a Milo'), findsOneWidget);
    expect(
      find.text(
        'Contanos sobre tu hogar para que el refugio pueda evaluar la adopción.',
      ),
      findsOneWidget,
    );

    await _androidBack(tester);

    expect(
      router.routeInformationProvider.value.uri.path,
      RoutePaths.dogDetail(dog.slug),
    );
    expect(find.text('Una historia real.'), findsOneWidget);
  });
}

ProviderContainer _container(
  FakeAuthRepository auth, {
  _EmptyProfileRepository? profiles,
  DogRepository? dogRepository,
  ApplicationsRepository? applications,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(
        profiles ?? _EmptyProfileRepository(),
      ),
      dogRepositoryProvider.overrideWithValue(
        dogRepository ?? _EmptyDogRepository(),
      ),
      if (applications != null)
        applicationsRepositoryProvider.overrideWithValue(applications),
    ],
  );
}

class _EmptyDogRepository implements DogRepository {
  @override
  Future<List<Dog>> fetchPublishedDogs() async => const [];

  @override
  Future<DogDetail?> fetchPublishedDogBySlug(String slug) async => null;
}

class _EmptyProfileRepository implements ProfileRepository {
  int ensureCalls = 0;

  @override
  Future<UserProfile> ensureCurrentUserProfile(AppUser user) async {
    ensureCalls += 1;
    return UserProfile(id: user.id, role: 'adopter', email: user.email);
  }

  @override
  Future<UserProfile?> fetchCurrentProfile(AppUser user) async => null;
}

Dog _sampleDog() => const Dog(
  id: 'dog-1',
  shelterId: 'shelter-1',
  name: 'Milo',
  slug: 'milo-demo',
  story: 'Una historia real.',
  status: 'published',
  sex: 'macho',
  ageMonths: 18,
  size: 'mediano',
  shelter: DogShelter(id: 'shelter-1', name: 'Woofy'),
);

class _SingleDogRepository implements DogRepository {
  const _SingleDogRepository(this.dog);

  final Dog dog;

  @override
  Future<List<Dog>> fetchPublishedDogs() async => [dog];

  @override
  Future<DogDetail?> fetchPublishedDogBySlug(String slug) async =>
      slug == dog.slug ? DogDetail(dog: dog) : null;
}

class _EmptyApplicationsRepository implements ApplicationsRepository {
  @override
  Future<AdoptionApplication?> fetchMyApplicationForDog(String dogId) async =>
      null;

  @override
  Future<AdoptionApplication> createApplication(
    Dog dog,
    ApplicationFormData formData,
  ) {
    throw UnimplementedError('No se usa en esta prueba.');
  }
}

Future<void> _androidBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}
