import 'package:url_launcher/url_launcher.dart';

/// URLs públicas de los documentos legales (mismo sitio web que el footer).
abstract final class LegalLinks {
  static const _base = 'https://woofy-adopci-n-responsable.vercel.app/legal';

  static const terminos = '$_base/terminos';
  static const privacidad = '$_base/privacidad';
  static const definiciones = '$_base/definiciones';
  static const soporte = '$_base/soporte';
  static const eliminarCuenta = '$_base/eliminar-cuenta';

  /// Contacto para denuncias y problemas. La guía 1.2 pide que sea fácil de
  /// alcanzar, así que también se ofrece sin haber iniciado sesión.
  static const soporteEmail = 'woofy@woofy.com.bo';
}

/// Abre un documento legal en un navegador in-app (Custom Tab en Android,
/// SFSafariViewController en iOS) para que la experiencia se sienta interna.
Future<void> openLegalUrl(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
}

/// Abre el cliente de correo con el asunto ya puesto. Va por
/// externalApplication porque mailto: lo resuelve otra app, no el navegador.
Future<void> openSupportEmail({String subject = 'Consulta desde la app'}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: LegalLinks.soporteEmail,
    queryParameters: {'subject': subject},
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
