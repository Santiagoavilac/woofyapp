import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/favorites/data/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => SupabaseFavoritesRepository(ref.watch(supabaseClientProvider)),
);

final favoriteDogIdsProvider = FutureProvider<Set<String>>((ref) async {
  if (ref.watch(currentUserProvider) == null) return const <String>{};
  return ref
      .watch(favoritesRepositoryProvider)
      .fetchFavoriteDogIdsForCurrentUser();
});

final favoriteDogsProvider = FutureProvider<List<Dog>>((ref) async {
  if (ref.watch(currentUserProvider) == null) return const <Dog>[];
  return ref.watch(favoritesRepositoryProvider).fetchFavoriteDogs();
});

/// Lo que el usuario acaba de decidir, antes de que el servidor lo confirme.
///
/// El corazón tiene que llenarse en el momento del toque: si espera el viaje
/// de red completo, marcar un favorito se siente lento y se pierde el impulso.
final favoriteOverrideProvider =
    NotifierProvider<FavoriteOverrideController, Map<String, bool>>(
      FavoriteOverrideController.new,
    );

class FavoriteOverrideController extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const <String, bool>{};

  void set(String dogId, {required bool isFavorite}) =>
      state = {...state, dogId: isFavorite};

  void clear(String dogId) => state = {...state}..remove(dogId);
}

/// Estado que el corazón tiene que mostrar ahora mismo.
final isFavoriteProvider = Provider.family<bool, String>((ref, dogId) {
  final pending = ref.watch(favoriteOverrideProvider)[dogId];
  if (pending != null) return pending;
  final ids = ref.watch(favoriteDogIdsProvider).value ?? const <String>{};
  return ids.contains(dogId);
});

final favoriteMutationProvider =
    NotifierProvider<FavoriteMutationController, Set<String>>(
      FavoriteMutationController.new,
    );

class FavoriteMutationController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  Future<void> toggle(String dogId) async {
    if (state.contains(dogId)) return;
    final wasFavorite = ref.read(isFavoriteProvider(dogId));
    ref
        .read(favoriteOverrideProvider.notifier)
        .set(dogId, isFavorite: !wasFavorite);
    state = {...state, dogId};
    try {
      await ref.read(favoritesRepositoryProvider).toggleFavorite(dogId);
      ref.invalidate(favoriteDogIdsProvider);
      ref.invalidate(favoriteDogsProvider);
      // Recién cuando la lista real volvió se suelta el estado optimista: si se
      // soltara antes, el corazón parpadearía al valor viejo.
      await ref.read(favoriteDogIdsProvider.future);
    } finally {
      ref.read(favoriteOverrideProvider.notifier).clear(dogId);
      state = {...state}..remove(dogId);
    }
  }
}
