import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/core/errors/app_exception.dart';
import 'package:mi_app/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Google OAuth is disabled during Fase 4A', () async {
    final repository = SupabaseAuthRepository(
      SupabaseClient('https://example.supabase.co', 'publishable-key'),
    );

    await expectLater(
      repository.signInWithGoogle(),
      throwsA(
        isA<AppException>()
            .having((error) => error.code, 'code', 'google_oauth_disabled')
            .having(
              (error) => error.message,
              'message',
              'Google login no está disponible por ahora.',
            ),
      ),
    );
  });
}
