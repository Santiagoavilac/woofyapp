import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/favorites/data/favorites_providers.dart';
import 'package:woofy/features/favorites/data/favorites_repository.dart';
import 'package:woofy/features/favorites/presentation/widgets/double_tap_like.dart';

void main() {
  testWidgets('double tapping the photo saves the dog', (tester) async {
    final repository = _FakeFavoritesRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('photo')));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byKey(const ValueKey('photo')));
    await tester.pumpAndSettle();

    expect(repository.toggled, ['dog-1']);
  });

  testWidgets('a second double tap does not take the favorite away', (
    tester,
  ) async {
    // En Instagram el doble toque siempre suma. Si alternara, festejar dos
    // veces la misma foto terminaría quitándole el favorito.
    final repository = _FakeFavoritesRepository(favorites: {'dog-1'});
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('photo')));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byKey(const ValueKey('photo')));
    await tester.pumpAndSettle();

    expect(repository.toggled, isEmpty);
  });

  testWidgets('the heart shows up over the photo and then leaves', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakeFavoritesRepository()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_rounded), findsNothing);

    await tester.tap(find.byKey(const ValueKey('photo')));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byKey(const ValueKey('photo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('a single tap still reaches what is underneath', (tester) async {
    // El gesto solo escucha el doble toque: si se comiera el toque simple,
    // dejaría muerto todo lo que tenga debajo.
    var taps = 0;
    await tester.pumpWidget(
      _app(
        _FakeFavoritesRepository(),
        child: GestureDetector(
          onTap: () => taps++,
          child: Container(
            key: const ValueKey('photo'),
            width: 200,
            height: 200,
            color: const Color(0xFFEEEEEE),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('photo')));
    // Hay que pasar la ventana del doble toque a mano: mientras corre, el
    // gesto de arriba retiene la disputa y `pumpAndSettle` no adelanta ese
    // reloj porque no hay ninguna animación pendiente.
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
    expect(taps, 1);
  });
}

Widget _app(_FakeFavoritesRepository repository, {Widget? child}) {
  return ProviderScope(
    overrides: [
      favoritesRepositoryProvider.overrideWithValue(repository),
      // Los dos providers de favoritos leen la sesión, y sin sesión de verdad
      // caen en el cliente de Supabase. Se sirven del repositorio falso.
      favoriteDogIdsProvider.overrideWith((ref) async => repository.favorites),
      favoriteDogsProvider.overrideWith((ref) async => const <Dog>[]),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: DoubleTapLike(
            dogId: 'dog-1',
            child:
                child ??
                Container(
                  key: const ValueKey('photo'),
                  width: 200,
                  height: 200,
                  color: const Color(0xFFEEEEEE),
                ),
          ),
        ),
      ),
    ),
  );
}

class _FakeFavoritesRepository implements FavoritesRepository {
  _FakeFavoritesRepository({Set<String>? favorites})
    : favorites = {...?favorites};

  final Set<String> favorites;
  final List<String> toggled = [];

  @override
  Future<Set<String>> fetchFavoriteDogIdsForCurrentUser() async => favorites;

  @override
  Future<List<Dog>> fetchFavoriteDogs() async => const [];

  @override
  Future<bool> toggleFavorite(String dogId) async {
    toggled.add(dogId);
    final wasFavorite = favorites.remove(dogId);
    if (!wasFavorite) favorites.add(dogId);
    return !wasFavorite;
  }

  @override
  Future<bool> isFavorite(String dogId) async => favorites.contains(dogId);

  @override
  Future<void> addFavorite(String dogId) async => favorites.add(dogId);

  @override
  Future<void> removeFavorite(String dogId) async => favorites.remove(dogId);
}
