import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/app/app.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/app/router.dart';
import 'package:mi_app/core/errors/app_exception.dart';
import 'package:mi_app/features/auth/data/auth_models.dart';
import 'package:mi_app/features/auth/data/profile_repository.dart';
import 'package:mi_app/features/auth/providers/auth_providers.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('registration pending confirmation shows a clear message', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    await _pumpRoute(tester, auth, _FakeProfileRepository(), RoutePaths.auth);

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('register-name')), 'Ana');
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'ana@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password')),
      'secreto1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm-password')),
      'secreto1',
    );
    final submit = find.widgetWithText(FilledButton, 'Crear cuenta');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Te enviamos un correo de confirmación. Abrilo y luego iniciá sesión.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Revisá tu correo para confirmar tu cuenta.'),
      findsNothing,
    );
  });

  testWidgets('Google login is shown and delegates to auth on Android', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    try {
      await _pumpRoute(tester, auth, _FakeProfileRepository(), RoutePaths.auth);

      final googleButton = find.text('Continuar con Google');
      expect(googleButton, findsOneWidget);

      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();
      expect(auth.googleSignInCalls, 1);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Google login is hidden on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    try {
      await _pumpRoute(tester, auth, _FakeProfileRepository(), RoutePaths.auth);

      expect(find.text('Continuar con Google'), findsNothing);

      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Continuar con Google'), findsNothing);
      expect(auth.googleSignInCalls, 0);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('registration error does not show the confirmation message', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..registrationError = const AppException(
        code: 'authentication',
        message: 'Ya existe una cuenta con este correo.',
      );
    addTearDown(auth.dispose);
    await _pumpRoute(tester, auth, _FakeProfileRepository(), RoutePaths.auth);

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('register-name')), 'Ana');
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'ana@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password')),
      'secreto1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm-password')),
      'secreto1',
    );
    final submit = find.widgetWithText(FilledButton, 'Crear cuenta');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Ya existe una cuenta con este correo.'), findsOneWidget);
    expect(
      find.text(
        'Te enviamos un correo de confirmación. Abrilo y luego iniciá sesión.',
      ),
      findsNothing,
    );
  });

  testWidgets('profile shows only available public identity fields', (
    tester,
  ) async {
    const user = AppUser(id: 'user-1', email: 'ana@example.com');
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final profiles = _FakeProfileRepository(
      profile: const UserProfile(
        id: 'user-1',
        role: 'adopter',
        fullName: 'Ana Pérez',
        email: 'ana@example.com',
        phone: '+59170000000',
      ),
    );
    await _pumpRoute(tester, auth, profiles, RoutePaths.profile);

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('+59170000000'), findsOneWidget);
    expect(find.text('adopter'), findsNothing);
    expect(find.text('Mis mensajes'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(find.text('Legal y soporte'), findsOneWidget);
    expect(find.text('Términos de uso'), findsOneWidget);
    expect(find.text('Política de privacidad'), findsOneWidget);
    expect(find.text('Eliminar cuenta'), findsOneWidget);
  });

  testWidgets('profile links to the delete account page', (tester) async {
    const user = AppUser(id: 'user-1', email: 'ana@example.com');
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final profiles = _FakeProfileRepository(
      profile: const UserProfile(
        id: 'user-1',
        role: 'adopter',
        fullName: 'Ana Pérez',
        email: 'ana@example.com',
      ),
    );
    await _pumpRoute(tester, auth, profiles, RoutePaths.profile);

    final deleteButton = find.text('Eliminar cuenta');
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Eliminar tu cuenta'), findsOneWidget);
  });

  testWidgets('missing profile provides an idempotent creation retry', (
    tester,
  ) async {
    const user = AppUser(id: 'user-1', email: 'ana@example.com');
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final profiles = _FakeProfileRepository();
    await _pumpRoute(tester, auth, profiles, RoutePaths.profile);

    expect(find.text('Tu perfil todavía no está completo.'), findsOneWidget);
    expect(profiles.ensureCalls, 1);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(profiles.ensureCalls, 2);
  });

  for (final size in <Size>[const Size(320, 568), const Size(800, 1200)]) {
    testWidgets('auth has no overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);

      await _pumpRoute(tester, auth, _FakeProfileRepository(), RoutePaths.auth);

      expect(tester.takeException(), isNull);
      expect(find.text('Ingresar a Woofy'), findsOneWidget);
    });
  }
}

Future<void> _pumpRoute(
  WidgetTester tester,
  FakeAuthRepository auth,
  ProfileRepository profiles,
  String route,
) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(profiles),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WoofyApp()),
  );
  container.read(routerProvider).go(route);
  await tester.pumpAndSettle();
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({this.profile});

  UserProfile? profile;
  int ensureCalls = 0;

  @override
  Future<UserProfile> ensureCurrentUserProfile(AppUser user) async {
    ensureCalls += 1;
    return profile ??
        UserProfile(id: user.id, role: 'adopter', email: user.email);
  }

  @override
  Future<UserProfile?> fetchCurrentProfile(AppUser user) async => profile;

  @override
  Future<String?> fetchEmailByFullName(String name) async => null;

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async => UserProfile(id: userId, role: 'adopter');
}
