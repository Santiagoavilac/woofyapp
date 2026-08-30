import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:woofy/core/config/env.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/publisher/data/publisher_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class PublisherRepository {
  Future<List<ShelterMembership>> fetchMyShelterMemberships();

  Future<List<Dog>> fetchShelterDogs(String shelterId);

  Future<Dog> fetchDogById(String dogId);

  Future<Dog> createDog(String shelterId, DogFormData formData);

  Future<Dog> updateDog(String dogId, DogFormData formData);
}

abstract interface class PublisherDataSource {
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> fetchMemberships(String userId);

  Future<List<Map<String, dynamic>>> fetchDogs(String shelterId);

  Future<Map<String, dynamic>?> fetchDog(String dogId);

  Future<Map<String, dynamic>> insertDog(Map<String, dynamic> values);

  Future<Map<String, dynamic>> updateDogFields(
    String dogId,
    Map<String, dynamic> values,
  );
}

class SupabasePublisherDataSource implements PublisherDataSource {
  SupabasePublisherDataSource(this._client);

  static const _dogSelect = '''
    id, shelter_id, name, slug, story, status, species, sex, age_months, size,
    energy_level, sterilized, vaccinated, medical_notes, temperament,
    good_with_children, good_with_dogs, good_with_cats, created_at, updated_at,
    deleted_at
  ''';

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> fetchMemberships(String userId) => _client
      .from('shelter_members')
      .select('id, shelter_id, role, shelters(name)')
      .eq('user_id', userId);

  @override
  Future<List<Map<String, dynamic>>> fetchDogs(String shelterId) => _client
      .from('dogs')
      .select(_dogSelect)
      .eq('shelter_id', shelterId)
      .isFilter('deleted_at', null)
      .order('created_at', ascending: false);

  @override
  Future<Map<String, dynamic>?> fetchDog(String dogId) =>
      _client.from('dogs').select(_dogSelect).eq('id', dogId).maybeSingle();

  @override
  Future<Map<String, dynamic>> insertDog(Map<String, dynamic> values) =>
      _client.from('dogs').insert(values).select(_dogSelect).single();

  @override
  Future<Map<String, dynamic>> updateDogFields(
    String dogId,
    Map<String, dynamic> values,
  ) => _client
      .from('dogs')
      .update(values)
      .eq('id', dogId)
      .select(_dogSelect)
      .single();
}

class SupabasePublisherRepository implements PublisherRepository {
  SupabasePublisherRepository(SupabaseClient client)
    : _source = SupabasePublisherDataSource(client);

  SupabasePublisherRepository.withDataSource(PublisherDataSource source)
    : _source = source;

  final PublisherDataSource _source;

  @override
  Future<List<ShelterMembership>> fetchMyShelterMemberships() async {
    final userId = _requireUserId();
    try {
      final rows = await _source.fetchMemberships(userId);
      return rows.map(ShelterMembership.fromJson).toList();
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw AppException(
        code: 'memberships_load',
        message: 'No pudimos cargar tus refugios.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Dog>> fetchShelterDogs(String shelterId) async {
    _requireUserId();
    try {
      final rows = await _source.fetchDogs(shelterId);
      return rows.map(Dog.fromJson).toList();
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw AppException(
        code: 'publisher_dogs_load',
        message: 'No pudimos cargar los perros del refugio.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Dog> fetchDogById(String dogId) async {
    _requireUserId();
    try {
      final row = await _source.fetchDog(dogId);
      if (row == null) {
        throw const AppException(
          code: 'publisher_dog_not_found',
          message: 'No encontramos ese perro.',
        );
      }
      return Dog.fromJson(row);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw AppException(
        code: 'publisher_dog_load',
        message: 'No pudimos cargar el perro.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Dog> createDog(String shelterId, DogFormData formData) async {
    _requireUserId();
    try {
      final row = await _source.insertDog({
        'shelter_id': shelterId,
        ...formData.toJson(),
      });
      return Dog.fromJson(row);
    } on PostgrestException catch (error, stackTrace) {
      if (error.code == '23505') {
        throw AppException(
          code: 'slug_taken',
          message:
              'Ya existe un perro con ese slug. Elegí otro nombre o cambiá el slug.',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      throw AppException(
        code: 'publisher_dog_create',
        message: 'No pudimos publicar el perro.',
        cause: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw AppException(
        code: 'publisher_dog_create',
        message: 'No pudimos publicar el perro.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Dog> updateDog(String dogId, DogFormData formData) async {
    _requireUserId();
    try {
      final row = await _source.updateDogFields(dogId, formData.toJson());
      return Dog.fromJson(row);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw AppException(
        code: 'publisher_dog_update',
        message: 'No pudimos actualizar el perro.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _requireUserId() {
    final userId = _source.currentUserId;
    if (userId == null) {
      throw const AppException(
        code: 'auth_required',
        message: 'Necesitás iniciar sesión para continuar.',
      );
    }
    return userId;
  }
}

// ── Shelter portal ──────────────────────────────────────────────────────────

abstract interface class ShelterPortalRepository {
  Future<ShelterPortalSession> login(String loginCode, String password);
  Future<void> logout(ShelterPortalSession session);
  Future<ShelterPortalSession> refreshSession(ShelterPortalSession session);
  Future<List<DogDetail>> fetchDogs(ShelterPortalSession session);
  Future<String> saveDog(
    ShelterPortalSession session,
    DogFormData formData, {
    String? dogId,
  });
  Future<void> updateDogStatus(
    ShelterPortalSession session,
    String dogId,
    String status,
  );
  Future<String> uploadDogPhoto(
    ShelterPortalSession session,
    String dogId,
    String filePath,
    String mimeType,
  );
  Future<ShelterPortalSession> updateShelter(
    ShelterPortalSession session,
    ShelterProfileFormData data,
  );
  Future<String> uploadShelterProfileImage(
    ShelterPortalSession session,
    String filePath,
    String mimeType,
  );
  Future<ShelterPortalSession> updateShelterProfileImage(
    ShelterPortalSession session,
    String storagePath,
  );
}

class SupabaseShelterPortalRepository implements ShelterPortalRepository {
  SupabaseShelterPortalRepository(this._client, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final SupabaseClient _client;
  final http.Client _http;

  @override
  Future<ShelterPortalSession> login(String loginCode, String password) async {
    try {
      final data = await _client.rpc(
        'shelter_portal_login',
        params: {'p_login_code': loginCode, 'p_password': password},
      );
      final rows = data as List<dynamic>? ?? [];
      if (rows.isEmpty) {
        throw const AppException(
          code: 'shelter_login_failed',
          message: 'ID o contraseña incorrectos.',
        );
      }
      return ShelterPortalSession.fromJson(
        Map<String, dynamic>.from(rows.first as Map),
      );
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> logout(ShelterPortalSession session) async {
    try {
      await _client.rpc(
        'shelter_portal_logout',
        params: {'p_session_id': session.sessionId, 'p_token': session.token},
      );
    } catch (_) {}
  }

  @override
  Future<ShelterPortalSession> refreshSession(
    ShelterPortalSession session,
  ) async {
    try {
      final data = await _client.rpc(
        'shelter_portal_get_session',
        params: {'p_session_id': session.sessionId, 'p_token': session.token},
      );
      if (data == null) {
        throw const AppException(
          code: 'shelter_session_invalid',
          message: 'Sesión de refugio inválida o expirada.',
        );
      }
      final shelter = (data as Map).cast<String, dynamic>();
      return ShelterPortalSession(
        sessionId: session.sessionId,
        token: session.token,
        expiresAt: session.expiresAt,
        shelterId: shelter['id'] as String? ?? session.shelterId,
        shelterName: shelter['name'] as String? ?? session.shelterName,
        shelterCity: shelter['city'] as String?,
      );
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<List<DogDetail>> fetchDogs(ShelterPortalSession session) async {
    try {
      final data = await _client.rpc(
        'shelter_portal_get_dogs',
        params: {'p_session_id': session.sessionId, 'p_token': session.token},
      );
      final list = data as List<dynamic>? ?? [];
      final storage = _client.storage.from('dog-images');
      return list.map((item) {
        final row = Map<String, dynamic>.from(item as Map);
        final dog = Dog.fromJson(row);
        final photos = dog.photos
            .map(
              (photo) => photo.copyWith(
                publicUrl: storage.getPublicUrl(photo.storagePath),
              ),
            )
            .toList();
        final dogWithUrls = dog.copyWith(photos: photos);
        final detailsRaw = row['dog_details'];
        final eventsRaw = row['dog_medical_events'];
        return DogDetail.fromJson(
          dog: dogWithUrls,
          detailsJson: detailsRaw is Map
              ? Map<String, dynamic>.from(detailsRaw)
              : null,
          medicalEventsJson: eventsRaw is List
              ? List<dynamic>.from(eventsRaw)
              : const [],
        );
      }).toList();
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<String> saveDog(
    ShelterPortalSession session,
    DogFormData formData, {
    String? dogId,
  }) async {
    try {
      final data = await _client.rpc(
        'shelter_portal_save_dog',
        params: {
          'p_session_id': session.sessionId,
          'p_token': session.token,
          'p_dog_id': dogId,
          'p_input': formData.toPortalJson(),
        },
      );
      return data as String;
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> updateDogStatus(
    ShelterPortalSession session,
    String dogId,
    String status,
  ) async {
    try {
      await _client.rpc(
        'shelter_portal_update_dog_status',
        params: {
          'p_session_id': session.sessionId,
          'p_token': session.token,
          'p_dog_id': dogId,
          'p_status': status,
        },
      );
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<String> uploadDogPhoto(
    ShelterPortalSession session,
    String dogId,
    String filePath,
    String mimeType,
  ) async {
    try {
      final storagePath = await _uploadImage(
        session: session,
        kind: 'dog',
        dogId: dogId,
        filePath: filePath,
        mimeType: mimeType,
      );
      await _client.rpc(
        'shelter_portal_register_dog_photo',
        params: {
          'p_session_id': session.sessionId,
          'p_token': session.token,
          'p_dog_id': dogId,
          'p_storage_path': storagePath,
          'p_is_cover': true,
        },
      );
      return storagePath;
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<ShelterPortalSession> updateShelter(
    ShelterPortalSession session,
    ShelterProfileFormData data,
  ) async {
    try {
      final response = await _client.rpc(
        'shelter_portal_update_shelter',
        params: {
          'p_session_id': session.sessionId,
          'p_token': session.token,
          'p_input': data.toJson(),
        },
      );
      final shelter = (response as Map).cast<String, dynamic>();
      return session.copyWith(
        shelterName: shelter['name'] as String? ?? session.shelterName,
        shelterCity: shelter['city'] as String?,
        profileImagePath: shelter['profile_image_path'] as String?,
        description: shelter['description'] as String?,
        phone: shelter['phone'] as String?,
        email: shelter['email'] as String?,
        instagram: shelter['instagram'] as String?,
        facebook: shelter['facebook'] as String?,
        website: shelter['website'] as String?,
        publicContactName: shelter['public_contact_name'] as String?,
        locationNotes: shelter['location_notes'] as String?,
        address: shelter['address'] as String?,
      );
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<String> uploadShelterProfileImage(
    ShelterPortalSession session,
    String filePath,
    String mimeType,
  ) async {
    try {
      return await _uploadImage(
        session: session,
        kind: 'profile',
        filePath: filePath,
        mimeType: mimeType,
      );
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<ShelterPortalSession> updateShelterProfileImage(
    ShelterPortalSession session,
    String storagePath,
  ) async {
    try {
      final response = await _client.rpc(
        'shelter_portal_update_profile_image',
        params: {
          'p_session_id': session.sessionId,
          'p_token': session.token,
          'p_storage_path': storagePath,
        },
      );
      final shelter = (response as Map).cast<String, dynamic>();
      return session.copyWith(
        profileImagePath:
            shelter['profile_image_path'] as String? ?? storagePath,
      );
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  Future<String> _uploadImage({
    required ShelterPortalSession session,
    required String kind,
    required String filePath,
    required String mimeType,
    String? dogId,
  }) async {
    final uri = Uri.parse(
      '${Env.supabaseUrl}/functions/v1/shelter-portal-upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${Env.supabasePublishableKey}'
      ..headers['apikey'] = Env.supabasePublishableKey
      ..fields['session_id'] = session.sessionId
      ..fields['token'] = session.token
      ..fields['kind'] = kind
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType.parse(mimeType),
        ),
      );
    if (dogId != null) request.fields['dog_id'] = dogId;

    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw AppException(
        code: 'photo_upload_failed',
        message: body['error'] as String? ?? 'No pudimos subir la foto.',
      );
    }
    final storagePath = body['storage_path'] as String?;
    if (storagePath == null || storagePath.isEmpty) {
      throw const AppException(
        code: 'photo_upload_failed',
        message: 'La foto se subió pero no recibimos la ruta.',
      );
    }
    return storagePath;
  }

  Map<String, dynamic> _decodeJson(String body) {
    if (body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }
}
