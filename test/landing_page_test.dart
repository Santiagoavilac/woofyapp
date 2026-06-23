import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/app/app.dart';
import 'package:mi_app/features/auth/providers/auth_providers.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';
import 'package:mi_app/features/dogs/data/dog_repository.dart';
import 'package:mi_app/features/dogs/data/dog_repository_provider.dart';
import 'package:mi_app/features/landing/presentation/widgets/hero_dogs_image.dart';
import 'package:mi_app/features/landing/presentation/widgets/landing_background.dart';
import 'package:mi_app/features/landing/presentation/widgets/landing_logo.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('landing presents the Woofy message and primary actions', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Encontrá a tu próximo mejor amigo'), findsOneWidget);
    expect(
      find.text(
        'Conectamos perritos en adopción con personas listas para darles un hogar.',
      ),
      findsOneWidget,
    );
    expect(find.text('Perros'), findsOneWidget);
    expect(find.text('Ingresar refugio'), findsNothing);
    expect(find.text('Mi cuenta'), findsOneWidget);
    expect(find.text('Ver perros en adopción'), findsOneWidget);
  });

  testWidgets('primary call to action opens the dogs route', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Ver perros en adopción'));
    await tester.pumpAndSettle();

    expect(
      find.text('No encontramos perritos publicados todavía.'),
      findsOneWidget,
    );
  });

  testWidgets('dogs navigation link opens the dogs route', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Perros'));
    await tester.pumpAndSettle();

    expect(
      find.text('No encontramos perritos publicados todavía.'),
      findsOneWidget,
    );
  });

  testWidgets('account navigation link opens adopter authentication', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Mi cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresar a Woofy'), findsOneWidget);
  });

  testWidgets('missing landing assets render safe visual fallbacks', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LandingBackground(
            patternAssetPath: 'assets/images/missing-pattern.png',
            child: Column(
              children: [
                SizedBox(
                  width: 300,
                  height: 140,
                  child: LandingLogo(
                    assetPath: 'assets/images/missing-logo.png',
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: HeroDogsImage(
                    assetPath: 'assets/images/missing-dogs.png',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('landing-paw-pattern-fallback')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('landing-logo-fallback')), findsOneWidget);
    expect(find.byKey(const ValueKey('landing-dogs-fallback')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in <Size>[const Size(320, 568), const Size(800, 1200)]) {
    testWidgets('landing has no overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpApp(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Ver perros en adopción'), findsOneWidget);
    });
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dogRepositoryProvider.overrideWithValue(_EmptyDogRepository()),
        authRepositoryProvider.overrideWithValue(auth),
      ],
      child: const WoofyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class _EmptyDogRepository implements DogRepository {
  @override
  Future<List<Dog>> fetchPublishedDogs() async => const [];

  @override
  Future<DogDetail?> fetchPublishedDogBySlug(String slug) async => null;
}
