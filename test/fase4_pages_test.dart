import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/features/applications/data/application_models.dart';
import 'package:woofy/features/applications/presentation/widgets/application_form.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/favorites/data/favorites_providers.dart';
import 'package:woofy/features/favorites/presentation/favorites_page.dart';
import 'package:woofy/features/favorites/presentation/widgets/favorite_dog_card.dart';
import 'package:woofy/features/favorites/presentation/widgets/favorite_row_card.dart';

void main() {
  testWidgets('reduced motion shows the favorites without waiting', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          favoriteDogsProvider.overrideWith((ref) async => const [_dog]),
          favoriteDogIdsProvider.overrideWith((ref) async => {'dog-1'}),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: FavoritesPage(),
          ),
        ),
      ),
    );
    // Sin `pumpAndSettle`: con el movimiento apagado la grilla tiene que estar
    // entera en el primer cuadro en que existe, no desvanecida.
    await tester.pump();
    await tester.pump();

    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Milo'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('favorites page shows populated state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          favoriteDogsProvider.overrideWith((ref) async => const <Dog>[]),
          favoriteDogIdsProvider.overrideWith((ref) async => <String>{}),
        ],
        child: const MaterialApp(home: FavoritesPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Todavía no guardaste favoritos'), findsOneWidget);
    expect(find.text('Ver animales'), findsOneWidget);
    expect(find.byKey(const ValueKey('favorites-empty-image')), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          favoriteDogsProvider.overrideWith((ref) async => const [_dog]),
          favoriteDogIdsProvider.overrideWith((ref) async => {'dog-1'}),
        ],
        child: const MaterialApp(home: FavoritesPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Milo'), findsOneWidget);
    expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
  });

  testWidgets('one column lays favorites out flat, two columns keeps the card', (
    tester,
  ) async {
    Future<void> pumpAt(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            favoriteDogsProvider.overrideWith((ref) async => const [_dog]),
            favoriteDogIdsProvider.overrideWith((ref) async => {'dog-1'}),
          ],
          child: const MaterialApp(home: FavoritesPage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // En teléfono la tarjeta grande deja ver un favorito por pantalla, así que
    // la lista va acostada.
    await pumpAt(const Size(390, 844));
    expect(find.byType(FavoriteRowCard), findsOneWidget);
    expect(find.byType(FavoriteDogCard), findsNothing);
    expect(find.text('Milo'), findsOneWidget);
    expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);

    // Con ancho de sobra la tarjeta grande sí luce.
    await pumpAt(const Size(900, 1200));
    expect(find.byType(FavoriteDogCard), findsOneWidget);
    expect(find.byType(FavoriteRowCard), findsNothing);
  });

  testWidgets('each step blocks the way forward with its own empty fields', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ApplicationForm(onSubmit: (_) async => calls++),
          ),
        ),
      ),
    );

    // Paso 1: teléfono y ciudad vacíos frenan el avance, y marcan solo los
    // suyos — los campos de los pasos ocultos no gritan por adelantado.
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Este campo es obligatorio.'), findsNWidgets(2));
    expect(find.text('Paso 1 de 3'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Teléfono'),
      '70000000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ciudad'),
      'La Paz',
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Paso 2 es desplegable e interruptores: siempre válido, nunca traba.
    expect(find.text('Paso 2 de 3'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Paso 3 de 3'), findsOneWidget);
    await tester.ensureVisible(find.text('Enviar postulación'));
    await tester.tap(find.text('Enviar postulación'));
    await tester.pumpAndSettle();
    expect(find.text('Este campo es obligatorio.'), findsNWidgets(2));
    expect(calls, 0);
  });

  testWidgets('walking the three steps submits the same data as before', (
    tester,
  ) async {
    final gate = Completer<void>();
    ApplicationFormData? sent;
    Future<void> submit(ApplicationFormData data) async {
      sent = data;
      await gate.future;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ApplicationForm(initialPhone: '70000000', onSubmit: submit),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ciudad'),
      'La Paz',
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hay otros animales'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Experiencia previa'),
      'Tengo experiencia cuidando perros.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Motivación para adoptar'),
      'Quiero ofrecer un hogar seguro y responsable.',
    );
    await tester.ensureVisible(find.text('Enviar postulación'));
    await tester.tap(find.text('Enviar postulación'));
    await tester.pump();

    // Los pasos ocultos siguen montados: lo que se contestó en el paso 1 y 2
    // llega entero al envío.
    expect(sent, isNotNull);
    expect(sent!.phone, '70000000');
    expect(sent!.city, 'La Paz');
    expect(sent!.housingType, HousingType.houseWithYard);
    expect(sent!.hasChildren, isFalse);
    expect(sent!.hasPets, isTrue);
    expect(sent!.experience, 'Tengo experiencia cuidando perros.');
    expect(sent!.motivation, 'Quiero ofrecer un hogar seguro y responsable.');
    gate.complete();
    await tester.pump();
  });

  testWidgets('going back keeps what was already answered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ApplicationForm(onSubmit: (_) async {}),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Teléfono'),
      '70000000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ciudad'),
      'Sucre',
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Tu hogar'), findsOneWidget);

    await tester.tap(find.text('Atrás'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    expect(find.text('Sucre'), findsOneWidget);
  });

  testWidgets('reduced motion shows the step complete on the first frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SingleChildScrollView(
              child: ApplicationForm(
                initialPhone: '70000000',
                onSubmit: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ciudad'),
      'La Paz',
    );
    await tester.tap(find.text('Continuar'));
    // Un solo `pump`: el paso nuevo tiene que estar entero, no a medio aparecer.
    await tester.pump();

    expect(find.text('Tu hogar'), findsOneWidget);
    final fade = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.text('Tipo de vivienda'),
            matching: find.byType(Opacity),
          )
          .last,
    );
    expect(fade.opacity, 1);
  });

  testWidgets('the stepped form has no overflow at 320x568', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ApplicationForm(
              initialPhone: '70000000',
              onSubmit: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ciudad'),
      'La Paz',
    );
    // La fila "Atrás / Continuar" del paso 2 es la más apretada: dos botones
    // con ícono en 320 px.
    for (var step = 0; step < 2; step++) {
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  for (final size in <Size>[const Size(320, 568), const Size(800, 1200)]) {
    testWidgets('favorites has no overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            favoriteDogsProvider.overrideWith((ref) async => const [_dog]),
            favoriteDogIdsProvider.overrideWith((ref) async => {'dog-1'}),
          ],
          child: const MaterialApp(home: FavoritesPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

const _dog = Dog(
  id: 'dog-1',
  shelterId: 'shelter-1',
  name: 'Milo',
  slug: 'milo-demo',
  story: 'Historia',
  status: 'published',
  sex: 'macho',
  size: 'mediano',
  shelter: DogShelter(id: 'shelter-1', name: 'Woofy'),
);
