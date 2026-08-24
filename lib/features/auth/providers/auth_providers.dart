import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/core/services/supabase_service.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/data/auth_repository.dart';
import 'package:woofy/features/auth/data/profile_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
);

final authStateProvider = StreamProvider<AppUser?>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  yield repository.currentUser;
  yield* repository.authStateChanges;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).value ??
      ref.watch(authRepositoryProvider).currentUser;
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).fetchCurrentProfile(user);
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  String? _ensuredProfileUserId;
  String? _ensuringProfileUserId;
  Future<void>? _profileSyncFuture;

  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      String resolvedEmail = email.trim();
      if (!resolvedEmail.contains('@')) {
        final found = await ref
            .read(profileRepositoryProvider)
            .fetchEmailByFullName(resolvedEmail);
        if (found == null || found.isEmpty) {
          throw const AppException(
            code: 'user_not_found',
            message: 'No encontramos un usuario con ese nombre.',
          );
        }
        resolvedEmail = found;
      }
      final user = await ref
          .read(authRepositoryProvider)
          .signInWithEmailAndPassword(email: resolvedEmail, password: password);
      await ensureAuthenticatedProfile(user);
    } catch (error, stackTrace) {
      state = AsyncError(ErrorMapper.map(error, stackTrace), stackTrace);
      rethrow;
    }
  }

  Future<RegistrationResult> register({
    required String fullName,
    required String? phone,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .signUpWithEmailAndPassword(
            fullName: fullName,
            phone: phone,
            email: email,
            password: password,
          );
      if (!result.requiresEmailConfirmation) {
        await ensureAuthenticatedProfile(result.user);
      }
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(ErrorMapper.map(error, stackTrace), stackTrace);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(ErrorMapper.map(error, stackTrace), stackTrace);
      rethrow;
    }
  }

  Future<void> ensureAuthenticatedProfile(AppUser user) {
    if (_ensuredProfileUserId == user.id) return Future.value();
    if (_ensuringProfileUserId == user.id && _profileSyncFuture != null) {
      return _profileSyncFuture!;
    }

    _ensuringProfileUserId = user.id;
    final operation = _ensureAuthenticatedProfile(user);
    _profileSyncFuture = operation;
    return operation.whenComplete(() {
      if (identical(_profileSyncFuture, operation)) {
        _ensuringProfileUserId = null;
        _profileSyncFuture = null;
      }
    });
  }

  Future<void> _ensureAuthenticatedProfile(AppUser user) async {
    state = const AsyncLoading();
    try {
      await ref.read(profileRepositoryProvider).ensureCurrentUserProfile(user);
      _ensuredProfileUserId = user.id;
      ref.invalidate(currentProfileProvider);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(ErrorMapper.map(error, stackTrace), stackTrace);
      rethrow;
    }
  }

  Future<void> ensureCurrentProfile() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    state = const AsyncLoading();
    try {
      _ensuredProfileUserId = null;
      await ensureAuthenticatedProfile(user);
    } catch (error, stackTrace) {
      state = AsyncError(ErrorMapper.map(error, stackTrace), stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      _ensuredProfileUserId = null;
      _ensuringProfileUserId = null;
      _profileSyncFuture = null;
      ref.invalidate(currentProfileProvider);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(ErrorMapper.map(error, stackTrace), stackTrace);
      rethrow;
    }
  }

  Future<void> updateProfile({String? fullName, String? phone}) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw const AppException(
          code: 'auth_required',
          message: 'Necesitás iniciar sesión.',
        );
      }
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(userId: user.id, fullName: fullName, phone: phone);
      ref.invalidate(currentProfileProvider);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(
        error is AppException ? error : ErrorMapper.map(error, stackTrace),
        stackTrace,
      );
      rethrow;
    }
  }
}
