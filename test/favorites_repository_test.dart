import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/core/errors/app_exception.dart';
import 'package:mi_app/features/favorites/data/favorites_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('favorite IDs are scoped to the authenticated user', () async {
    final source = _FakeFavoritesDataSource(
      currentUserId: 'user-1',
      favoriteRows: const [
        {'dog_id': 'dog-1'},
        {'dog_id': 'dog-2'},
      ],
    );
    final repository = SupabaseFavoritesRepository.withDataSource(source);

    final result = await repository.fetchFavoriteDogIdsForCurrentUser();

    expect(result, {'dog-1', 'dog-2'});
    expect(source.lastUserId, 'user-1');
  });

  test('adding an existing favorite is idempotent', () async {
    final source = _FakeFavoritesDataSource(currentUserId: 'user-1')
      ..insertError = const PostgrestException(
        message: 'duplicate',
        code: '23505',
      );
    final repository = SupabaseFavoritesRepository.withDataSource(source);

    await repository.addFavorite('dog-1');

    expect(source.inserted, {'user_id': 'user-1', 'dog_id': 'dog-1'});
  });

  test('toggle removes an existing favorite', () async {
    final source = _FakeFavoritesDataSource(
      currentUserId: 'user-1',
      existing: const {'user_id': 'user-1', 'dog_id': 'dog-1'},
    );
    final repository = SupabaseFavoritesRepository.withDataSource(source);

    final active = await repository.toggleFavorite('dog-1');

    expect(active, isFalse);
    expect(source.deleted, ('user-1', 'dog-1'));
  });

  test('favorites require an authenticated user', () async {
    final repository = SupabaseFavoritesRepository.withDataSource(
      _FakeFavoritesDataSource(),
    );

    await expectLater(
      repository.addFavorite('dog-1'),
      throwsA(
        isA<AppException>()
            .having((error) => error.code, 'code', 'auth_required')
            .having(
              (error) => error.message,
              'message',
              'Necesitás iniciar sesión para continuar.',
            ),
      ),
    );
  });
}

class _FakeFavoritesDataSource implements FavoritesDataSource {
  _FakeFavoritesDataSource({
    this.currentUserId,
    this.favoriteRows = const [],
    this.existing,
  });

  @override
  final String? currentUserId;
  final List<Map<String, dynamic>> favoriteRows;
  final Map<String, dynamic>? existing;
  Object? insertError;
  String? lastUserId;
  Map<String, dynamic>? inserted;
  (String, String)? deleted;

  @override
  Future<void> deleteFavorite(String userId, String dogId) async {
    deleted = (userId, dogId);
  }

  @override
  Future<Map<String, dynamic>?> fetchFavorite(
    String userId,
    String dogId,
  ) async {
    lastUserId = userId;
    return existing;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFavoriteDogIds(String userId) async {
    lastUserId = userId;
    return favoriteRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFavoriteDogs(String userId) async {
    lastUserId = userId;
    return const [];
  }

  @override
  String getPublicDogPhotoUrl(String storagePath) => 'public/$storagePath';

  @override
  Future<void> insertFavorite(Map<String, dynamic> values) async {
    inserted = values;
    if (insertError case final error?) throw error;
  }
}
