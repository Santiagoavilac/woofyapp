import 'package:woofy/core/config/env.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRepository {
  AppUser? get currentUser;

  Stream<AppUser?> get authStateChanges;

  Future<void> signInWithGoogle();

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<RegistrationResult> signUpWithEmailAndPassword({
    required String fullName,
    required String? phone,
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AppUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AppUser?> get authStateChanges => _client.auth.onAuthStateChange.map(
    (state) => _mapUser(state.session?.user),
  );

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Env.oauthMobileRedirect,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = _mapUser(response.user);
      if (user == null) {
        throw const AuthException('No authenticated user returned');
      }
      return user;
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<RegistrationResult> signUpWithEmailAndPassword({
    required String fullName,
    required String? phone,
    required String email,
    required String password,
  }) async {
    try {
      final normalizedPhone = _optional(phone);
      final metadata = <String, dynamic>{'full_name': fullName.trim()};
      if (normalizedPhone != null) metadata['phone'] = normalizedPhone;
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: Env.authEmailRedirectTo,
        data: metadata,
      );
      final user = _mapUser(response.user);
      if (user == null) {
        throw const AuthException('No registered user returned');
      }
      return RegistrationResult(
        user: user,
        requiresEmailConfirmation: response.session == null,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  static AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser.fromAuthMetadata(
      id: user.id,
      email: user.email ?? '',
      metadata: user.userMetadata,
    );
  }

  static String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
