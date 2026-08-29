import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/app.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/app/router.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/vets/data/cart_provider.dart';
import 'package:woofy/features/vets/data/vet_models.dart';
import 'package:woofy/features/vets/data/vet_repository.dart';
import 'package:woofy/features/vets/data/vet_repository_provider.dart';
import 'package:woofy/shared/widgets/woofy_bottom_navigation.dart';
import 'package:woofy/shared/widgets/woofy_filter_chips.dart';

import 'support/fake_auth_repository.dart';

const _santaCruz = Vet(
  id: 'vet-1',
  name: 'Vet Santa Cruz',
  slug: 'vet-santa-cruz',
  city: 'Santa Cruz',
  description: 'Consultas y peluquería canina.',
  whatsappPhone: '70123456',
  verified: true,
);

const _laPaz = Vet(
  id: 'vet-2',
  name: 'Clínica La Paz',
  slug: 'clinica-la-paz',
  city: 'La Paz',
);

const _alimento = VetProduct(
  id: 'p1',
  vetId: 'vet-1',
  name: 'Alimento Premium',
  priceCents: 15000,
);

const _collar = VetProduct(
  id: 'p2',
  vetId: 'vet-1',
  name: 'Collar reflectivo',
  description: 'Se ve de noche a cien metros.',
  priceCents: 4550,
);

const _bano = VetService(
  id: 's1',
  vetId: 'vet-1',
  name: 'Baño para perro',
  priceCents: 7000,
);

/// Pantalla alta para que las listas perezosas construyan todo lo que el test
/// va a tocar. Sin esto los slivers dejan las tarjetas de más abajo sin montar
/// y `find` no las ve.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('vets page shows loading, then the empty state', (tester) async {
    final completer = Completer<List<Vet>>();
    final loading = await _pumpVets(
      tester,
      FakeVetRepository(vetsFuture: completer.future),
    );

    expect(find.text('Cargando veterinarias…'), findsOneWidget);
    loading.dispose();

    await tester.pumpWidget(const SizedBox.shrink());
    final empty = await _pumpVets(tester, FakeVetRepository());
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay veterinarias'), findsOneWidget);
    empty.dispose();
  });

  testWidgets('vets page hides the raw error behind a safe message', (
    tester,
  ) async {
    final container = await _pumpVets(
      tester,
      FakeVetRepository(error: StateError('network detail')),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar las veterinarias.'), findsOneWidget);
    expect(find.textContaining('network detail'), findsNothing);
    container.dispose();
  });

  testWidgets('the city filter narrows the list and can be cleared', (
    tester,
  ) async {
    _useTallScreen(tester);
    final container = await _pumpVets(
      tester,
      FakeVetRepository(vets: const [_santaCruz, _laPaz]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vet Santa Cruz'), findsOneWidget);
    expect(find.text('Clínica La Paz'), findsOneWidget);

    // El nombre de la ciudad también aparece en la tarjeta, así que el tap se
    // acota a la fila de chips: tocar la tarjeta abriría el perfil.
    await tester.tap(
      find.descendant(
        of: find.byType(WoofyFilterChips),
        matching: find.text('La Paz'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vet Santa Cruz'), findsNothing);
    expect(find.text('Clínica La Paz'), findsOneWidget);

    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();

    expect(find.text('Vet Santa Cruz'), findsOneWidget);
    container.dispose();
  });

  testWidgets('searching by name leaves a way out of the empty result', (
    tester,
  ) async {
    final container = await _pumpVets(
      tester,
      FakeVetRepository(vets: const [_santaCruz, _laPaz]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('Sin resultados'), findsOneWidget);

    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('Vet Santa Cruz'), findsOneWidget);
    container.dispose();
  });

  testWidgets('tapping a card opens the vet profile with its catalog', (
    tester,
  ) async {
    _useTallScreen(tester);
    final container = await _pumpVets(
      tester,
      FakeVetRepository(
        vets: const [_santaCruz],
        detail: const VetDetail(
          vet: _santaCruz,
          products: [_alimento],
          services: [_bano],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('vet-card-vet-santa-cruz-tap')));
    await tester.pumpAndSettle();

    expect(find.text('Consultas y peluquería canina.'), findsOneWidget);
    expect(find.text('Alimento Premium'), findsOneWidget);
    expect(find.text('Baño para perro'), findsOneWidget);
    // Los precios se pintan en centavos formateados, nunca en flotante.
    expect(find.textContaining('150,00'), findsWidgets);
    container.dispose();
  });

  testWidgets('a missing vet shows the unavailable state', (tester) async {
    final container = await _pumpRoute(
      tester,
      FakeVetRepository(detail: null),
      RoutePaths.vetDetail('no-existe'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Veterinaria no disponible'), findsOneWidget);
    container.dispose();
  });

  testWidgets('adding a product fills the cart and the badge counts it', (
    tester,
  ) async {
    _useTallScreen(tester);
    final container = await _pumpRoute(
      tester,
      FakeVetRepository(
        vets: const [_santaCruz],
        detail: const VetDetail(vet: _santaCruz, products: [_alimento]),
      ),
      RoutePaths.vetDetail('vet-santa-cruz'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('vet-product-add-p1')));
    await tester.pumpAndSettle();

    final group = container.read(cartProvider)['vet-1']!;
    expect(group.lines.single.productId, 'p1');
    expect(group.totalCents, 15000);
    expect(container.read(cartItemCountProvider), 1);
    container.dispose();
  });

  testWidgets('tapping a product opens its page with the rest below', (
    tester,
  ) async {
    _useTallScreen(tester);
    final container = await _pumpRoute(
      tester,
      FakeVetRepository(
        vets: const [_santaCruz],
        detail: const VetDetail(
          vet: _santaCruz,
          products: [_collar, _alimento],
        ),
      ),
      RoutePaths.vetDetail('vet-santa-cruz'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('vet-product-p2-tap')));
    await tester.pumpAndSettle();

    expect(
      _currentPath(container),
      RoutePaths.vetProduct('vet-santa-cruz', 'p2'),
    );
    expect(find.text('Se ve de noche a cien metros.'), findsOneWidget);
    expect(find.text('Otras personas también compraron'), findsOneWidget);
    // El producto abierto no puede recomendarse a sí mismo.
    expect(find.byKey(const ValueKey('vet-related-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('vet-related-p2')), findsNothing);
    container.dispose();
  });

  testWidgets('the add bar carries the chosen quantity into the cart', (
    tester,
  ) async {
    _useTallScreen(tester);
    // Sin sesión a propósito: armar el carrito no pide cuenta, el login se
    // pide recién al mandar el pedido.
    final container = await _pumpRoute(
      tester,
      FakeVetRepository(
        vets: const [_santaCruz],
        detail: const VetDetail(vet: _santaCruz, products: [_alimento]),
      ),
      RoutePaths.vetProduct('vet-santa-cruz', 'p1'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-bar-increment')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('add-bar-total'))).data,
      contains('300,00'),
    );

    await tester.tap(find.byKey(const ValueKey('add-bar-submit')));
    await tester.pumpAndSettle();

    expect(container.read(cartProvider)['vet-1']!.lines.single.quantity, 2);
    expect(
      _currentPath(container),
      RoutePaths.vetCart,
    );
    container.dispose();
  });

  testWidgets('the cart groups two vets and totals each one on its own', (
    tester,
  ) async {
    final container = await _pumpRoute(
      tester,
      FakeVetRepository(vets: const [_santaCruz, _laPaz]),
      RoutePaths.vets,
      user: const AppUser(id: 'user-1', email: 'user@example.com'),
    );
    final cart = container.read(cartProvider.notifier)
      ..add(_santaCruz, _alimento, quantity: 2)
      ..add(
        _laPaz,
        const VetProduct(
          id: 'p9',
          vetId: 'vet-2',
          name: 'Juguete',
          priceCents: 3000,
        ),
      );
    expect(cart.totalItemCount, 3);

    container.read(routerProvider).go(RoutePaths.vetCart);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cart-group-vet-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('cart-group-vet-2')), findsOneWidget);

    final total = tester.widget<Text>(
      find.byKey(const ValueKey('cart-total-vet-1')),
    );
    expect(total.data, contains('300,00'));
    container.dispose();
  });

  testWidgets('an empty cart points back at the catalog', (tester) async {
    final container = await _pumpRoute(
      tester,
      FakeVetRepository(),
      RoutePaths.vetCart,
      user: const AppUser(id: 'user-1', email: 'user@example.com'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tu carrito está vacío'), findsOneWidget);
    container.dispose();
  });

  testWidgets('swiping the page sideways changes tab', (tester) async {
    final container = await _pumpRoute(
      tester,
      FakeVetRepository(),
      RoutePaths.landing,
    );
    await tester.pumpAndSettle();

    // El arrastre vive en el cuerpo del shell, así que se hace sobre la
    // página y no sobre la barra.
    await tester.fling(
      find.byType(StatefulNavigationShell),
      const Offset(-400, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RoutePaths.dogs,
    );
    container.dispose();
  });

  testWidgets('the bottom navigation reaches the vets tab', (tester) async {
    final container = await _pumpRoute(
      tester,
      FakeVetRepository(),
      RoutePaths.landing,
    );
    await tester.pumpAndSettle();

    final nav = find.byType(WoofyBottomNavigation);
    final vets = find.byKey(const ValueKey('nav-item-veterinarias'));
    expect(find.descendant(of: nav, matching: vets), findsOneWidget);

    await tester.tap(vets);
    await tester.pumpAndSettle();

    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RoutePaths.vets,
    );
    container.dispose();
  });

  testWidgets('Android back from the vets tab returns to landing', (
    tester,
  ) async {
    final container = await _pumpVets(tester, FakeVetRepository());
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RoutePaths.landing,
    );
    container.dispose();
  });

  testWidgets('the reservation form only enables submit with a date', (
    tester,
  ) async {
    _useTallScreen(tester);
    final container = await _pumpRoute(
      tester,
      FakeVetRepository(
        detail: const VetDetail(vet: _santaCruz, services: [_bano]),
      ),
      RoutePaths.vetReservation('vet-santa-cruz'),
      user: const AppUser(id: 'user-1', email: 'user@example.com'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Baño para perro'), findsOneWidget);
    expect(find.text('Elegí fecha y hora'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reservation-service-s1')));
    await tester.pumpAndSettle();

    // Sin fecha el botón queda apagado aunque haya servicio elegido: el RPC
    // rechaza turnos sin `scheduled_for`.
    final submit = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('reservation-submit')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(submit.onPressed, isNull);
    expect(find.textContaining('70,00'), findsWidgets);
    container.dispose();
  });

  for (final size in <Size>[const Size(320, 568), const Size(412, 915)]) {
    testWidgets('vets catalog has no overflow at ${size.width}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = await _pumpVets(
        tester,
        FakeVetRepository(vets: const [_santaCruz, _laPaz]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Vet Santa Cruz'), findsOneWidget);
      container.dispose();
    });
  }
}

class FakeVetRepository implements VetRepository {
  FakeVetRepository({
    this.vets = const [],
    this.detail,
    this.error,
    this.vetsFuture,
  });

  final List<Vet> vets;
  final VetDetail? detail;
  final Object? error;
  final Future<List<Vet>>? vetsFuture;

  final List<({String vetId, List<({String productId, int quantity})> items})>
  createdOrders = [];

  @override
  Future<List<Vet>> fetchActiveVets() {
    if (error != null) return Future.error(error!);
    return vetsFuture ?? Future.value(vets);
  }

  @override
  Future<VetDetail?> fetchVetBySlug(String slug) {
    if (error != null) return Future.error(error!);
    return Future.value(detail);
  }

  @override
  Future<VetOrder> createOrder({
    required String vetId,
    required List<({String productId, int quantity})> items,
    String? contactPhone,
    String? notes,
  }) async {
    createdOrders.add((vetId: vetId, items: items));
    return VetOrder(
      id: 'order-1',
      vetId: vetId,
      status: 'pending',
      totalCents: 0,
      items: const [],
    );
  }

  @override
  Future<VetReservation> createReservation({
    required String vetId,
    required String serviceId,
    required DateTime scheduledFor,
    String? petName,
    String? contactPhone,
    String? notes,
  }) async => VetReservation(
    id: 'reservation-1',
    vetId: vetId,
    status: 'pending',
    serviceNameSnapshot: 'Baño para perro',
    priceCentsSnapshot: 7000,
    scheduledFor: scheduledFor,
    petName: petName,
  );

  @override
  Future<List<VetOrder>> fetchMyOrders() async => const [];

  @override
  Future<List<VetReservation>> fetchMyReservations() async => const [];
}

/// Ubicación actual del router.
///
/// `currentConfiguration.uri` se queda con la ruta que se fue a buscar: `push`
/// agrega un match encima pero copia el `uri` original. Con navegación
/// imperativa hay que leer el último match para saber dónde estamos parados.
String _currentPath(ProviderContainer container) {
  final matches =
      container.read(routerProvider).routerDelegate.currentConfiguration;
  final last = matches.last;
  return last is ImperativeRouteMatch
      ? last.matches.uri.path
      : matches.uri.path;
}

Future<ProviderContainer> _pumpVets(
  WidgetTester tester,
  VetRepository repository,
) => _pumpRoute(tester, repository, RoutePaths.vets);

Future<ProviderContainer> _pumpRoute(
  WidgetTester tester,
  VetRepository repository,
  String route, {
  AppUser? user,
}) async {
  final auth = FakeAuthRepository(user: user);
  addTearDown(auth.dispose);
  final container = ProviderContainer(
    overrides: [
      vetRepositoryProvider.overrideWithValue(repository),
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
