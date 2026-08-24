import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/app/app.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/app/router.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/data/dog_repository.dart';
import 'package:woofy/features/dogs/data/dog_repository_provider.dart';
import 'package:woofy/features/dogs/presentation/dogs_page.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('dogs page shows loading and empty states', (tester) async {
    final completer = Completer<List<Dog>>();
    final loadingRepository = FakeDogRepository(dogsFuture: completer.future);
    final loading = await _pumpDogs(tester, loadingRepository);

    expect(find.text('Cargando animales…'), findsOneWidget);
    loading.dispose();

    await tester.pumpWidget(const SizedBox.shrink());
    final empty = await _pumpDogs(tester, FakeDogRepository(dogs: const []));
    await tester.pumpAndSettle();

    expect(
      find.text('No encontramos animales publicados todavía.'),
      findsOneWidget,
    );
    empty.dispose();
  });

  testWidgets('dogs page shows a safe error with retry', (tester) async {
    final container = await _pumpDogs(
      tester,
      FakeDogRepository(error: StateError('network detail')),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar los animales.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('network detail'), findsNothing);
    container.dispose();
  });

  testWidgets('Android back from dogs page returns to landing', (tester) async {
    final container = await _pumpDogs(
      tester,
      FakeDogRepository(dogs: const []),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RoutePaths.dogs,
    );

    await _androidBack(tester);

    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RoutePaths.landing,
    );
    expect(find.text('Hola 👋'), findsOneWidget);
    container.dispose();
  });

  testWidgets('dog without photos uses a placeholder and opens its slug', (
    tester,
  ) async {
    final dog = sampleDog();
    final repository = FakeDogRepository(
      dogs: [dog],
      detail: DogDetail(dog: dog),
    );
    final container = await _pumpDogs(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Milo'), findsOneWidget);
    expect(find.byKey(const ValueKey('dog-photo-placeholder')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dog-card-milo-demo-tap')));
    await tester.pumpAndSettle();

    expect(find.text('Una historia real.'), findsOneWidget);
    expect(find.text('Iniciar sesión para postular'), findsOneWidget);

    await _androidBack(tester);

    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RoutePaths.dogs,
    );
    expect(find.text('Encontrá a tu compañero ideal'), findsOneWidget);
    container.dispose();
  });

  testWidgets('missing dog detail shows unavailable state', (tester) async {
    final container = await _pumpRoute(
      tester,
      FakeDogRepository(detail: null),
      RoutePaths.dogDetail('missing'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Este perrito no está disponible.'), findsOneWidget);
    container.dispose();
  });

  testWidgets(
    'catalog uses the ivory system background, not a celeste override',
    (tester) async {
      final container = await _pumpDogs(
        tester,
        FakeDogRepository(dogs: [sampleDog()]),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(DogsPage),
          matching: find.byType(Scaffold),
        ),
      );
      // A null backgroundColor means the Scaffold inherits the theme's ivory
      // scaffoldBackgroundColor instead of forcing its own palette.
      expect(scaffold.backgroundColor, isNull);
      container.dispose();
    },
  );

  testWidgets('catalog opens the filter sheet', (tester) async {
    final container = await _pumpDogs(
      tester,
      FakeDogRepository(dogs: [sampleDog()]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('Tamaño'), findsOneWidget);
    expect(find.text('Sexo'), findsOneWidget);
    container.dispose();
  });

  testWidgets('bottom navigation exposes the three shell destinations', (
    tester,
  ) async {
    final container = await _pumpRoute(
      tester,
      FakeDogRepository(dogs: const []),
      RoutePaths.landing,
    );
    await tester.pumpAndSettle();

    final nav = find.byType(NavigationBar);
    expect(
      find.descendant(of: nav, matching: find.text('Inicio')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: nav, matching: find.text('Explorar')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: nav, matching: find.text('Perfil')),
      findsOneWidget,
    );

    await tester.tap(find.descendant(of: nav, matching: find.text('Explorar')));
    await tester.pumpAndSettle();

    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RoutePaths.dogs,
    );
    container.dispose();
  });

  for (final size in <Size>[
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(412, 915),
  ]) {
    testWidgets('catalog has no overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = await _pumpDogs(
        tester,
        FakeDogRepository(dogs: [sampleDog()]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Milo'), findsOneWidget);
      container.dispose();
    });
  }
}

Dog sampleDog() => const Dog(
  id: 'dog-1',
  shelterId: 'shelter-1',
  name: 'Milo',
  slug: 'milo-demo',
  story: 'Una historia real.',
  status: 'published',
  sex: 'macho',
  ageMonths: 18,
  size: 'mediano',
  shelter: DogShelter(
    id: 'shelter-1',
    name: 'Woofy',
    city: 'Santa Cruz',
    status: 'active',
  ),
);

class FakeDogRepository implements DogRepository {
  FakeDogRepository({
    this.dogs = const [],
    this.detail,
    this.error,
    this.dogsFuture,
  });

  final List<Dog> dogs;
  final DogDetail? detail;
  final Object? error;
  final Future<List<Dog>>? dogsFuture;

  @override
  Future<List<Dog>> fetchPublishedDogs() {
    if (error != null) return Future.error(error!);
    return dogsFuture ?? Future.value(dogs);
  }

  @override
  Future<DogDetail?> fetchPublishedDogBySlug(String slug) {
    if (error != null) return Future.error(error!);
    return Future.value(detail);
  }
}

Future<ProviderContainer> _pumpDogs(
  WidgetTester tester,
  DogRepository repository,
) => _pumpRoute(tester, repository, RoutePaths.dogs);

Future<ProviderContainer> _pumpRoute(
  WidgetTester tester,
  DogRepository repository,
  String route,
) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  final container = ProviderContainer(
    overrides: [
      dogRepositoryProvider.overrideWithValue(repository),
      authRepositoryProvider.overrideWithValue(auth),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WoofyApp()),
  );
  container.read(routerProvider).go(route);
  await tester.pump();
  await tester.pump();
  return container;
}

Future<void> _androidBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}
