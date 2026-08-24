import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AccountDeletionRepository {
  /// Elimina la cuenta y sus datos de forma definitiva.
  ///
  /// [appleAuthorizationCode] es obligatorio para cuentas creadas con Apple:
  /// la función revoca los tokens antes de borrar, como exige Apple, y falla
  /// si no puede hacerlo.
  Future<void> deleteAccount({String? appleAuthorizationCode, String? reason});
}

abstract interface class AccountDeletionDataSource {
  Future<Map<String, dynamic>?> invokeDeletion(Map<String, dynamic> body);
}

class SupabaseAccountDeletionDataSource implements AccountDeletionDataSource {
  SupabaseAccountDeletionDataSource(this._client);

  static const functionName = 'delete-account';

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> invokeDeletion(
    Map<String, dynamic> body,
  ) async {
    final response = await _client.functions.invoke(functionName, body: body);
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }
}

class SupabaseAccountDeletionRepository implements AccountDeletionRepository {
  SupabaseAccountDeletionRepository(SupabaseClient client)
    : _source = SupabaseAccountDeletionDataSource(client);

  SupabaseAccountDeletionRepository.withDataSource(
    AccountDeletionDataSource source,
  ) : _source = source;

  final AccountDeletionDataSource _source;

  @override
  Future<void> deleteAccount({
    String? appleAuthorizationCode,
    String? reason,
  }) async {
    try {
      final result = await _source.invokeDeletion({
        'apple_authorization_code': ?_optional(appleAuthorizationCode),
        'reason': ?_optional(reason),
      });

      // La función responde 200 con {deleted:true}. Cualquier otra forma
      // significa que algo se interrumpió y la cuenta sigue viva.
      if (result?['deleted'] != true) {
        throw AppException(
          code: 'account_deletion',
          message:
              result?['error'] as String? ??
              'No pudimos eliminar la cuenta. Intentá de nuevo.',
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
