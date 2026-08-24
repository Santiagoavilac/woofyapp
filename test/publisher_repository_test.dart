import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/core/errors/app_exception.dart';
import 'package:mi_app/features/publisher/data/publisher_models.dart';
import 'package:mi_app/features/publisher/data/publisher_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('fetchMyShelterMemberships queries with current user id', () async {
    final source = _FakePublisherDataSource();
    final repository = SupabasePublisherRepository.withDataSource(source);

    final memberships = await repository.fetchMyShelterMemberships();

    expect(source.membershipUserId, 'user-1');
    expect(memberships.length, 1);
    expect(memberships.first.shelterName, 'Refugio Woofy');
    expect(memberships.first.shelterId, 'shelter-1');
  });

  test('fetchShelterDogs returns all-status dogs for the shelter', () async {
    final source = _FakePublisherDataSource();
    final repository = SupabasePublisherRepository.withDataSource(source);

    final dogs = await repository.fetchShelterDogs('shelter-1');

    expect(source.dogsFetchedShelterId, 'shelter-1');
    expect(dogs.length, 2);
    expect(
      dogs.map((d) => d.status).toList(),
      containsAll(['draft', 'published']),
    );
  });

  test(
    'createDog inserts shelter_id from argument, not from form data',
    () async {
      final source = _FakePublisherDataSource();
      final repository = SupabasePublisherRepository.withDataSource(source);

      await repository.createDog(
        'shelter-1',
        const DogFormData(
          name: 'Max',
          slug: 'max',
          story: 'Un perro muy bueno.',
          status: 'draft',
        ),
      );

      expect(source.insertedDog?['shelter_id'], 'shelter-1');
      expect(source.insertedDog?['name'], 'Max');
      expect(source.insertedDog?['slug'], 'max');
      expect(source.insertedDog?.containsKey('shelter_id'), isTrue);
    },
  );

  test(
    'createDog throws AppException with code slug_taken on duplicate',
    () async {
      final source = _FakePublisherDataSource(slugConflict: true);
      final repository = SupabasePublisherRepository.withDataSource(source);

      await expectLater(
        repository.createDog(
          'shelter-1',
          const DogFormData(
            name: 'Max',
            slug: 'max',
            story: 'Historia.',
            status: 'draft',
          ),
        ),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', 'slug_taken'),
        ),
      );
    },
  );

  test(
    'updateDog sends only form fields — shelter_id is never in the update',
    () async {
      final source = _FakePublisherDataSource();
      final repository = SupabasePublisherRepository.withDataSource(source);

      await repository.updateDog(
        'dog-1',
        const DogFormData(
          name: 'Max actualizado',
          slug: 'max',
          story: 'Historia actualizada.',
          status: 'published',
          sex: 'macho',
        ),
      );

      expect(source.updatedDogId, 'dog-1');
      expect(source.updatedFields?['name'], 'Max actualizado');
      expect(source.updatedFields?['status'], 'published');
      expect(source.updatedFields?.containsKey('shelter_id'), isFalse);
    },
  );

  test(
    'repository throws auth_required when user is not authenticated',
    () async {
      final repository = SupabasePublisherRepository.withDataSource(
        _FakePublisherDataSource(currentUserId: null),
      );

      await expectLater(
        repository.fetchMyShelterMemberships(),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', 'auth_required'),
        ),
      );
    },
  );

  test(
    'fetchDogById throws publisher_dog_not_found when dog is missing',
    () async {
      final source = _FakePublisherDataSource(hasDog: false);
      final repository = SupabasePublisherRepository.withDataSource(source);

      await expectLater(
        repository.fetchDogById('dog-unknown'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'publisher_dog_not_found',
          ),
        ),
      );
    },
  );
}

class _FakePublisherDataSource implements PublisherDataSource {
  _FakePublisherDataSource({
    this.currentUserId = 'user-1',
    this.slugConflict = false,
    this.hasDog = true,
  });

  @override
  final String? currentUserId;
  final bool slugConflict;
  final bool hasDog;

  String? membershipUserId;
  String? dogsFetchedShelterId;
  Map<String, dynamic>? insertedDog;
  String? updatedDogId;
  Map<String, dynamic>? updatedFields;

  @override
  Future<List<Map<String, dynamic>>> fetchMemberships(String userId) async {
    membershipUserId = userId;
    return [
      {
        'id': 'member-1',
        'shelter_id': 'shelter-1',
        'role': 'owner',
        'shelters': {'name': 'Refugio Woofy'},
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDogs(String shelterId) async {
    dogsFetchedShelterId = shelterId;
    return [
      {
        ..._baseDogJson,
        'id': 'dog-1',
        'shelter_id': shelterId,
        'name': 'Max',
        'slug': 'max',
        'status': 'draft',
      },
      {
        ..._baseDogJson,
        'id': 'dog-2',
        'shelter_id': shelterId,
        'name': 'Luna',
        'slug': 'luna',
        'status': 'published',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>?> fetchDog(String dogId) async {
    if (!hasDog) return null;
    return {
      ..._baseDogJson,
      'id': dogId,
      'shelter_id': 'shelter-1',
      'name': 'Max',
      'slug': 'max',
      'status': 'draft',
    };
  }

  @override
  Future<Map<String, dynamic>> insertDog(Map<String, dynamic> values) async {
    insertedDog = values;
    if (slugConflict) {
      throw const PostgrestException(message: 'duplicate key', code: '23505');
    }
    return {..._baseDogJson, 'id': 'dog-created', ...values};
  }

  @override
  Future<Map<String, dynamic>> updateDogFields(
    String dogId,
    Map<String, dynamic> values,
  ) async {
    updatedDogId = dogId;
    updatedFields = values;
    return {..._baseDogJson, 'id': dogId, 'shelter_id': 'shelter-1', ...values};
  }
}

const _baseDogJson = {
  'story': 'Historia.',
  'sex': null,
  'age_months': null,
  'size': null,
  'energy_level': null,
  'sterilized': null,
  'vaccinated': null,
  'medical_notes': null,
  'temperament': null,
  'good_with_children': null,
  'good_with_dogs': null,
  'good_with_cats': null,
  'created_at': '2026-06-22T10:00:00Z',
  'updated_at': '2026-06-23T10:00:00Z',
  'deleted_at': null,
};
