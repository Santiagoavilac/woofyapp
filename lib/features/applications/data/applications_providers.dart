import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_app/core/services/supabase_service.dart';
import 'package:mi_app/features/applications/data/application_models.dart';
import 'package:mi_app/features/applications/data/applications_repository.dart';
import 'package:mi_app/features/auth/providers/auth_providers.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';

final applicationsRepositoryProvider = Provider<ApplicationsRepository>(
  (ref) => SupabaseApplicationsRepository(ref.watch(supabaseClientProvider)),
);

final currentDogApplicationProvider =
    FutureProvider.family<AdoptionApplication?, String>((ref, dogId) async {
      if (ref.watch(currentUserProvider) == null) return null;
      return ref
          .watch(applicationsRepositoryProvider)
          .fetchMyApplicationForDog(dogId);
    });

final applicationSubmissionProvider =
    NotifierProvider.family<
      ApplicationSubmissionController,
      AsyncValue<AdoptionApplication?>,
      String
    >((dogId) => ApplicationSubmissionController(dogId));

class ApplicationSubmissionController
    extends Notifier<AsyncValue<AdoptionApplication?>> {
  ApplicationSubmissionController(this.dogId);

  final String dogId;

  @override
  AsyncValue<AdoptionApplication?> build() => const AsyncData(null);

  Future<AdoptionApplication?> submit(
    Dog dog,
    ApplicationFormData formData,
  ) async {
    if (state.isLoading) return null;
    if (dog.id != dogId) {
      throw ArgumentError.value(dog.id, 'dog.id', 'No coincide con el flujo');
    }
    state = const AsyncLoading();
    try {
      final application = await ref
          .read(applicationsRepositoryProvider)
          .createApplication(dog, formData);
      state = AsyncData(application);
      ref.invalidate(currentDogApplicationProvider(dog.id));
      return application;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
