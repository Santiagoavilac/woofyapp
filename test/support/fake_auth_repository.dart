import 'dart:async';

import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/data/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user});

  AppUser? user;
  RegistrationResult? registrationResult;
  final authChanges = StreamController<AppUser?>.broadcast();
  final authEventChanges = StreamController<AuthLifecycleEvent>.broadcast();
  int signOutCalls = 0;
  int googleSignInCalls = 0;
  int appleSignInCalls = 0;
  int appleReauthCalls = 0;
  int resetEmailCalls = 0;
  int resendCalls = 0;
  String? lastResetEmail;
  String? lastResendEmail;
  String? lastUpdatedPassword;
  Object? googleSignInError;
  Object? appleSignInError;
  Object? appleReauthError;
  Object? registrationError;
  Object? resetEmailError;
  Object? resendError;
  Object? updatePasswordError;

  bool appleIdentity = false;

  @override
  bool get hasAppleIdentity => appleIdentity;

  @override
  AppUser? get currentUser => user;

  void setUser(AppUser? user) {
    this.user = user;
    authChanges.add(user);
  }

  @override
  Stream<AppUser?> get authStateChanges => authChanges.stream;

  @override
  Stream<AuthLifecycleEvent> get authEvents => authEventChanges.stream;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    resetEmailCalls += 1;
    lastResetEmail = email;
    if (resetEmailError case final error?) throw error;
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    lastUpdatedPassword = newPassword;
    if (updatePasswordError case final error?) throw error;
  }

  @override
  Future<void> resendConfirmationEmail({required String email}) async {
    resendCalls += 1;
    lastResendEmail = email;
    if (resendError case final error?) throw error;
  }

  @override
  Future<AppUser> signInWithApple() async {
    appleSignInCalls += 1;
    if (appleSignInError case final error?) throw error;
    final signedInUser =
        user ?? const AppUser(id: 'apple-user', email: 'apple@example.com');
    setUser(signedInUser);
    return signedInUser;
  }

  @override
  Future<String> reauthenticateWithApple() async {
    appleReauthCalls += 1;
    if (appleReauthError case final error?) throw error;
    return 'apple-auth-code';
  }

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

  Future<void> dispose() async {
    await authChanges.close();
    await authEventChanges.close();
  }
}
