import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> fetchCurrentProfile(AppUser user);

  Future<UserProfile> ensureCurrentUserProfile(AppUser user);

  Future<String?> fetchEmailByFullName(String name);

  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  });
}

abstract interface class ProfileDataSource {
  Future<Map<String, dynamic>?> fetchByUserId(String userId);

  Future<Map<String, dynamic>?> fetchByFullName(String name);

  Future<Map<String, dynamic>> insertProfile(Map<String, dynamic> values);

  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> values,
  );
}

class SupabaseProfileDataSource implements ProfileDataSource {
  SupabaseProfileDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchByUserId(String userId) async {
    return _client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  @override
  Future<Map<String, dynamic>?> fetchByFullName(String name) async {
    final email =
        await _client.rpc(
              'lookup_email_by_username',
              params: {'username': name.trim()},
            )
            as String?;
    if (email == null || email.isEmpty) return null;
    return {'email': email};
  }

  @override
  Future<Map<String, dynamic>> insertProfile(
    Map<String, dynamic> values,
  ) async {
    return _client.from('profiles').insert(values).select().single();
  }

  @override
  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> values,
  ) async {
    return _client
        .from('profiles')
        .update(values)
        .eq('id', userId)
        .select()
        .single();
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
  Future<String?> fetchEmailByFullName(String name) async {
    try {
      final json = await _source.fetchByFullName(name);
      return json?['email'] as String?;
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

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async {
    try {
      final values = <String, dynamic>{};
      if (fullName != null) values['full_name'] = _optional(fullName);
      if (phone != null) values['phone'] = _optional(phone);
      if (values.isEmpty) {
        final current = await _source.fetchByUserId(userId);
        if (current == null) {
          throw const AppException(
            code: 'profile_missing',
            message: 'No encontramos tu perfil.',
          );
        }
        return UserProfile.fromJson(current);
      }
      final row = await _source.updateProfile(userId, values);
      return UserProfile.fromJson(row);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  static String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
