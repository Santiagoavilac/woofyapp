import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_app/core/services/supabase_service.dart';
import 'package:mi_app/features/auth/providers/auth_providers.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';
import 'package:mi_app/features/favorites/data/favorites_repository.dart';

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

final favoriteMutationProvider =
    NotifierProvider<FavoriteMutationController, Set<String>>(
      FavoriteMutationController.new,
    );

class FavoriteMutationController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  Future<void> toggle(String dogId) async {
    if (state.contains(dogId)) return;
    state = {...state, dogId};
    try {
      await ref.read(favoritesRepositoryProvider).toggleFavorite(dogId);
      ref.invalidate(favoriteDogIdsProvider);
      ref.invalidate(favoriteDogsProvider);
    } finally {
      state = {...state}..remove(dogId);
    }
  }
}
