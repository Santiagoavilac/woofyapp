import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:woofy/app/app.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/app/router.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/merch/presentation/merch_store_page.dart';
import 'package:woofy/features/partners/data/cart_provider.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/partner_repository_provider.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_partner_repository.dart';

const _store = Partner(
  id: 'store-1',
  name: 'Woofy Merch',
  slug: 'woofy-merch',
  whatsappPhone: '70123456',
  status: 'active',
  isWoofyStore: true,
  categories: [PartnerCategory.shop],
);

const _product = PartnerProduct(
  id: 'product-1',
  partnerId: 'store-1',
  name: 'Polera Woofy negra',
  description: 'Algodón suave.',
  priceCents: 12500,
  imagePaths: ['merch/front.webp', 'merch/back.webp'],
  variants: [
    PartnerProductVariant(
      id: 'size-s',
      productId: 'product-1',
      sizeLabel: 'S',
      stock: 0,
    ),
    PartnerProductVariant(
      id: 'size-m',
      productId: 'product-1',
      sizeLabel: 'M',
      stock: 2,
    ),
  ],
);

void main() {
  test('product parses gallery and size variants', () {
    final product = PartnerProduct.fromJson({
      'id': 'p1',
      'partner_id': 'store-1',
      'name': 'Polera azul',
      'price_cents': 9900,
      'image_paths': ['one.webp', 'two.webp'],
      'variants': [
        {
          'id': 'm',
          'product_id': 'p1',
          'size_label': 'M',
          'stock': 3,
          'is_active': true,
        },
      ],
    });

    expect(product.imagePaths, ['one.webp', 'two.webp']);
    expect(product.variants.single.sizeLabel, 'M');
    expect(product.variants.single.stock, 3);
  });

  testWidgets('store and product are public without an account', (
    tester,
  ) async {
    final repository = FakePartnerRepository(
      detail: const PartnerDetail(partner: _store, products: [_product]),
    );
    final container = await _pumpRoute(tester, repository, RoutePaths.store);

    expect(find.text('Vestite con propósito'), findsOneWidget);
    expect(find.text('Polera Woofy negra'), findsOneWidget);
    expect(container.read(currentUserProvider), isNull);

    await tester.tap(find.byKey(const ValueKey('merch-product-product-1')));
    await tester.pumpAndSettle();
    expect(_currentPath(container), RoutePaths.storeProduct('product-1'));
  });

  testWidgets('the cover photo carries a single hero tag into the detail', (
    tester,
  ) async {
    final repository = FakePartnerRepository(
      detail: const PartnerDetail(partner: _store, products: [_product]),
    );
    await _pumpRoute(tester, repository, RoutePaths.store);

    final tag = merchPhotoHeroTag('product-1');
    expect(_heroTags(tester), contains(tag));

    await tester.tap(find.byKey(const ValueKey('merch-product-product-1')));
    await tester.pumpAndSettle();

    // La galería tiene dos fotos pero solo la portada lleva la etiqueta: si el
    // resto también la llevara, pasar de página rompería el vuelo con un tag
    // duplicado.
    expect(_heroTags(tester).where((each) => each == tag), hasLength(1));
  });

  testWidgets('the size travels to the cart with the capped quantity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakePartnerRepository(
      detail: const PartnerDetail(partner: _store, products: [_product]),
    );
    final container = await _pumpRoute(
      tester,
      repository,
      RoutePaths.storeProduct('product-1'),
    );

    // Sin talle elegido no se puede agregar: el pedido saldría sin el dato que
    // más importa.
    final submitFinder = find.byKey(const ValueKey('add-bar-submit'));
    expect(tester.widget<FilledButton>(submitFinder).onPressed, isNull);

    final unavailableSize = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('merch-size-size-s')),
    );
    expect(unavailableSize.onSelected, isNull);

    await tester.tap(find.byKey(const ValueKey('merch-size-size-m')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submitFinder).onPressed, isNotNull);

    // El talle M tiene 2 en stock: el contador no puede pasar de ahí.
    await tester.tap(find.byKey(const ValueKey('add-bar-increment')));
    await tester.pump();
    expect(find.text('2 productos'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('add-bar-increment')))
          .onPressed,
      isNull,
    );

    await tester.tap(submitFinder);
    await tester.pumpAndSettle();

    final line = container.read(cartProvider)['store-1']!.lines.single;
    expect(line.variantId, 'size-m');
    expect(line.sizeLabel, 'M');
    expect(line.quantity, 2);

    container.read(routerProvider).go(RoutePaths.cart);
    await tester.pumpAndSettle();
    expect(find.text('Polera Woofy negra'), findsOneWidget);
    expect(find.text('Talle M'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(320, 568), Size(412, 915)]) {
    testWidgets('merch has no overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = FakePartnerRepository(
        detail: const PartnerDetail(partner: _store, products: [_product]),
      );
      await _pumpRoute(tester, repository, RoutePaths.store);
      expect(tester.takeException(), isNull);

      final productCard = find.byKey(const ValueKey('merch-product-product-1'));
      await tester.ensureVisible(productCard);
      await tester.pumpAndSettle();
      await tester.tap(productCard);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

Iterable<Object> _heroTags(WidgetTester tester) =>
    tester.widgetList<Hero>(find.byType(Hero)).map((hero) => hero.tag);

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

Future<ProviderContainer> _pumpRoute(
  WidgetTester tester,
  FakePartnerRepository repository,
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
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WoofyApp()),
  );
  container.read(routerProvider).go(route);
  await tester.pumpAndSettle();
  return container;
}
