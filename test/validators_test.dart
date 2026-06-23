import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_app/core/utils/date_formatters.dart';
import 'package:mi_app/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('required rejects blank values', () {
      expect(Validators.required('  '), isNotNull);
      expect(Validators.required('Woofy'), isNull);
    });

    test('email rejects malformed addresses', () {
      expect(Validators.email('persona@'), isNotNull);
      expect(Validators.email('persona@woofy.com'), isNull);
    });

    test('minLength enforces the requested length', () {
      final validator = Validators.minLength(4);

      expect(validator('abc'), isNotNull);
      expect(validator('abcd'), isNull);
    });

    test('matches compares confirmation values', () {
      final validator = Validators.matches(
        'secreto1',
        message: 'Las contraseñas no coinciden.',
      );

      expect(validator('distinto'), 'Las contraseñas no coinciden.');
      expect(validator('secreto1'), isNull);
    });
  });

  test('DateFormatters formats short and Spanish long dates', () async {
    await initializeDateFormatting('es');
    final date = DateTime(2026, 6, 19);

    expect(DateFormatters.short(date), '19/06/2026');
    expect(DateFormatters.longSpanish(date), '19 de junio de 2026');
  });
}
