typedef StringValidator = String? Function(String? value);

abstract final class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(value!.trim())) {
      return 'Ingresá un correo válido.';
    }
    return null;
  }

  static StringValidator minLength(int length) {
    return (value) {
      final requiredError = required(value);
      if (requiredError != null) return requiredError;
      if (value!.trim().length < length) {
        return 'Debe tener al menos $length caracteres.';
      }
      return null;
    };
  }

  static StringValidator matches(String expected, {required String message}) {
    return (value) => value == expected ? null : message;
  }
}
