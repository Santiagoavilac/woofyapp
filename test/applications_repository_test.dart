import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/applications/data/application_models.dart';
import 'package:woofy/features/applications/data/applications_repository.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const dog = Dog(
    id: 'dog-1',
    shelterId: 'shelter-1',
    name: 'Milo',
    slug: 'milo-demo',
    story: 'Historia',
    status: 'published',
  );
  const form = ApplicationFormData(
    phone: '+59170000000',
    city: 'Santa Cruz',
    housingType: HousingType.houseWithYard,
    hasChildren: false,
    hasPets: true,
    experience: 'Tengo experiencia cuidando perros.',
    motivation: 'Quiero ofrecerle un hogar estable y responsable.',
  );

  test('application lookup is scoped to the authenticated adopter', () async {
    final source = _FakeApplicationsDataSource(currentUserId: 'user-1');
    final repository = SupabaseApplicationsRepository.withDataSource(source);

    await repository.fetchMyApplicationForDog('dog-1');

    expect(source.lookup, ('user-1', 'dog-1'));
  });

  test(
    'create application controls adopter, shelter and initial status',
    () async {
      final source = _FakeApplicationsDataSource(currentUserId: 'user-1');
      final repository = SupabaseApplicationsRepository.withDataSource(source);

      final application = await repository.createApplication(dog, form);

      expect(source.inserted, {
        'dog_id': 'dog-1',
        'adopter_id': 'user-1',
        'shelter_id': 'shelter-1',
        'status': 'submitted',
        ...form.toJson(),
      });
      expect(application.status, ApplicationStatus.submitted);
    },
  );

  test('duplicate applications use the required safe message', () async {
    final source = _FakeApplicationsDataSource(currentUserId: 'user-1')
      ..insertError = const PostgrestException(
        message: 'duplicate',
        code: '23505',
      );
    final repository = SupabaseApplicationsRepository.withDataSource(source);

    await expectLater(
      repository.createApplication(dog, form),
      throwsA(
        isA<AppException>()
            .having((error) => error.code, 'code', 'duplicate_application')
            .having(
              (error) => error.message,
              'message',
              'Ya postulaste a este perrito.',
            ),
      ),
    );
  });

  test('application creation requires an authenticated user', () async {
    final repository = SupabaseApplicationsRepository.withDataSource(
      _FakeApplicationsDataSource(),
    );

    await expectLater(
      repository.createApplication(dog, form),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'auth_required',
        ),
      ),
    );
  });
}

class _FakeApplicationsDataSource implements ApplicationsDataSource {
  _FakeApplicationsDataSource({this.currentUserId});

  @override
  final String? currentUserId;
  (String, String)? lookup;
  Map<String, dynamic>? inserted;
  Object? insertError;

  @override
  Future<Map<String, dynamic>?> fetchApplicationForDog(
    String adopterId,
    String dogId,
  ) async {
    lookup = (adopterId, dogId);
    return null;
  }

  @override
  Future<Map<String, dynamic>> insertApplication(
    Map<String, dynamic> values,
  ) async {
    inserted = values;
    if (insertError case final error?) throw error;
    return {
      'id': 'application-1',
      ...values,
      'created_at': '2026-06-21T12:00:00Z',
    };
  }
}
