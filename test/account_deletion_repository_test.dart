import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/legal/data/account_deletion_repository.dart';

void main() {
  test('deletion without an Apple account sends no authorization code', () async {
    final source = _FakeAccountDeletionDataSource();
    final repository = SupabaseAccountDeletionRepository.withDataSource(source);

    await repository.deleteAccount();

    expect(source.calls.single, isEmpty);
  });

  test('an Apple account forwards its authorization code', () async {
    final source = _FakeAccountDeletionDataSource();
    final repository = SupabaseAccountDeletionRepository.withDataSource(source);

    await repository.deleteAccount(appleAuthorizationCode: 'code-123');

    expect(source.calls.single['apple_authorization_code'], 'code-123');
  });

  test('blank values are dropped instead of sent empty', () async {
    final source = _FakeAccountDeletionDataSource();
    final repository = SupabaseAccountDeletionRepository.withDataSource(source);

    await repository.deleteAccount(appleAuthorizationCode: '  ', reason: '   ');

    expect(source.calls.single, isEmpty);
  });

  test('a reason is forwarded when present', () async {
    final source = _FakeAccountDeletionDataSource();
    final repository = SupabaseAccountDeletionRepository.withDataSource(source);

    await repository.deleteAccount(reason: 'Ya no lo uso');

    expect(source.calls.single['reason'], 'Ya no lo uso');
  });

  test('a response without confirmation is treated as a failure', () async {
    // Es el caso peligroso: si diéramos por buena una respuesta ambigua, la
    // app diría "cuenta eliminada" con la cuenta todavía viva.
    final source = _FakeAccountDeletionDataSource(
      result: {'error': 'No pudimos revocar el acceso con Apple.'},
    );
    final repository = SupabaseAccountDeletionRepository.withDataSource(source);

    await expectLater(
      repository.deleteAccount(),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          'No pudimos revocar el acceso con Apple.',
        ),
      ),
    );
  });

  test('an empty response is also a failure', () async {
    final source = _FakeAccountDeletionDataSource(result: null);
    final repository = SupabaseAccountDeletionRepository.withDataSource(source);

    await expectLater(repository.deleteAccount(), throwsA(isA<AppException>()));
  });
}

class _FakeAccountDeletionDataSource implements AccountDeletionDataSource {
  _FakeAccountDeletionDataSource({this.result = const {'deleted': true}});

  final Map<String, dynamic>? result;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<Map<String, dynamic>?> invokeDeletion(
    Map<String, dynamic> body,
  ) async {
    calls.add(body);
    return result;
  }
}
