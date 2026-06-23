import 'package:mi_app/core/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class ErrorMapper {
  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    if (error is FormatException) {
      return AppException(
        code: 'configuration',
        message: 'Revisá la configuración local antes de volver a intentar.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is AuthException) {
      final message = switch (error.code) {
        'invalid_credentials' => 'Revisá tu correo y contraseña.',
        'email_not_confirmed' => 'Confirmá tu correo antes de ingresar.',
        'user_already_exists' ||
        'user_already_registered' => 'Ya existe una cuenta con este correo.',
        'email_address_invalid' => 'Ingresá un correo válido.',
        'weak_password' =>
          'La contraseña no cumple los requisitos de seguridad.',
        _ => 'No pudimos completar la autenticación.',
      };
      return AppException(
        code: 'authentication',
        message: message,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is PostgrestException && error.code == '42501') {
      return AppException(
        code: 'supabase_permission',
        message: 'El catálogo no tiene permisos públicos de lectura.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is PostgrestException || error is StorageException) {
      return AppException(
        code: 'supabase',
        message: 'No pudimos conectar con el servicio de Woofy.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return AppException(
      message: 'Ocurrió un error inesperado al iniciar Woofy.',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
