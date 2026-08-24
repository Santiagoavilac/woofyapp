import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/services/secure_storage_service.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/publisher/data/publisher_models.dart';
import 'package:woofy/features/publisher/data/publisher_repository.dart';

// ── Legacy adopter publisher (still used for shelter-member detection) ──────

final publisherRepositoryProvider = Provider<PublisherRepository>(
  (ref) => SupabasePublisherRepository(ref.watch(supabaseClientProvider)),
);

final myShelterMembershipsProvider = FutureProvider<List<ShelterMembership>>((
  ref,
) async {
  if (ref.watch(currentUserProvider) == null) return const [];
  return ref.watch(publisherRepositoryProvider).fetchMyShelterMemberships();
});

// ── Shelter portal ──────────────────────────────────────────────────────────

const _shelterSessionKey = 'woofy_shelter_portal_session';

final shelterPortalRepositoryProvider = Provider<ShelterPortalRepository>(
  (ref) => SupabaseShelterPortalRepository(ref.watch(supabaseClientProvider)),
);

final shelterPortalSessionProvider =
    AsyncNotifierProvider<ShelterPortalNotifier, ShelterPortalSession?>(
      ShelterPortalNotifier.new,
    );

class ShelterPortalNotifier extends AsyncNotifier<ShelterPortalSession?> {
  @override
  Future<ShelterPortalSession?> build() async {
    final storage = ref.read(secureStorageServiceProvider);
    ShelterPortalSession? stored;
    try {
      final raw = await storage.read(_shelterSessionKey);
      if (raw == null) return null;
      stored = ShelterPortalSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (error, stack) {
      debugPrint('shelter_portal: no se pudo leer secure_storage: $error');
      debugPrintStack(stackTrace: stack);
      try {
        await storage.delete(_shelterSessionKey);
      } catch (_) {}
      return null;
    }

    unawaited(_refreshInBackground(stored));
    return stored;
  }

  Future<void> _refreshInBackground(ShelterPortalSession stored) async {
    try {
      final refreshed = await ref
          .read(shelterPortalRepositoryProvider)
          .refreshSession(stored);
      await ref.read(secureStorageServiceProvider).write(
        _shelterSessionKey,
        jsonEncode(refreshed.toJson()),
      );
      state = AsyncData(refreshed);
    } on AppException catch (error) {
      if (_isSessionInvalid(error)) {
        debugPrint(
          'shelter_portal: sesión inválida en server (${error.code}), '
          'cerrando sesión local.',
        );
        await ref.read(secureStorageServiceProvider).delete(_shelterSessionKey);
        state = const AsyncData(null);
      } else {
        debugPrint(
          'shelter_portal: refresh transitorio: ${error.code} ${error.message}',
        );
      }
    } catch (error, stack) {
      debugPrint('shelter_portal: refresh error inesperado: $error');
      debugPrintStack(stackTrace: stack);
    }
  }

  bool _isSessionInvalid(AppException error) {
    return error.code == 'shelter_session_invalid' ||
        error.code == 'shelter_session_expired' ||
        error.code == 'not_authorized';
  }

  Future<void> login(String loginCode, String password) async {
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(shelterPortalRepositoryProvider)
          .login(loginCode.trim(), password);
      await ref.read(secureStorageServiceProvider).write(
        _shelterSessionKey,
        jsonEncode(session.toJson()),
      );
      state = AsyncData(session);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    final current = state.value;
    await ref.read(secureStorageServiceProvider).delete(_shelterSessionKey);
    state = const AsyncData(null);
    if (current != null) {
      try {
        await ref.read(shelterPortalRepositoryProvider).logout(current);
      } catch (_) {}
    }
  }

  Future<void> updateProfile(ShelterProfileFormData data) async {
    final current = state.value;
    if (current == null) return;
    final updated = await ref
        .read(shelterPortalRepositoryProvider)
        .updateShelter(current, data);
    await ref.read(secureStorageServiceProvider).write(
      _shelterSessionKey,
      jsonEncode(updated.toJson()),
    );
    state = AsyncData(updated);
  }

  Future<void> updateProfileImage(String filePath, String mimeType) async {
    final current = state.value;
    if (current == null) return;
    final repo = ref.read(shelterPortalRepositoryProvider);
    final path = await repo.uploadShelterProfileImage(
      current,
      filePath,
      mimeType,
    );
    final updated = await repo.updateShelterProfileImage(current, path);
    await ref.read(secureStorageServiceProvider).write(
      _shelterSessionKey,
      jsonEncode(updated.toJson()),
    );
    state = AsyncData(updated);
  }
}

final shelterPortalDogsProvider = FutureProvider<List<DogDetail>>((ref) async {
  final session = await ref.watch(shelterPortalSessionProvider.future);
  if (session == null) return const [];
  return ref.read(shelterPortalRepositoryProvider).fetchDogs(session);
});

final shelterPortalDogByIdProvider = FutureProvider.family<DogDetail?, String>((
  ref,
  dogId,
) async {
  final dogs = await ref.watch(shelterPortalDogsProvider.future);
  try {
    return dogs.firstWhere((d) => d.dog.id == dogId);
  } catch (_) {
    return null;
  }
});
