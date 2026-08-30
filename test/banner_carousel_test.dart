import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/features/banners/data/banner_models.dart';
import 'package:woofy/features/banners/data/banner_repository_provider.dart';
import 'package:woofy/features/banners/presentation/widgets/banner_carousel.dart';

void main() {
  testWidgets('con un solo banner no se mueve solo', (tester) async {
    await _pump(tester, _banners(1));

    expect(find.byKey(const ValueKey('promo-banner-b0')), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('promo-banner-b0')), findsOneWidget);
  });

  testWidgets('con varios banners pasa solo al siguiente', (tester) async {
    await _pump(tester, _banners(3));

    expect(_pageOf(tester), 0);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(_pageOf(tester), 1);
  });

  testWidgets('después del último vuelve al primero', (tester) async {
    await _pump(tester, _banners(2));

    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    }
    expect(_pageOf(tester), 0);
  });

  testWidgets('con movimiento reducido se queda quieto', (tester) async {
    // Un carrusel que avanza solo es justo el movimiento que nadie pidió. Las
    // páginas siguen a mano: se pasan arrastrando.
    await _pump(tester, _banners(3), reduceMotion: true);

    await tester.pump(const Duration(seconds: 12));
    await tester.pumpAndSettle();
    expect(_pageOf(tester), 0);
  });

  testWidgets('sin banners y sin respaldo no dibuja nada', (tester) async {
    await _pump(tester, const []);

    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('sin banners muestra el respaldo', (tester) async {
    await _pump(
      tester,
      const [],
      fallback: const Text('Adoptá', key: ValueKey('fallback')),
    );

    expect(find.byKey(const ValueKey('fallback')), findsOneWidget);
  });
}

int _pageOf(WidgetTester tester) {
  final view = tester.widget<PageView>(find.byType(PageView));
  return view.controller!.page!.round();
}

List<PromoBanner> _banners(int count) => [
  for (var i = 0; i < count; i++)
    PromoBanner(id: 'b$i', title: 'Banner $i', imageUrl: 'https://x/$i.png'),
];

Future<void> _pump(
  WidgetTester tester,
  List<PromoBanner> banners, {
  bool reduceMotion = false,
  Widget? fallback,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bannersProvider(BannerSlot.home).overrideWith((ref) async => banners),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(
            body: BannerCarousel(slot: BannerSlot.home, fallback: fallback),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
