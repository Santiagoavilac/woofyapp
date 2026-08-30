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
import 'package:woofy/shared/widgets/woofy_search_field.dart';

import 'support/fake_auth_repository.dart';

/// Lo que tiene que sostener la pantalla de Explorar rediseñada: que se pueda
/// elegir el tipo de animal de un toque, que los números que muestra sean los
/// que después se ven, y que ningún animal aparezca dos veces.
void main() {
  testWidgets('los mosaicos cuentan lo que hay de cada especie', (
    tester,
  ) async {
    final container = await _pumpDogs(tester, _catalog());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('species-tile-todos')), findsOneWidget);
    expect(find.byKey(const ValueKey('species-tile-perro')), findsOneWidget);
    expect(find.byKey(const ValueKey('species-tile-gato')), findsOneWidget);
    // Nadie publicó un "otro" y el mosaico está igual, en cero: es la fila que
    // cuenta de qué se trata Woofy, no un filtro que aparece y desaparece.
    expect(find.byKey(const ValueKey('species-tile-otro')), findsOneWidget);
    container.dispose();
  });

  testWidgets('con puros perros las tres especies siguen estando', (
    tester,
  ) async {
    // Mostrar solo lo que hay hoy haría creer que Woofy es una app de perros.
    final container = await _pumpDogs(tester, [_dog('Milo', 'milo-demo')]);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('species-tile-todos')), findsOneWidget);
    expect(find.byKey(const ValueKey('species-tile-gato')), findsOneWidget);
    expect(find.text('Milo'), findsOneWidget);
    container.dispose();
  });

  testWidgets('una especie vacía lleva a un vacío que se explica', (
    tester,
  ) async {
    final container = await _pumpDogs(tester, [_dog('Milo', 'milo-demo')]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('species-tile-gato')));
    await tester.pumpAndSettle();

    expect(find.text('Milo'), findsNothing);
    expect(find.text('Sin resultados'), findsOneWidget);
    container.dispose();
  });

  testWidgets('tocar un mosaico deja solo esa especie', (tester) async {
    final container = await _pumpDogs(tester, _catalog());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('species-tile-gato')));
    await tester.pumpAndSettle();
    await _scrollToResults(tester);

    expect(find.text('Nala'), findsOneWidget);
    expect(find.text('Milo'), findsNothing);
    // Con la especie ya elegida, repetir el título "Gatos" no agrega nada; lo
    // que sirve es cuántos quedaron.
    expect(find.text('1 animal disponible'), findsOneWidget);
    container.dispose();
  });

  testWidgets('sin especie elegida los resultados van agrupados', (
    tester,
  ) async {
    final container = await _pumpDogs(tester, _catalog());
    await tester.pumpAndSettle();

    expect(find.text('Perros'), findsOneWidget);
    expect(find.text('Gatos'), findsOneWidget);

    await _scrollToResults(tester);
    // Cada animal cae en una sección y en una sola: las secciones parten la
    // lista, no la duplican.
    expect(find.text('Milo'), findsOneWidget);
    expect(find.text('Nala'), findsOneWidget);
    container.dispose();
  });

  testWidgets('las píldoras de edad filtran por etapa', (tester) async {
    final container = await _pumpDogs(tester, _catalog());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('age-pill-cachorro')));
    await tester.pumpAndSettle();
    await _scrollToResults(tester);

    expect(find.text('Nala'), findsOneWidget);
    expect(find.text('Milo'), findsNothing);
    container.dispose();
  });

  testWidgets('la búsqueda entiende el diminutivo y el plural', (tester) async {
    final container = await _pumpDogs(tester, _catalog());
    await tester.pumpAndSettle();

    // "gatitos" no está escrito en ninguna parte de la base: la especie se
    // guarda como "gato" y el animal se llama Nala.
    await tester.enterText(find.byType(WoofySearchField), 'gatitos');
    await tester.pumpAndSettle();
    await _scrollToResults(tester);

    expect(find.text('Nala'), findsOneWidget);
    expect(find.text('Milo'), findsNothing);
    container.dispose();
  });

  testWidgets('la búsqueda perdona dos letras cambiadas de lugar', (
    tester,
  ) async {
    final container = await _pumpDogs(tester, _catalog());
    await tester.pumpAndSettle();

    // Invertir dos letras vecinas es el error de tipeo más común que hay.
    await tester.enterText(find.byType(WoofySearchField), 'Mlio');
    await tester.pumpAndSettle();
    await _scrollToResults(tester);

    expect(find.text('Milo'), findsOneWidget);
    expect(find.text('Nala'), findsNothing);
    container.dispose();
  });

  testWidgets('explorar no desborda a 320x568 con varias especies', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _pumpDogs(tester, _catalog());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('species-tile-todos')), findsOneWidget);
    container.dispose();
  });
}

List<Dog> _catalog() => [
  _dog('Milo', 'milo-demo'),
  _dog(
    'Nala',
    'nala-demo',
    species: AnimalSpecies.gato,
    ageMonths: 5,
    sex: 'hembra',
  ),
];

Dog _dog(
  String name,
  String slug, {
  AnimalSpecies species = AnimalSpecies.perro,
  int ageMonths = 18,
  String sex = 'macho',
}) => Dog(
  id: slug,
  shelterId: 'shelter-1',
  name: name,
  slug: slug,
  story: 'Una historia real.',
  status: 'published',
  species: species,
  sex: sex,
  ageMonths: ageMonths,
  size: 'mediano',
  shelter: const DogShelter(
    id: 'shelter-1',
    name: 'Woofy',
    city: 'Santa Cruz',
    status: 'active',
  ),
);

class _FakeDogRepository implements DogRepository {
  _FakeDogRepository(this.dogs);

  final List<Dog> dogs;

  @override
  Future<List<Dog>> fetchPublishedDogs() => Future.value(dogs);

  @override
  Future<DogDetail?> fetchPublishedDogBySlug(String slug) => Future.value(null);
}

/// Baja hasta los resultados.
///
/// Los mosaicos, las píldoras y el banner se llevan la primera pantalla, y un
/// `find` no ve los slivers que quedaron fuera del viewport. Sin este scroll el
/// test diría "no hay ningún animal" cuando en realidad están un poco más
/// abajo.
Future<void> _scrollToResults(WidgetTester tester) async {
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
  await tester.pumpAndSettle();
}

Future<ProviderContainer> _pumpDogs(WidgetTester tester, List<Dog> dogs) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  final container = ProviderContainer(
    overrides: [
      dogRepositoryProvider.overrideWithValue(_FakeDogRepository(dogs)),
      authRepositoryProvider.overrideWithValue(auth),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WoofyApp()),
  );
  container.read(routerProvider).go(RoutePaths.dogs);
  await tester.pump();
  await tester.pump();
  return container;
}
