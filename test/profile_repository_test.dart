import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/features/auth/data/auth_models.dart';
import 'package:mi_app/features/auth/data/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const user = AppUser(
    id: 'user-1',
    email: 'ana@example.com',
    fullName: 'Ana Pérez',
    phone: '+59170000000',
  );

  test('returns an existing profile without inserting', () async {
    final source = _FakeProfileDataSource([_profileJson]);
    final repository = SupabaseProfileRepository.withDataSource(source);

    final profile = await repository.ensureCurrentUserProfile(user);

    expect(profile.id, user.id);
    expect(source.insertCalls, isEmpty);
  });

  test('inserts an adopter profile when it is missing', () async {
    final source = _FakeProfileDataSource([null], insertResult: _profileJson);
    final repository = SupabaseProfileRepository.withDataSource(source);

    final profile = await repository.ensureCurrentUserProfile(user);

    expect(profile.role, 'adopter');
    expect(source.insertCalls.single, {
      'id': user.id,
      'email': user.email,
      'full_name': user.fullName,
      'phone': user.phone,
      'role': 'adopter',
    });
  });

  test('selects again when a concurrent insert reports a duplicate', () async {
    final source = _FakeProfileDataSource(
      [null, _profileJson],
      insertError: const PostgrestException(
        message: 'duplicate key',
        code: '23505',
      ),
    );
    final repository = SupabaseProfileRepository.withDataSource(source);

    final profile = await repository.ensureCurrentUserProfile(user);

    expect(profile.id, user.id);
    expect(source.fetchCount, 2);
  });
}

const _profileJson = <String, dynamic>{
  'id': 'user-1',
  'email': 'ana@example.com',
  'full_name': 'Ana Pérez',
  'phone': '+59170000000',
  'role': 'adopter',
};

class _FakeProfileDataSource implements ProfileDataSource {
  _FakeProfileDataSource(
    this.fetchResults, {
    this.insertResult,
    this.insertError,
  });

  final List<Map<String, dynamic>?> fetchResults;
  final Map<String, dynamic>? insertResult;
  final Object? insertError;
  final List<Map<String, dynamic>> insertCalls = [];
  int fetchCount = 0;

  @override
  Future<Map<String, dynamic>?> fetchByUserId(String userId) async {
    final result = fetchResults[fetchCount.clamp(0, fetchResults.length - 1)];
    fetchCount += 1;
    return result;
  }

  @override
  Future<Map<String, dynamic>?> fetchByFullName(String name) async => null;

  @override
  Future<Map<String, dynamic>> insertProfile(
    Map<String, dynamic> values,
  ) async {
    insertCalls.add(values);
    if (insertError case final error?) throw error;
    return insertResult!;
  }

  @override
  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> values,
  ) async {
    return {'id': userId, 'role': 'adopter', ...values};
  }
}
