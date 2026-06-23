import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';

void main() {
  group('Dog.fromJson', () {
    test('parses the public response and orders the cover photo first', () {
      final dog = Dog.fromJson({
        'id': 'dog-1',
        'shelter_id': 'shelter-1',
        'name': 'Milo',
        'slug': 'milo-demo',
        'story': 'Una historia real.',
        'sex': 'macho',
        'age_months': 18,
        'size': 'mediano',
        'status': 'published',
        'shelters': {
          'id': 'shelter-1',
          'name': 'Woofy',
          'city': 'Santa Cruz',
          'status': 'active',
        },
        'dog_photos': [
          {
            'id': 'photo-2',
            'dog_id': 'dog-1',
            'storage_path': 'dogs/second.jpg',
            'is_cover': false,
            'position': 0,
          },
          {
            'id': 'photo-1',
            'dog_id': 'dog-1',
            'storage_path': 'dogs/cover.jpg',
            'is_cover': true,
            'position': 2,
          },
        ],
      });

      expect(dog.name, 'Milo');
      expect(dog.ageLabel, '1 año y 6 meses');
      expect(dog.shelter?.name, 'Woofy');
      expect(dog.photos.first.id, 'photo-1');
      expect(dog.coverPhoto?.storagePath, 'dogs/cover.jpg');
    });

    test('accepts sparse relations and a dog without photos', () {
      final dog = Dog.fromJson({
        'id': 'dog-2',
        'shelter_id': 'shelter-1',
        'name': 'Luna',
        'slug': 'luna',
        'story': null,
        'status': 'published',
        'shelters': null,
        'dog_photos': null,
      });

      expect(dog.story, isEmpty);
      expect(dog.ageLabel, isNull);
      expect(dog.shelter, isNull);
      expect(dog.photos, isEmpty);
      expect(dog.coverPhoto, isNull);
    });
  });

  test('DogDetail parses extended fields and sorts medical events', () {
    final dog = Dog.fromJson({
      'id': 'dog-1',
      'shelter_id': 'shelter-1',
      'name': 'Milo',
      'slug': 'milo-demo',
      'story': 'Una historia real.',
      'status': 'published',
    });

    final detail = DogDetail.fromJson(
      dog: dog,
      detailsJson: {
        'dog_id': 'dog-1',
        'breed': 'Mestizo mediano',
        'arrival_date': '2026-03-22',
        'ideal_home': 'Un hogar paciente.',
        'dewormed': true,
      },
      medicalEventsJson: [
        {
          'id': 'older',
          'dog_id': 'dog-1',
          'event_date': '2026-03-22',
          'event_type': 'Ingreso',
          'title': 'Evaluación inicial',
        },
        {
          'id': 'newer',
          'dog_id': 'dog-1',
          'event_date': '2026-04-25',
          'event_type': 'Control',
          'title': 'Control de recuperación',
        },
      ],
    );

    expect(detail.breed, 'Mestizo mediano');
    expect(detail.arrivalDate, DateTime(2026, 3, 22));
    expect(detail.dewormed, isTrue);
    expect(detail.medicalEvents.first.id, 'newer');
  });
}
