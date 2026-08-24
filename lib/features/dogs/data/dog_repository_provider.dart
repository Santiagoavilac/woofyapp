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
