import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/blocks/data/blocks_repository.dart';

void main() {
  test('blocking records the blocker and the shelter', () async {
    final source = _FakeBlocksDataSource();
    final repository = SupabaseBlocksRepository.withDataSource(source);

    await repository.blockShelter('shelter-1');

    expect(source.inserted.single, {
      'blocker_user_id': 'user-1',
      'blocked_shelter_id': 'shelter-1',
    });
  });

  test('a blank reason is dropped instead of stored empty', () async {
    final source = _FakeBlocksDataSource();
    final repository = SupabaseBlocksRepository.withDataSource(source);

    await repository.blockShelter('shelter-1', reason: '  ');

    expect(source.inserted.single.containsKey('reason'), isFalse);
  });

  test('a reason is kept when present', () async {
    final source = _FakeBlocksDataSource();
    final repository = SupabaseBlocksRepository.withDataSource(source);

    await repository.blockShelter('shelter-1', reason: ' Me insultó ');

    expect(source.inserted.single['reason'], 'Me insultó');
  });

  test('unblocking targets the pair, not the whole table', () async {
    final source = _FakeBlocksDataSource();
    final repository = SupabaseBlocksRepository.withDataSource(source);

    await repository.unblockShelter('shelter-1');

    expect(source.deleted.single, ('user-1', 'shelter-1'));
  });

  test('the blocked list resolves the shelter name', () async {
    final source = _FakeBlocksDataSource(
      blocks: [
        {
          'id': 'block-1',
          'blocked_shelter_id': 'shelter-1',
          'created_at': '2026-08-24T10:00:00Z',
          'shelters': {'name': 'Patitas Felices'},
        },
      ],
    );
    final repository = SupabaseBlocksRepository.withDataSource(source);

    final blocked = await repository.fetchBlockedShelters();

    expect(blocked.single.shelterId, 'shelter-1');
    expect(blocked.single.shelterName, 'Patitas Felices');
  });

  test('a block without a joined shelter still renders', () async {
    // El join puede venir vacío si el refugio fue borrado; la pantalla de
    // bloqueados no debería romperse por eso.
    final source = _FakeBlocksDataSource(
      blocks: [
        {'id': 'block-1', 'blocked_shelter_id': 'shelter-1'},
      ],
    );
    final repository = SupabaseBlocksRepository.withDataSource(source);

    final blocked = await repository.fetchBlockedShelters();

    expect(blocked.single.shelterName, 'Refugio');
    expect(blocked.single.createdAt, isNull);
  });

  test('blocking without a session fails before writing', () async {
    final source = _FakeBlocksDataSource(userId: null);
    final repository = SupabaseBlocksRepository.withDataSource(source);

    await expectLater(
      repository.blockShelter('shelter-1'),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          'block_requires_session',
        ),
      ),
    );
    expect(source.inserted, isEmpty);
  });
}

class _FakeBlocksDataSource implements BlocksDataSource {
  _FakeBlocksDataSource({
    this.userId = 'user-1',
    this.blocks = const <Map<String, dynamic>>[],
  });

  final String? userId;
  final List<Map<String, dynamic>> blocks;
  final List<Map<String, dynamic>> inserted = [];
  final List<(String, String)> deleted = [];

  @override
  String? get currentUserId => userId;

  @override
  Future<List<Map<String, dynamic>>> fetchBlocks(String userId) async => blocks;

  @override
  Future<void> insertBlock(Map<String, dynamic> values) async {
    inserted.add(values);
  }

  @override
  Future<void> deleteBlock(String userId, String shelterId) async {
    deleted.add((userId, shelterId));
  }
}
