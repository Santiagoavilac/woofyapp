import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/errors/error_mapper.dart';

/// Un refugio bloqueado por el usuario actual.
class BlockedShelter {
  const BlockedShelter({
    required this.id,
    required this.shelterId,
    required this.shelterName,
    this.createdAt,
  });

  factory BlockedShelter.fromJson(Map<String, dynamic> json) {
    final shelter = json['shelters'] as Map<String, dynamic>?;
    return BlockedShelter(
      id: json['id'] as String,
      shelterId: json['blocked_shelter_id'] as String,
      shelterName: shelter?['name'] as String? ?? 'Refugio',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  final String id;
  final String shelterId;
  final String shelterName;
  final DateTime? createdAt;
}

abstract interface class BlocksRepository {
  Future<List<BlockedShelter>> fetchBlockedShelters();

  Future<void> blockShelter(String shelterId, {String? reason});

  Future<void> unblockShelter(String shelterId);
}

abstract interface class BlocksDataSource {
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> fetchBlocks(String userId);

  Future<void> insertBlock(Map<String, dynamic> values);

  Future<void> deleteBlock(String userId, String shelterId);
}

class SupabaseBlocksDataSource implements BlocksDataSource {
  SupabaseBlocksDataSource(this._client);

  static const _table = 'blocked_parties';

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> fetchBlocks(String userId) => _client
      .from(_table)
      .select('id, blocked_shelter_id, created_at, shelters(name)')
      .eq('blocker_user_id', userId)
      .not('blocked_shelter_id', 'is', null)
      .order('created_at', ascending: false);

  @override
  Future<void> insertBlock(Map<String, dynamic> values) async {
    await _client.from(_table).insert(values);
  }

  @override
  Future<void> deleteBlock(String userId, String shelterId) async {
    await _client
        .from(_table)
        .delete()
        .eq('blocker_user_id', userId)
        .eq('blocked_shelter_id', shelterId);
  }
}

class SupabaseBlocksRepository implements BlocksRepository {
  SupabaseBlocksRepository(SupabaseClient client)
    : _source = SupabaseBlocksDataSource(client);

  SupabaseBlocksRepository.withDataSource(this._source);

  final BlocksDataSource _source;

  @override
  Future<List<BlockedShelter>> fetchBlockedShelters() async {
    try {
      final userId = _requireUser();
      final rows = await _source.fetchBlocks(userId);
      return rows.map(BlockedShelter.fromJson).toList();
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> blockShelter(String shelterId, {String? reason}) async {
    try {
      final userId = _requireUser();
      await _source.insertBlock({
        'blocker_user_id': userId,
        'blocked_shelter_id': shelterId,
        'reason': ?_optional(reason),
      });
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> unblockShelter(String shelterId) async {
    try {
      await _source.deleteBlock(_requireUser(), shelterId);
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  String _requireUser() {
    final userId = _source.currentUserId;
    if (userId == null) {
      throw const AppException(
        code: 'block_requires_session',
        message: 'Iniciá sesión para administrar tus bloqueos.',
      );
    }
    return userId;
  }

  static String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
