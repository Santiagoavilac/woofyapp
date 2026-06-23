import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/features/auth/data/auth_models.dart';

void main() {
  test('AppUser uses Google name when full_name is absent', () {
    final user = AppUser.fromAuthMetadata(
      id: 'google-user',
      email: 'ana@example.com',
      metadata: const {'name': 'Ana Google'},
    );

    expect(user.fullName, 'Ana Google');
    expect(user.phone, isNull);
  });

  group('UserProfile.fromJson', () {
    test('parses the public profile fields', () {
      final profile = UserProfile.fromJson({
        'id': 'user-1',
        'full_name': 'Ana Pérez',
        'email': 'ana@example.com',
        'phone': '+59170000000',
        'role': 'adopter',
        'created_at': '2026-06-20T10:00:00Z',
        'updated_at': '2026-06-20T11:00:00Z',
      });

      expect(profile.id, 'user-1');
      expect(profile.fullName, 'Ana Pérez');
      expect(profile.email, 'ana@example.com');
      expect(profile.phone, '+59170000000');
      expect(profile.role, 'adopter');
      expect(profile.createdAt, DateTime.utc(2026, 6, 20, 10));
    });

    test('accepts nullable optional fields', () {
      final profile = UserProfile.fromJson({'id': 'user-2', 'role': 'adopter'});

      expect(profile.fullName, isNull);
      expect(profile.email, isNull);
      expect(profile.phone, isNull);
      expect(profile.createdAt, isNull);
    });
  });
}
