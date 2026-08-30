class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
  });

  factory AppUser.fromAuthMetadata({
    required String id,
    required String email,
    Map<String, dynamic>? metadata,
  }) {
    final values = metadata ?? const <String, dynamic>{};
    return AppUser(
      id: id,
      email: email,
      fullName: _optional(
        values['full_name'] as String? ?? values['name'] as String?,
      ),
      phone: _optional(values['phone'] as String?),
    );
  }

  final String id;
  final String email;
  final String? fullName;
  final String? phone;

  static String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  // Se compara por valor y no por identidad porque de eso depende que la app
  // no se recargue sola.
  //
  // Supabase emite `onAuthStateChange` en la sesión inicial, en cada refresco
  // de token y cada vez que la app vuelve del fondo. Cada emisión arma un
  // `AppUser` nuevo. Sin este `==`, Riverpod lo veía como un usuario distinto,
  // avisaba a todo lo que depende de la sesión y la pantalla entera volvía a
  // pedir datos y a mostrar el spinner — encima de cualquier animación.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          other.id == id &&
          other.email == email &&
          other.fullName == fullName &&
          other.phone == phone;

  @override
  int get hashCode => Object.hash(id, email, fullName, phone);
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.role,
    this.fullName,
    this.email,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'adopter',
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class RegistrationResult {
  const RegistrationResult({
    required this.user,
    required this.requiresEmailConfirmation,
  });

  final AppUser user;
  final bool requiresEmailConfirmation;
}

/// Eventos del ciclo de vida de la sesión, sin exponer tipos de Supabase.
///
/// [passwordRecovery] es el que llega cuando el usuario abre el enlace de
/// recuperación del correo: Supabase crea una sesión válida, así que sin
/// distinguirlo de un login normal el usuario terminaría en el perfil en vez
/// de en la pantalla de contraseña nueva.
enum AuthLifecycleEvent {
  signedIn,
  signedOut,
  userUpdated,
  passwordRecovery,
  other,
}
