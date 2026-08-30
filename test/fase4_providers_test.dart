import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/features/applications/data/application_models.dart';
import 'package:woofy/features/applications/data/applications_providers.dart';
import 'package:woofy/features/applications/data/applications_repository.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/favorites/data/favorites_providers.dart';
import 'package:woofy/features/favorites/data/favorites_repository.dart';

void main() {
  const user = AppUser(id: 'user-1', email: 'adopter@example.com');

  test(
    'favorite providers load IDs and prevent simultaneous toggles',
    () async {
      final repository = _FakeFavoritesRepository();
      final gate = Completer<void>();
      repository.toggleGate = gate;
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          favoritesRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(favoriteDogIdsProvider.future), {'dog-1'});
      final first = container
          .read(favoriteMutationProvider.notifier)
          .toggle('dog-1');
      final second = container
          .read(favoriteMutationProvider.notifier)
          .toggle('dog-1');
      expect(container.read(favoriteMutationProvider), contains('dog-1'));
      expect(repository.toggleCalls, 1);
      gate.complete();
      await Future.wait([first, second]);
      expect(container.read(favoriteMutationProvider), isEmpty);
    },
  );

  test('the heart flips before the network answers', () async {
    final repository = _FakeFavoritesRepository();
    final gate = Completer<void>();
    repository.toggleGate = gate;
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(user),
        favoritesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(favoriteDogIdsProvider.future);
    expect(container.read(isFavoriteProvider('dog-1')), isTrue);

    final pending = container
        .read(favoriteMutationProvider.notifier)
        .toggle('dog-1');
    // Sin esperar el viaje de red: si el corazón tardara, marcar un favorito
    // se sentiría lento y se perdería el impulso.
    expect(container.read(isFavoriteProvider('dog-1')), isFalse);

    gate.complete();
    await pending;
    expect(container.read(favoriteOverrideProvider), isEmpty);
  });

  test(
    'application provider exposes existing state and blocks double submit',
    () async {
      final repository = _FakeApplicationsRepository();
      final gate = Completer<void>();
      repository.createGate = gate;
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          applicationsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(currentDogApplicationProvider('dog-1').future),
        isNull,
      );
      final controller = container.read(
        applicationSubmissionProvider('dog-1').notifier,
      );
      final first = controller.submit(_dog, _form);
      final second = controller.submit(_dog, _form);
      expect(repository.createCalls, 1);
      gate.complete();
      await Future.wait([first, second]);
      expect(
        container.read(applicationSubmissionProvider('dog-1')).value?.status,
        ApplicationStatus.submitted,
      );
    },
  );
}

const _dog = Dog(
  id: 'dog-1',
  shelterId: 'shelter-1',
  name: 'Milo',
  slug: 'milo-demo',
  story: 'Historia',
  status: 'published',
);

const _form = ApplicationFormData(
  phone: '70000000',
  city: 'La Paz',
  housingType: HousingType.apartment,
  hasChildren: false,
  hasPets: true,
  experience: 'Experiencia suficiente',
  motivation: 'Quiero darle un hogar responsable.',
);

class _FakeFavoritesRepository implements FavoritesRepository {
  Completer<void>? toggleGate;
  int toggleCalls = 0;

  @override
  Future<Set<String>> fetchFavoriteDogIdsForCurrentUser() async => {'dog-1'};
  @override
  Future<List<Dog>> fetchFavoriteDogs() async => const [_dog];
  @override
  Future<bool> toggleFavorite(String dogId) async {
    toggleCalls++;
    await toggleGate?.future;
    return false;
  }

  @override
  Future<void> addFavorite(String dogId) async {}
  @override
  Future<bool> isFavorite(String dogId) async => true;
  @override
  Future<void> removeFavorite(String dogId) async {}
}

class _FakeApplicationsRepository implements ApplicationsRepository {
  Completer<void>? createGate;
  int createCalls = 0;
  @override
  Future<AdoptionApplication> createApplication(
    Dog dog,
    ApplicationFormData formData,
  ) async {
    createCalls++;
    await createGate?.future;
    return AdoptionApplication(
      id: 'application-1',
      dogId: 'dog-1',
      adopterId: 'user-1',
      shelterId: 'shelter-1',
      status: ApplicationStatus.submitted,
      createdAt: DateTime.utc(2026, 6, 21),
    );
  }

  @override
  Future<AdoptionApplication?> fetchMyApplicationForDog(String dogId) async =>
      null;
}
