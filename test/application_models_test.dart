import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/features/applications/data/application_models.dart';

void main() {
  test('application parses every real status', () {
    const statuses = {
      'submitted': ApplicationStatus.submitted,
      'reviewing': ApplicationStatus.reviewing,
      'interview': ApplicationStatus.interview,
      'approved': ApplicationStatus.approved,
      'rejected': ApplicationStatus.rejected,
      'withdrawn': ApplicationStatus.withdrawn,
      'completed': ApplicationStatus.completed,
    };

    for (final entry in statuses.entries) {
      final application = AdoptionApplication.fromJson({
        'id': 'application-1',
        'dog_id': 'dog-1',
        'adopter_id': 'user-1',
        'shelter_id': 'shelter-1',
        'status': entry.key,
        'created_at': '2026-06-21T12:00:00Z',
      });
      expect(application.status, entry.value);
    }
  });

  test('form data emits only real application form columns', () {
    const input = ApplicationFormData(
      phone: '+59170000000',
      city: 'Santa Cruz',
      housingType: HousingType.apartment,
      hasChildren: true,
      hasPets: false,
      experience: 'Tuve perros durante diez años.',
      motivation: 'Quiero sumar un compañero estable a mi familia.',
    );

    expect(input.toJson(), {
      'phone': '+59170000000',
      'city': 'Santa Cruz',
      'housing_type': 'departamento',
      'has_children': true,
      'has_pets': false,
      'experience': 'Tuve perros durante diez años.',
      'motivation': 'Quiero sumar un compañero estable a mi familia.',
    });
  });
}
