import 'dart:async';

import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/data/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user});

  AppUser? user;
  RegistrationResult? registrationResult;
  final authChanges = StreamController<AppUser?>.broadcast();
  int signOutCalls = 0;
  int googleSignInCalls = 0;
  Object? googleSignInError;
  Object? registrationError;

  @override
  AppUser? get currentUser => user;

  void setUser(AppUser? user) {
    this.user = user;
    authChanges.add(user);
  }

  @override
  Stream<AppUser?> get authStateChanges => authChanges.stream;

  @override
  Future<void> signInWithGoogle() async {
    googleSignInCalls += 1;
    if (googleSignInError case final error?) throw error;
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final signedInUser = user ?? AppUser(id: 'user-1', email: email);
    setUser(signedInUser);
    return signedInUser;
  }

  @override
  Future<RegistrationResult> signUpWithEmailAndPassword({
    required String fullName,
    required String? phone,
    required String email,
    required String password,
  }) async {
    if (registrationError case final error?) throw error;
    return registrationResult ??
        RegistrationResult(
          user: AppUser(
            id: 'user-1',
            email: email,
            fullName: fullName,
            phone: phone,
          ),
          requiresEmailConfirmation: true,
        );
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    setUser(null);
  }

  Future<void> dispose() => authChanges.close();
}
