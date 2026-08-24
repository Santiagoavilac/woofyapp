import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/core/errors/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('ErrorMapper identifies a missing public database grant', () {
    final mapped = ErrorMapper.map(
      const PostgrestException(
        message: 'permission denied for table dogs',
        code: '42501',
      ),
    );

    expect(mapped.code, 'supabase_permission');
    expect(
      mapped.message,
      'El catálogo no tiene permisos públicos de lectura.',
    );
    expect(mapped.message, isNot(contains('dogs')));
  });

  test('ErrorMapper provides human authentication messages', () {
    expect(
      ErrorMapper.map(
        const AuthException('Invalid login', code: 'invalid_credentials'),
      ).message,
      'Revisá tu correo y contraseña.',
    );
    expect(
      ErrorMapper.map(
        const AuthException('Confirm email', code: 'email_not_confirmed'),
      ).message,
      'Confirmá tu correo antes de ingresar.',
    );
    expect(
      ErrorMapper.map(
        const AuthException('Already exists', code: 'user_already_exists'),
      ).message,
      'Ya existe una cuenta con este correo.',
    );
    expect(
      ErrorMapper.map(
        const AuthException('Invalid email', code: 'email_address_invalid'),
      ).message,
      'Ingresá un correo válido.',
    );
  });
}
