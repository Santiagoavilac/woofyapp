import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class Env {
  static const _supabaseUrlKey = 'SUPABASE_URL';
  static const _supabasePublishableKey = 'SUPABASE_PUBLISHABLE_KEY';
  static const _authEmailRedirectToKey = 'AUTH_EMAIL_REDIRECT_TO';

  /// Deep link para el retorno de Google OAuth en móvil. Debe coincidir
  /// exactamente con el intent-filter de AndroidManifest.xml y con las
  /// Redirect URLs configuradas en Supabase Auth.
  static const oauthMobileRedirect = 'io.woofy.app://login-callback';

  static Future<void> load({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName);
    validate();
  }

  static String get supabaseUrl => dotenv.env[_supabaseUrlKey]?.trim() ?? '';

  static String get supabasePublishableKey =>
      dotenv.env[_supabasePublishableKey]?.trim() ?? '';

  static String get authEmailRedirectTo =>
      dotenv.env[_authEmailRedirectToKey]?.trim() ?? '';

  static void validate() {
    if (!_isHttpsUrl(supabaseUrl)) {
      throw const FormatException(
        'SUPABASE_URL debe ser una URL HTTPS válida.',
      );
    }

    if (supabasePublishableKey.isEmpty) {
      throw const FormatException('Falta SUPABASE_PUBLISHABLE_KEY.');
    }

    if (!_isSafePublicHttpsUrl(authEmailRedirectTo)) {
      throw const FormatException(
        'AUTH_EMAIL_REDIRECT_TO debe ser una URL HTTPS válida.',
      );
    }
  }

  static bool _isHttpsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  static bool _isSafePublicHttpsUrl(String value) {
    if (!_isHttpsUrl(value)) return false;
    final uri = Uri.parse(value);
    final host = uri.host.toLowerCase();
    return host != 'localhost' && host != '127.0.0.1';
  }
}
