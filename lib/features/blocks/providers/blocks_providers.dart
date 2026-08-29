import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/blocks/data/blocks_repository.dart';
import 'package:woofy/features/messages/data/messages_providers.dart';

final blocksRepositoryProvider = Provider<BlocksRepository>(
  (ref) => SupabaseBlocksRepository(ref.watch(supabaseClientProvider)),
);

final blockedSheltersProvider = FutureProvider<List<BlockedShelter>>((
  ref,
) async {
  if (ref.watch(currentUserProvider) == null) {
    return const <BlockedShelter>[];
  }
  return ref.watch(blocksRepositoryProvider).fetchBlockedShelters();
});

final blockControllerProvider = AsyncNotifierProvider<BlockController, void>(
  BlockController.new,
);

class BlockController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> blockShelter(String shelterId, {String? reason}) => _run(
    () => ref
        .read(blocksRepositoryProvider)
        .blockShelter(shelterId, reason: reason),
  );

  Future<void> unblockShelter(String shelterId) =>
      _run(() => ref.read(blocksRepositoryProvider).unblockShelter(shelterId));

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      // El bloqueo saca el hilo de la bandeja, así que hay que releerla.
      ref.invalidate(blockedSheltersProvider);
      ref.invalidate(myThreadsProvider);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(ErrorMapper.map(error, stackTrace), stackTrace);
      rethrow;
    }
  }
}
