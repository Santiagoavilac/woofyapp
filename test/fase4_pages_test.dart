import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/features/applications/data/application_models.dart';
import 'package:mi_app/features/applications/presentation/widgets/application_form.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';
import 'package:mi_app/features/favorites/data/favorites_providers.dart';
import 'package:mi_app/features/favorites/presentation/favorites_page.dart';

void main() {
  testWidgets('favorites page shows empty state', (tester) async {});

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

  testWidgets('application form validates real required fields', (
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
    await tester.ensureVisible(find.text('Enviar postulación'));
    await tester.tap(find.text('Enviar postulación'));
    await tester.pump();
    expect(find.text('Este campo es obligatorio.'), findsNWidgets(4));
    expect(calls, 0);
  });

  testWidgets('valid application form submits the real fields', (tester) async {
    final gate = Completer<void>();
    var calls = 0;
    Future<void> submit(ApplicationFormData data) async {
      calls++;
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
    expect(calls, 1);
    gate.complete();
    await tester.pump();
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
