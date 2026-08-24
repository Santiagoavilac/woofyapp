import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class FavoritesRepository {
  Future<Set<String>> fetchFavoriteDogIdsForCurrentUser();

  Future<bool> isFavorite(String dogId);

  Future<void> addFavorite(String dogId);

  Future<void> removeFavorite(String dogId);

  Future<bool> toggleFavorite(String dogId);

  Future<List<Dog>> fetchFavoriteDogs();
}

abstract interface class FavoritesDataSource {
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> fetchFavoriteDogIds(String userId);

  Future<Map<String, dynamic>?> fetchFavorite(String userId, String dogId);

  Future<void> insertFavorite(Map<String, dynamic> values);

  Future<void> deleteFavorite(String userId, String dogId);

  Future<List<Map<String, dynamic>>> fetchFavoriteDogs(String userId);

  String getPublicDogPhotoUrl(String storagePath);
}

class SupabaseFavoritesDataSource implements FavoritesDataSource {
  SupabaseFavoritesDataSource(this._client);

  static const _favoriteDogSelect = '''
    created_at,
    dogs!inner(
      id, shelter_id, name, slug, story, sex, age_months, size, energy_level,
      status, sterilized, vaccinated, medical_notes, temperament,
      good_with_children, good_with_dogs, good_with_cats, created_at,
      deleted_at,
      shelters!inner(
        id, name, description, city, address, phone, instagram, verified,
        status, email, facebook, website, profile_image_path,
        public_contact_name, location_notes
      ),
      dog_photos(id, dog_id, storage_path, position, is_cover)
    )
  ''';

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<void> deleteFavorite(String userId, String dogId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('dog_id', dogId);
  }

  @override
  Future<Map<String, dynamic>?> fetchFavorite(String userId, String dogId) =>
      _client
          .from('favorites')
          .select('user_id, dog_id, created_at')
          .eq('user_id', userId)
          .eq('dog_id', dogId)
          .maybeSingle();

  @override
  Future<List<Map<String, dynamic>>> fetchFavoriteDogIds(String userId) =>
      _client
          .from('favorites')
          .select('dog_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

  @override
  Future<List<Map<String, dynamic>>> fetchFavoriteDogs(String userId) => _client
      .from('favorites')
      .select(_favoriteDogSelect)
      .eq('user_id', userId)
      .eq('dogs.status', 'published')
      .isFilter('dogs.deleted_at', null)
      .eq('dogs.shelters.status', 'active')
      .order('created_at', ascending: false)
      .limit(100);

  @override
  String getPublicDogPhotoUrl(String storagePath) =>
      _client.storage.from('dog-images').getPublicUrl(storagePath);

  @override
  Future<void> insertFavorite(Map<String, dynamic> values) async {
    await _client.from('favorites').insert(values);
  }
}

class SupabaseFavoritesRepository implements FavoritesRepository {
  SupabaseFavoritesRepository(SupabaseClient client)
    : _source = SupabaseFavoritesDataSource(client);

  SupabaseFavoritesRepository.withDataSource(FavoritesDataSource source)
    : _source = source;

  final FavoritesDataSource _source;

  @override
  Future<void> addFavorite(String dogId) async {
    final userId = _requireUserId();
    try {
      await _source.insertFavorite({'user_id': userId, 'dog_id': dogId});
    } on PostgrestException catch (error) {
      if (error.code == '23505') return;
      throw _mutationError(error);
    } catch (error, stackTrace) {
      throw _mutationError(error, stackTrace);
    }
  }

  @override
  Future<Set<String>> fetchFavoriteDogIdsForCurrentUser() async {
    final userId = _requireUserId();
    try {
      final rows = await _source.fetchFavoriteDogIds(userId);
      return rows.map((row) => row['dog_id']).whereType<String>().toSet();
    } catch (error, stackTrace) {
      throw _loadError(error, stackTrace);
    }
  }

  @override
  Future<List<Dog>> fetchFavoriteDogs() async {
    final userId = _requireUserId();
    try {
      final rows = await _source.fetchFavoriteDogs(userId);
      return rows.map(_dogFromFavoriteRow).whereType<Dog>().toList();
    } catch (error, stackTrace) {
      throw _loadError(error, stackTrace);
    }
  }

  @override
  Future<bool> isFavorite(String dogId) async {
    final userId = _requireUserId();
    try {
      return await _source.fetchFavorite(userId, dogId) != null;
    } catch (error, stackTrace) {
      throw _loadError(error, stackTrace);
    }
  }

  @override
  Future<void> removeFavorite(String dogId) async {
    final userId = _requireUserId();
    try {
      await _source.deleteFavorite(userId, dogId);
    } catch (error, stackTrace) {
      throw _mutationError(error, stackTrace);
    }
  }

  @override
  Future<bool> toggleFavorite(String dogId) async {
    final active = await isFavorite(dogId);
    if (active) {
      await removeFavorite(dogId);
      return false;
    }
    await addFavorite(dogId);
    return true;
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

  Dog? _dogFromFavoriteRow(Map<String, dynamic> row) {
    final value = row['dogs'];
    final json = switch (value) {
      Map<String, dynamic>() => value,
      List<dynamic>() when value.isNotEmpty =>
        (value.first as Map).cast<String, dynamic>(),
      _ => null,
    };
    if (json == null) return null;
    final dog = Dog.fromJson(json);
    return dog.copyWith(
      photos: dog.photos
          .map(
            (photo) => photo.copyWith(
              publicUrl: _source.getPublicDogPhotoUrl(photo.storagePath),
            ),
          )
          .toList(),
    );
  }

  AppException _loadError(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;
    return AppException(
      code: 'favorites_load',
      message: 'No pudimos cargar tus favoritos.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  AppException _mutationError(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;
    return AppException(
      code: 'favorites_mutation',
      message: 'No pudimos guardar este perrito.',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
