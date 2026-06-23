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
