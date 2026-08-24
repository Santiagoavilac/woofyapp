import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/features/auth/data/auth_models.dart';
import 'package:mi_app/features/legal/data/account_deletion_repository.dart';

void main() {
  const user = AppUser(id: 'user-1', email: 'ana@example.com');

  test('inserts a deletion request with user id and email', () async {
    final source = _FakeAccountDeletionDataSource();
    final repository = SupabaseAccountDeletionRepository.withDataSource(source);

    await repository.requestDeletion(user);

    expect(source.inserted.single, {
      'user_id': 'user-1',
      'email': 'ana@example.com',
      'reason': null,
    });
  });

  test('normalizes a blank reason to null', () async {
    final source = _FakeAccountDeletionDataSource();
    final repository = SupabaseAccountDeletionRepository.withDataSource(source);

    await repository.requestDeletion(user, reason: '   ');

    expect(source.inserted.single['reason'], isNull);
  });

  test('keeps a provided reason', () async {
    final source = _FakeAccountDeletionDataSource();
    final repository = SupabaseAccountDeletionRepository.withDataSource(source);

    await repository.requestDeletion(user, reason: 'Ya no lo uso');

    expect(source.inserted.single['reason'], 'Ya no lo uso');
  });
}

class _FakeAccountDeletionDataSource implements AccountDeletionDataSource {
  final List<Map<String, dynamic>> inserted = [];

  @override
  Future<void> insertRequest(Map<String, dynamic> values) async {
    inserted.add(values);
  }
}
