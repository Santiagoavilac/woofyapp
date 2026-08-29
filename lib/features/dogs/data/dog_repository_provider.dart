import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/data/dog_repository.dart';

final dogRepositoryProvider = Provider<DogRepository>(
  (ref) => SupabaseDogRepository(ref.watch(supabaseClientProvider)),
);

final publishedDogsProvider = FutureProvider<List<Dog>>(
  (ref) => ref.watch(dogRepositoryProvider).fetchPublishedDogs(),
);

final dogDetailProvider = FutureProvider.family<DogDetail?, String>(
  (ref, slug) => ref.watch(dogRepositoryProvider).fetchPublishedDogBySlug(slug),
);

/// City the catalog is scoped to. `null` means every city.
///
/// Lives here (not in [DogsPage]) because the home header picks the city and
/// the catalog reads it.
final selectedCityProvider = NotifierProvider<SelectedCity, String?>(
  SelectedCity.new,
);

class SelectedCity extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? city) => state = city;
}

/// Cities with at least one published animal, alphabetically.
final availableCitiesProvider = Provider<List<String>>((ref) {
  final dogs = ref.watch(publishedDogsProvider).value ?? const <Dog>[];
  final cities = <String>{};
  for (final dog in dogs) {
    final city = dog.shelter?.city;
    if (city != null && city.isNotEmpty) cities.add(city);
  }
  return cities.toList()..sort();
});
