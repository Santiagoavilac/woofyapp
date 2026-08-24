import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:woofy/core/config/env.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRepository {
  AppUser? get currentUser;

  Stream<AppUser?> get authStateChanges;

  Stream<AuthLifecycleEvent> get authEvents;

  /// Si la cuenta se creó con Apple hay que revocar sus tokens al eliminarla.
  bool get hasAppleIdentity;

  Future<void> signInWithGoogle();

  /// Ingreso nativo con Apple. A diferencia de Google, resuelve en el acto:
  /// la hoja del sistema devuelve el token sin pasar por el navegador.
  Future<AppUser> signInWithApple();

  /// Vuelve a pedir credenciales de Apple para obtener un código de
  /// autorización fresco. Apple exige revocarlo al eliminar la cuenta, y así
  /// evitamos guardar un token de larga duración en la base.
  Future<String> reauthenticateWithApple();

  /// Envía el correo de recuperación. Vuelve a la app por deep link.
  Future<void> sendPasswordResetEmail({required String email});

  /// Cambia la contraseña del usuario con sesión de recuperación activa.
  Future<void> updatePassword({required String newPassword});

  /// Reenvía el correo de confirmación de registro.
  Future<void> resendConfirmationEmail({required String email});

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
  bool get hasAppleIdentity =>
      _client.auth.currentUser?.identities?.any(
        (identity) => identity.provider == 'apple',
      ) ??
      false;

  @override
  Stream<AuthLifecycleEvent> get authEvents =>
      _client.auth.onAuthStateChange.map(
        (state) => switch (state.event) {
          AuthChangeEvent.passwordRecovery =>
            AuthLifecycleEvent.passwordRecovery,
          AuthChangeEvent.signedIn => AuthLifecycleEvent.signedIn,
          AuthChangeEvent.signedOut => AuthLifecycleEvent.signedOut,
          AuthChangeEvent.userUpdated => AuthLifecycleEvent.userUpdated,
          _ => AuthLifecycleEvent.other,
        },
      );

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      // Reusa el deep link del OAuth: ya está en las Redirect URLs de
      // Supabase, así que el flujo no necesita configuración nueva.
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: Env.oauthMobileRedirect,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> resendConfirmationEmail({required String email}) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: Env.authEmailRedirectTo,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

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
  Future<AppUser> signInWithApple() async {
    try {
      // Apple firma el nonce hasheado; Supabase valida contra el crudo.
      final rawNonce = _generateRawNonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AppException(
          code: 'apple_missing_token',
          message: 'Apple no devolvió las credenciales. Probá de nuevo.',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      final user = _mapUser(response.user);
      if (user == null) {
        throw const AuthException('No authenticated user returned');
      }

      // Apple manda el nombre una única vez, en el primer ingreso. Si no lo
      // guardamos ahora, se pierde para siempre.
      final fullName = _appleFullName(credential);
      if (fullName != null && (user.fullName == null || user.fullName!.isEmpty)) {
        await _client.auth.updateUser(
          UserAttributes(data: {'full_name': fullName}),
        );
        return AppUser(
          id: user.id,
          email: user.email,
          fullName: fullName,
          phone: user.phone,
        );
      }
      return user;
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<String> reauthenticateWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email],
      );
      final code = credential.authorizationCode;
      if (code.isEmpty) {
        throw const AppException(
          code: 'apple_missing_code',
          message: 'Apple no devolvió el código de autorización.',
        );
      }
      return code;
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  static String? _appleFullName(AuthorizationCredentialAppleID credential) {
    final parts = [
      credential.givenName,
      credential.familyName,
    ].whereType<String>().map((part) => part.trim()).where((p) => p.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' ');
  }

  static String _generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
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
