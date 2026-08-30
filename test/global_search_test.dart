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
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';
import 'package:woofy/shared/widgets/woofy_search_field.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_partner_repository.dart';

/// El buscador general: lo que antes no hacía nada.
///
/// Lo que se prueba acá es que una sola búsqueda alcance las cuatro fuentes
/// —animales, tienda, veterinarias y servicios— y que perdone cómo se escribe.
void main() {
  testWidgets('el campo de Inicio abre el buscador general', (tester) async {
    final container = await _pumpLanding(tester);

    await tester.tap(find.byKey(const ValueKey('home-search-field')));
    await tester.pumpAndSettle();

    expect(_path(container), RoutePaths.search);
    expect(find.byKey(const ValueKey('global-search-field')), findsOneWidget);
    expect(find.text('Búsquedas frecuentes'), findsOneWidget);
  });

  testWidgets('encuentra una polera de la tienda', (tester) async {
    // El pedido original: "en ese se pueden ver poleras y otras cosas".
    final container = await _pumpSearch(tester);

    await tester.enterText(find.byType(WoofySearchField), 'polera');
    await tester.pumpAndSettle();

    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('Polera Woofy'), findsOneWidget);
    container.dispose();
  });

  testWidgets('una remera también encuentra la polera', (tester) async {
    // La palabra que la persona usa no tiene por qué ser la que guardó el
    // admin.
    final container = await _pumpSearch(tester);

    await tester.enterText(find.byType(WoofySearchField), 'remeras');
    await tester.pumpAndSettle();

    expect(find.text('Polera Woofy'), findsOneWidget);
    container.dispose();
  });

  testWidgets('una sola búsqueda alcanza las cuatro secciones', (tester) async {
    final container = await _pumpSearch(tester);

    // Todo lo cargado dice "Woofy" en alguna parte.
    await tester.enterText(find.byType(WoofySearchField), 'woofy');
    await tester.pumpAndSettle();

    expect(find.text('Animales'), findsOneWidget);
    expect(find.text('Productos'), findsOneWidget);
    // La lista es perezosa: las últimas secciones recién se construyen al
    // llegar a ellas.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Veterinarias'), findsOneWidget);
    expect(find.text('Servicios'), findsOneWidget);
    container.dispose();
  });

  testWidgets('buscar un gato no trae al perro', (tester) async {
    final container = await _pumpSearch(tester);

    await tester.enterText(find.byType(WoofySearchField), 'gatitos');
    await tester.pumpAndSettle();

    expect(find.text('Nala'), findsOneWidget);
    expect(find.text('Milo'), findsNothing);
    container.dispose();
  });

  testWidgets('una búsqueda sin resultados lo dice', (tester) async {
    final container = await _pumpSearch(tester);

    await tester.enterText(find.byType(WoofySearchField), 'elefante');
    await tester.pumpAndSettle();

    expect(find.text('Sin resultados'), findsOneWidget);
    container.dispose();
  });

  testWidgets('un atajo llena el campo y busca', (tester) async {
    final container = await _pumpSearch(tester);

    await tester.tap(find.byKey(const ValueKey('search-suggestion-Poleras')));
    await tester.pumpAndSettle();

    expect(find.text('Polera Woofy'), findsOneWidget);
    container.dispose();
  });

  testWidgets('tocar un resultado abre su ficha', (tester) async {
    final container = await _pumpSearch(tester);

    await tester.enterText(find.byType(WoofySearchField), 'Milo');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('search-hit-dog-1')));
    await tester.pumpAndSettle();

    expect(_path(container), RoutePaths.dogDetail('milo-demo'));
    container.dispose();
  });
}

const _dogs = [
  Dog(
    id: 'dog-1',
    shelterId: 'shelter-1',
    name: 'Milo',
    slug: 'milo-demo',
    story: 'Una historia real.',
    status: 'published',
    shelter: DogShelter(
      id: 'shelter-1',
      name: 'Refugio Woofy',
      city: 'Santa Cruz',
      status: 'active',
    ),
  ),
  Dog(
    id: 'dog-2',
    shelterId: 'shelter-1',
    name: 'Nala',
    slug: 'nala-demo',
    story: 'Busca un hogar.',
    status: 'published',
    species: AnimalSpecies.gato,
    shelter: DogShelter(
      id: 'shelter-1',
      name: 'Refugio Woofy',
      city: 'Santa Cruz',
      status: 'active',
    ),
  ),
];

const _store = PartnerDetail(
  partner: Partner(
    id: 'store',
    name: 'Tienda Woofy',
    slug: 'tienda-woofy',
    status: 'active',
    isWoofyStore: true,
  ),
  products: [
    PartnerProduct(
      id: 'prod-1',
      partnerId: 'store',
      name: 'Polera Woofy',
      priceCents: 15000,
    ),
  ],
);

const _partners = [
  Partner(
    id: 'vet-1',
    name: 'Veterinaria Woofy',
    slug: 'veterinaria-woofy',
    city: 'Santa Cruz',
    status: 'active',
    categories: [PartnerCategory.vet],
  ),
];

const _services = [
  PartnerService(
    id: 'srv-1',
    partnerId: 'vet-1',
    name: 'Baño y corte',
    priceCents: 8000,
    partnerName: 'Veterinaria Woofy',
    partnerSlug: 'veterinaria-woofy',
    partnerCity: 'Santa Cruz',
    kinds: [PartnerCategory.grooming],
  ),
];

class _FakeDogRepository implements DogRepository {
  @override
  Future<List<Dog>> fetchPublishedDogs() => Future.value(_dogs);

  @override
  Future<DogDetail?> fetchPublishedDogBySlug(String slug) =>
      Future.value(DogDetail(dog: _dogs.first));
}

/// La ruta que está arriba de todo.
///
/// Ni `routeInformationProvider` ni `currentConfiguration.uri` sirven acá: con
/// un `push` las dos se quedan mirando la ruta de abajo —la del shell— y el
/// test mediría siempre `/`. `state` sí devuelve la de arriba.
String _path(ProviderContainer container) =>
    container.read(routerProvider).state.uri.path;

Future<ProviderContainer> _pumpLanding(WidgetTester tester) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  final container = ProviderContainer(
    overrides: [
      dogRepositoryProvider.overrideWithValue(_FakeDogRepository()),
      partnerRepositoryProvider.overrideWithValue(
        FakePartnerRepository(
          partners: _partners,
          services: _services,
          detail: _store,
        ),
      ),
      authRepositoryProvider.overrideWithValue(auth),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WoofyApp()),
  );
  container.read(routerProvider).go(RoutePaths.landing);
  await tester.pumpAndSettle();
  return container;
}

Future<ProviderContainer> _pumpSearch(WidgetTester tester) async {
  final container = await _pumpLanding(tester);
  container.read(routerProvider).push(RoutePaths.search);
  await tester.pumpAndSettle();
  return container;
}
