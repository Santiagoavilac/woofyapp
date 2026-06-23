import 'package:mi_app/core/errors/app_exception.dart';
import 'package:mi_app/core/errors/error_mapper.dart';
import 'package:mi_app/features/auth/data/auth_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> fetchCurrentProfile(AppUser user);

  Future<UserProfile> ensureCurrentUserProfile(AppUser user);
}

abstract interface class ProfileDataSource {
  Future<Map<String, dynamic>?> fetchByUserId(String userId);

  Future<Map<String, dynamic>> insertProfile(Map<String, dynamic> values);
}

class SupabaseProfileDataSource implements ProfileDataSource {
  SupabaseProfileDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchByUserId(String userId) async {
    return _client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> insertProfile(
    Map<String, dynamic> values,
  ) async {
    return _client.from('profiles').insert(values).select().single();
  }
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(SupabaseClient client)
    : _source = SupabaseProfileDataSource(client);

  SupabaseProfileRepository.withDataSource(ProfileDataSource source)
    : _source = source;

  final ProfileDataSource _source;

  @override
  Future<UserProfile?> fetchCurrentProfile(AppUser user) async {
    try {
      final json = await _source.fetchByUserId(user.id);
      return json == null ? null : UserProfile.fromJson(json);
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<UserProfile> ensureCurrentUserProfile(AppUser user) async {
    try {
      final existing = await _source.fetchByUserId(user.id);
      if (existing != null) return UserProfile.fromJson(existing);

      try {
        final inserted = await _source.insertProfile({
          'id': user.id,
          'email': user.email,
          'full_name': _optional(user.fullName),
          'phone': _optional(user.phone),
          'role': 'adopter',
        });
        return UserProfile.fromJson(inserted);
      } on PostgrestException catch (error) {
        if (error.code != '23505') rethrow;
        final concurrent = await _source.fetchByUserId(user.id);
        if (concurrent != null) return UserProfile.fromJson(concurrent);
        throw const AppException(
          code: 'profile_creation',
          message: 'No pudimos crear tu perfil. Intentá nuevamente.',
        );
      }
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  static String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
