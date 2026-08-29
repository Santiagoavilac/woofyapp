import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/app.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/app/router.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';
import 'package:woofy/shared/widgets/woofy_filter_chips.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_partner_repository.dart';

const _paseo = PartnerService(
  id: 's1',
  partnerId: 'p-1',
  name: 'Paseo de una hora',
  priceCents: 3500,
  durationMinutes: 60,
  kinds: [PartnerCategory.walking],
  partnerName: 'Guau Paseos',
  partnerSlug: 'guau-paseos',
  partnerCity: 'Santa Cruz',
);

const _bano = PartnerService(
  id: 's2',
  partnerId: 'p-2',
  name: 'Baño y corte',
  description: 'Incluye secado y perfume.',
  priceCents: 7000,
  kinds: [PartnerCategory.grooming, PartnerCategory.homeCare],
  partnerName: 'Peluquería Lulu',
  partnerSlug: 'peluqueria-lulu',
  partnerCity: 'La Paz',
);

const _guauPaseos = Partner(
  id: 'p-1',
  name: 'Guau Paseos',
  slug: 'guau-paseos',
  city: 'Santa Cruz',
  description: 'Paseamos por el parque urbano.',
  categories: [PartnerCategory.walking],
);

void main() {
  testWidgets('the services page lists services, not businesses', (
    tester,
  ) async {
    final container = await _pumpServices(
      tester,
      FakePartnerRepository(services: const [_paseo, _bano]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paseo de una hora'), findsOneWidget);
    expect(find.text('Baño y corte'), findsOneWidget);
    // El negocio aparece como pie de la tarjeta, no como el título.
    expect(find.text('Guau Paseos · Santa Cruz'), findsOneWidget);
    expect(find.textContaining('60 min'), findsOneWidget);
    expect(find.textContaining('35,00'), findsOneWidget);
    container.dispose();
  });

  testWidgets('the kind chips only offer rubros that exist in the list', (
    tester,
  ) async {
    final container = await _pumpServices(
      tester,
      FakePartnerRepository(services: const [_paseo, _bano]),
    );
    await tester.pumpAndSettle();

    final chips = find.byType(WoofyFilterChips);
    expect(find.descendant(of: chips, matching: find.text('Paseos')), findsOne);
    expect(
      find.descendant(of: chips, matching: find.text('Peluquería')),
      findsOne,
    );
    // Nadie ofrece adiestramiento: el rubro no se ofrece como filtro vacío.
    expect(
      find.descendant(of: chips, matching: find.text('Adiestramiento')),
      findsNothing,
    );
    container.dispose();
  });

  testWidgets('filtering by kind narrows the list and can be cleared', (
    tester,
  ) async {
    final container = await _pumpServices(
      tester,
      FakePartnerRepository(services: const [_paseo, _bano]),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(WoofyFilterChips),
        matching: find.text('Peluquería'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paseo de una hora'), findsNothing);
    expect(find.text('Baño y corte'), findsOneWidget);

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    expect(find.text('Paseo de una hora'), findsOneWidget);
    container.dispose();
  });

  testWidgets('a service matches by its business name too', (tester) async {
    final container = await _pumpServices(
      tester,
      FakePartnerRepository(services: const [_paseo, _bano]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'lulu');
    await tester.pumpAndSettle();

    expect(find.text('Paseo de una hora'), findsNothing);
    expect(find.text('Baño y corte'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('Sin resultados'), findsOneWidget);
    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('Paseo de una hora'), findsOneWidget);
    container.dispose();
  });

  testWidgets('the business line opens its profile, the card books', (
    tester,
  ) async {
    final container = await _pumpServices(
      tester,
      FakePartnerRepository(
        services: const [_paseo],
        detail: const PartnerDetail(partner: _guauPaseos, services: [_paseo]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('service-card-s1-partner')));
    await tester.pumpAndSettle();

    expect(_currentPath(container), RoutePaths.partnerDetail('guau-paseos'));
    expect(find.text('Paseamos por el parque urbano.'), findsOneWidget);
    container.dispose();
  });

  testWidgets('an empty catalog says so instead of showing a bare list', (
    tester,
  ) async {
    final container = await _pumpServices(tester, FakePartnerRepository());
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay servicios'), findsOneWidget);
    container.dispose();
  });

  testWidgets('the raw error never reaches the screen', (tester) async {
    final container = await _pumpServices(
      tester,
      FakePartnerRepository(error: StateError('network detail')),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar los servicios.'), findsOneWidget);
    expect(find.textContaining('network detail'), findsNothing);
    container.dispose();
  });

  testWidgets('the home button reaches services without a tab', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _pumpRoute(
      tester,
      FakePartnerRepository(services: const [_paseo]),
      RoutePaths.landing,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('landing-services-button')));
    await tester.pumpAndSettle();

    expect(_currentPath(container), RoutePaths.services);
    expect(find.text('Paseo de una hora'), findsOneWidget);
    container.dispose();
  });

  for (final size in <Size>[const Size(320, 568), const Size(412, 915)]) {
    testWidgets('services list has no overflow at ${size.width}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = await _pumpServices(
        tester,
        FakePartnerRepository(services: const [_paseo, _bano]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Paseo de una hora'), findsOneWidget);
      container.dispose();
    });
  }
}

/// Ubicación actual del router: con `push` hay que leer el último match.
String _currentPath(ProviderContainer container) {
  final matches = container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration;
  final last = matches.last;
  return last is ImperativeRouteMatch
      ? last.matches.uri.path
      : matches.uri.path;
}

Future<ProviderContainer> _pumpServices(
  WidgetTester tester,
  PartnerRepository repository,
) => _pumpRoute(tester, repository, RoutePaths.services);

Future<ProviderContainer> _pumpRoute(
  WidgetTester tester,
  PartnerRepository repository,
  String route,
) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  final container = ProviderContainer(
    overrides: [
      partnerRepositoryProvider.overrideWithValue(repository),
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
