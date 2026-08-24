import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/app/bootstrap_error_app.dart';
import 'package:woofy/core/config/env.dart';
import 'package:woofy/core/errors/error_mapper.dart';

void main() {
  group('Env', () {
    test('reads a valid Supabase client configuration', () {
      dotenv.loadFromString(
        envString: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_test
AUTH_EMAIL_REDIRECT_TO=https://woofy-adopci-n-responsable.vercel.app/auth/confirmed
''',
      );

      expect(Env.supabaseUrl, 'https://example.supabase.co');
      expect(Env.supabasePublishableKey, 'sb_publishable_test');
      expect(
        Env.authEmailRedirectTo,
        'https://woofy-adopci-n-responsable.vercel.app/auth/confirmed',
      );
    });

    test('rejects a missing publishable key', () {
      dotenv.loadFromString(
        envString: '''
SUPABASE_URL=https://example.supabase.co
AUTH_EMAIL_REDIRECT_TO=https://woofy-adopci-n-responsable.vercel.app/auth/confirmed
''',
      );

      expect(Env.validate, throwsA(isA<FormatException>()));
    });

    test('rejects a non HTTPS Supabase URL', () {
      dotenv.loadFromString(
        envString: '''
SUPABASE_URL=http://example.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_test
AUTH_EMAIL_REDIRECT_TO=https://woofy-adopci-n-responsable.vercel.app/auth/confirmed
''',
      );

      expect(Env.validate, throwsA(isA<FormatException>()));
    });

    test('rejects a non HTTPS email confirmation redirect URL', () {
      dotenv.loadFromString(
        envString: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_test
AUTH_EMAIL_REDIRECT_TO=http://example.com/auth/confirmed
''',
      );

      expect(Env.validate, throwsA(isA<FormatException>()));
    });

    test('rejects a localhost email confirmation redirect URL', () {
      dotenv.loadFromString(
        envString: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_test
AUTH_EMAIL_REDIRECT_TO=https://localhost/auth/confirmed
''',
      );

      expect(Env.validate, throwsA(isA<FormatException>()));
    });

    test('rejects a loopback email confirmation redirect URL', () {
      dotenv.loadFromString(
        envString: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_test
AUTH_EMAIL_REDIRECT_TO=https://127.0.0.1/auth/confirmed
''',
      );

      expect(Env.validate, throwsA(isA<FormatException>()));
    });
  });

  testWidgets('bootstrap errors show a safe diagnostic message', (
    tester,
  ) async {
    final exception = ErrorMapper.map(
      const FormatException('SUPABASE_PUBLISHABLE_KEY=secret-value'),
    );

    await tester.pumpWidget(BootstrapErrorApp(exception: exception));

    expect(find.text('No pudimos iniciar Woofy'), findsOneWidget);
    expect(find.textContaining('configuración'), findsOneWidget);
    expect(find.textContaining('secret-value'), findsNothing);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
