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

  testWidgets('la caja toma la forma de lo que se subió', (tester) async {
    // Un banner más cuadrado que el viejo 2.5:1 tiene que verse entero, no
    // recortado contra una medida que ya no existe.
    await _pump(tester, [_banner(0, ratio: 16 / 9)]);

    expect(_boxRatio(tester), closeTo(16 / 9, 0.001));
  });

  testWidgets('sin proporción guardada usa la de siempre', (tester) async {
    // Los banners cargados antes de que el panel midiera la imagen.
    await _pump(tester, _banners(1));

    expect(
      _boxRatio(tester),
      closeTo(BannerCarousel.defaultAspectRatio, 0.001),
    );
  });

  group('el texto encima de la imagen', () {
    testWidgets('por defecto se dibuja', (tester) async {
      await _pump(tester, [_banner(0, subtitle: 'Bajada')]);

      expect(find.text('Banner 0'), findsOneWidget);
      expect(find.text('Bajada'), findsOneWidget);
    });

    testWidgets('un banner que ya trae su texto no lo repite', (tester) async {
      // El titular y el botón vienen dibujados en el PNG, justo en la esquina
      // donde iría el velo. Superponer otro título tapa el diseño.
      await _pump(tester, [_banner(0, subtitle: 'Bajada', showCaption: false)]);

      expect(find.text('Banner 0'), findsNothing);
      expect(find.text('Bajada'), findsNothing);
    });

    testWidgets('sin texto encima el título lo dice el lector', (tester) async {
      // Sin velo no queda ningún texto en pantalla: el label es lo único que
      // le queda a alguien que no ve la imagen.
      final handle = tester.ensureSemantics();
      await _pump(tester, [_banner(0, showCaption: false)]);

      expect(find.bySemanticsLabel('Banner 0'), findsOneWidget);
      handle.dispose();
    });
  });

  group('la caja es una sola para todo el carrusel', () {
    test('con formas distintas se reparte el recorte', () {
      // Si cada banner impusiera la suya, el carrusel cambiaría de alto en
      // pleno arrastre. Promediar deja a los dos con un recorte parecido, en
      // vez de sacrificar uno entero.
      final ratio = BannerCarousel.aspectRatioOf([
        _banner(0, ratio: 3),
        _banner(1, ratio: 1.8),
      ]);

      expect(ratio, closeTo(2.4, 0.001));
    });

    test('con todos iguales no recorta a nadie', () {
      // El caso normal: los banners de una pantalla los hace la misma persona.
      final ratio = BannerCarousel.aspectRatioOf([
        _banner(0, ratio: 2.2),
        _banner(1, ratio: 2.2),
        _banner(2, ratio: 2.2),
      ]);

      expect(ratio, closeTo(2.2, 0.001));
    });

    test('una proporción imposible no rompe el layout', () {
      // Una fila cargada por fuera del panel, sin el check de la base delante.
      final ratio = BannerCarousel.aspectRatioOf([
        _banner(0, ratio: 0.4),
        _banner(1, ratio: 40),
      ]);

      expect(ratio, greaterThanOrEqualTo(BannerCarousel.minAspectRatio));
      expect(ratio, lessThanOrEqualTo(BannerCarousel.maxAspectRatio));
    });
  });
}

double _boxRatio(WidgetTester tester) {
  final box = tester.widget<AspectRatio>(
    find.ancestor(
      of: find.byType(PageView),
      matching: find.byType(AspectRatio),
    ),
  );
  return box.aspectRatio;
}

int _pageOf(WidgetTester tester) {
  final view = tester.widget<PageView>(find.byType(PageView));
  return view.controller!.page!.round();
}

PromoBanner _banner(
  int index, {
  double? ratio,
  String? subtitle,
  bool showCaption = true,
}) => PromoBanner(
  id: 'b$index',
  title: 'Banner $index',
  subtitle: subtitle,
  imageUrl: 'https://x/$index.png',
  aspectRatio: ratio,
  showCaption: showCaption,
);

List<PromoBanner> _banners(int count) => [
  for (var i = 0; i < count; i++) _banner(i),
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
