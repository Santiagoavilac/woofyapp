import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/data/auth_repository.dart';
import 'package:woofy/features/auth/data/profile_repository.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';

void main() {
  const user = AppUser(
    id: 'user-1',
    email: 'ana@example.com',
    fullName: 'Ana Pérez',
  );

  test('login ensures the adopter profile', () async {
    final auth = _FakeAuthRepository(user: user);
    final profiles = _FakeProfileRepository();
    final container = _container(auth, profiles);
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .signIn(email: user.email, password: 'secreto1');

    expect(profiles.ensuredUsers, [user]);
  });

  test('registration with a session ensures the profile', () async {
    final auth = _FakeAuthRepository(
      user: user,
      registrationResult: const RegistrationResult(
        user: user,
        requiresEmailConfirmation: false,
      ),
    );
    final profiles = _FakeProfileRepository();
    final container = _container(auth, profiles);
    addTearDown(container.dispose);

    final result = await container
        .read(authControllerProvider.notifier)
        .register(
          fullName: 'Ana Pérez',
          phone: null,
          email: user.email,
          password: 'secreto1',
        );

    expect(result.requiresEmailConfirmation, isFalse);
    expect(profiles.ensuredUsers, [user]);
  });

  test('pending email confirmation does not try to create a profile', () async {
    final auth = _FakeAuthRepository(
      user: user,
      registrationResult: const RegistrationResult(
        user: user,
        requiresEmailConfirmation: true,
      ),
    );
    final profiles = _FakeProfileRepository();
    final container = _container(auth, profiles);
    addTearDown(container.dispose);

    final result = await container
        .read(authControllerProvider.notifier)
        .register(
          fullName: 'Ana Pérez',
          phone: '+59170000000',
          email: user.email,
          password: 'secreto1',
        );

    expect(result.requiresEmailConfirmation, isTrue);
    expect(profiles.ensuredUsers, isEmpty);
  });

  test('logout delegates to auth and clears profile state', () async {
    final auth = _FakeAuthRepository(user: user);
    final profiles = _FakeProfileRepository();
    final container = _container(auth, profiles);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).signOut();

    expect(auth.signOutCalls, 1);
  });

  test('Google login delegates to the auth repository', () async {
    final auth = _FakeAuthRepository(user: user);
    final profiles = _FakeProfileRepository();
    final container = _container(auth, profiles);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).signInWithGoogle();

    expect(auth.googleSignInCalls, 1);
  });

  test('Google login surfaces repository errors', () async {
    final auth = _FakeAuthRepository(
      user: user,
      googleSignInError: const AppException(
        code: 'google_oauth_failed',
        message: 'No pudimos iniciar sesión con Google.',
      ),
    );
    final profiles = _FakeProfileRepository();
    final container = _container(auth, profiles);
    addTearDown(container.dispose);

    await expectLater(
      container.read(authControllerProvider.notifier).signInWithGoogle(),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'google_oauth_failed',
        ),
      ),
    );

    expect(auth.googleSignInCalls, 1);
    expect(profiles.ensuredUsers, isEmpty);
  });

  test(
    'authenticated profile synchronization is deduplicated by user',
    () async {
      final profiles = _FakeProfileRepository();
      final container = _container(_FakeAuthRepository(user: user), profiles);
      addTearDown(container.dispose);
      final controller = container.read(authControllerProvider.notifier);

      await Future.wait([
        controller.ensureAuthenticatedProfile(user),
        controller.ensureAuthenticatedProfile(user),
      ]);
      await controller.ensureAuthenticatedProfile(user);

      expect(profiles.ensuredUsers, [user]);
    },
  );
}

ProviderContainer _container(AuthRepository auth, ProfileRepository profiles) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(profiles),
    ],
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    required this.user,
    this.registrationResult,
    this.googleSignInError,
  });

  final AppUser? user;
  final RegistrationResult? registrationResult;
  final Object? googleSignInError;
  int signOutCalls = 0;
  int googleSignInCalls = 0;

  @override
  AppUser? get currentUser => user;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<void> signInWithGoogle() async {
    googleSignInCalls += 1;
    if (googleSignInError case final error?) throw error;
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => user!;

  @override
  Future<RegistrationResult> signUpWithEmailAndPassword({
    required String fullName,
    required String? phone,
    required String email,
    required String password,
  }) async => registrationResult!;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }
}

class _FakeProfileRepository implements ProfileRepository {
  final List<AppUser> ensuredUsers = [];

  @override
  Future<UserProfile> ensureCurrentUserProfile(AppUser user) async {
    ensuredUsers.add(user);
    return UserProfile(id: user.id, role: 'adopter', email: user.email);
  }

  @override
  Future<UserProfile?> fetchCurrentProfile(AppUser user) async => null;

  @override
  Future<String?> fetchEmailByFullName(String name) async => null;

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async => UserProfile(id: userId, role: 'adopter');
}
