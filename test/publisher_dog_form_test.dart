import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/features/publisher/data/publisher_models.dart';

void main() {
  group('DogFormData.toPortalJson', () {
    test('emits details keys only for non-empty values', () {
      final data = DogFormData(
        name: 'Milo',
        slug: 'milo',
        story: 'Historia larga.',
        status: 'draft',
        breed: 'Mestizo',
        idealHome: '',
        specialCare: '  ',
        feedingNotes: 'balanceado',
      );

      final json = data.toPortalJson();
      final details = json['details'] as Map<String, dynamic>;

      expect(details.containsKey('breed'), isTrue);
      expect(details['breed'], 'Mestizo');
      expect(details['feeding_notes'], 'balanceado');
      expect(details.containsKey('ideal_home'), isFalse);
      expect(details.containsKey('special_care'), isFalse);
    });

    test('emits dogs-level extra fields with defaults and overrides', () {
      final data = DogFormData(
        name: 'Luna',
        slug: 'luna',
        story: '.',
        status: 'published',
        energyLevel: 'alta',
        sterilized: true,
        vaccinated: true,
        goodWithChildren: true,
        goodWithDogs: false,
        goodWithCats: null,
        temperament: 'sociable',
      );

      final json = data.toPortalJson();

      expect(json['energy_level'], 'alta');
      expect(json['sterilized'], true);
      expect(json['vaccinated'], true);
      expect(json['temperament'], 'sociable');
      expect(json['good_with_children'], true);
      expect(json['good_with_dogs'], false);
      expect(json['good_with_cats'], isNull);
    });

    test(
      'medical_events drops entries without title and includes those with title',
      () {
        final data = DogFormData(
          name: 'Rocky',
          slug: 'rocky',
          story: '.',
          status: 'draft',
          medicalEvents: [
            const MedicalEventFormData(
              title: 'Vacuna antirrábica',
              eventType: 'vacuna',
            ),
            const MedicalEventFormData(title: '   '),
            MedicalEventFormData(
              title: 'Cirugía',
              eventType: 'cirugía',
              eventDate: DateTime.utc(2025, 3, 14),
              description: 'Todo bien.',
            ),
          ],
        );

        final events = data.toPortalJson()['medical_events'] as List;

        expect(events.length, 2);
        expect(events.first['title'], 'Vacuna antirrábica');
        expect(events.first['event_type'], 'vacuna');
        expect(events.last['event_date'], '2025-03-14');
        expect(events.last['description'], 'Todo bien.');
      },
    );
  });
}
