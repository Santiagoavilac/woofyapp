import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class DogRepository {
  Future<List<Dog>> fetchPublishedDogs();

  Future<DogDetail?> fetchPublishedDogBySlug(String slug);
}

class SupabaseDogRepository implements DogRepository {
  SupabaseDogRepository(this._client);

  static const _dogFields = '''
    id, shelter_id, name, slug, story, sex, age_months, size, energy_level,
    status, sterilized, vaccinated, medical_notes, temperament,
    good_with_children, good_with_dogs, good_with_cats, created_at, deleted_at,
    shelters!inner(
      id, name, description, city, address, phone, instagram, verified, status,
      email, facebook, website, profile_image_path, public_contact_name,
      location_notes
    ),
    dog_photos(id, dog_id, storage_path, position, is_cover)
  ''';

  final SupabaseClient _client;

  @override
  Future<List<Dog>> fetchPublishedDogs() async {
    try {
      final response = await _client
          .from('dogs')
          .select(_dogFields)
          .eq('status', 'published')
          .isFilter('deleted_at', null)
          .eq('shelters.status', 'active')
          .order('created_at', ascending: false)
          .limit(100);

      return Future.wait(
        response.map((json) => _withPublicPhotoUrls(Dog.fromJson(json))),
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<DogDetail?> fetchPublishedDogBySlug(String slug) async {
    try {
      final response = await _client
          .from('dogs')
          .select(_dogFields)
          .eq('slug', slug)
          .eq('status', 'published')
          .isFilter('deleted_at', null)
          .eq('shelters.status', 'active')
          .maybeSingle();
      if (response == null) return null;

      final dog = await _withPublicPhotoUrls(Dog.fromJson(response));
      final related = await Future.wait<dynamic>([
        _client
            .from('dog_details')
            .select('''
              dog_id, arrival_date, arrival_condition, rescue_context,
              found_location, breed, breed_notes, mother_known, mother_breed,
              mother_notes, father_known, father_breed, father_notes,
              health_on_arrival, known_conditions, current_treatment,
              dewormed, deworming_date, special_care, feeding_notes,
              behavior_notes, ideal_home, extra_notes
            ''')
            .eq('dog_id', dog.id)
            .maybeSingle(),
        _client
            .from('dog_medical_events')
            .select('id, dog_id, event_date, event_type, title, description')
            .eq('dog_id', dog.id)
            .order('event_date', ascending: false),
      ]);

      return DogDetail.fromJson(
        dog: dog,
        detailsJson: related[0] as Map<String, dynamic>?,
        medicalEventsJson: related[1] as List<dynamic>,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  Future<Dog> _withPublicPhotoUrls(Dog dog) async {
    final photos = dog.photos
        .map(
          (photo) => photo.copyWith(
            publicUrl: _client.storage
                .from('dog-images')
                .getPublicUrl(photo.storagePath),
          ),
        )
        .toList();
    return dog.copyWith(photos: photos);
  }
}
