import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AccountDeletionRepository {
  Future<void> requestDeletion(AppUser user, {String? reason});
}

abstract interface class AccountDeletionDataSource {
  Future<void> insertRequest(Map<String, dynamic> values);
}

class SupabaseAccountDeletionDataSource implements AccountDeletionDataSource {
  SupabaseAccountDeletionDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> insertRequest(Map<String, dynamic> values) async {
    await _client.from('account_deletion_requests').insert(values);
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
  Future<void> requestDeletion(AppUser user, {String? reason}) async {
    try {
      await _source.insertRequest({
        'user_id': user.id,
        'email': user.email,
        'reason': _optional(reason),
      });
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  static String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
