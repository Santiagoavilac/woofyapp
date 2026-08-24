import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/app/app.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/app/router.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/data/profile_repository.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('the login form links to password recovery', (tester) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    await _pump(tester, auth, RoutePaths.auth);

    await tester.tap(find.byKey(const ValueKey('forgot-password-link')));
    await tester.pumpAndSettle();

    // La ruta se apila con push para conservar el volver al ingreso, así que
    // lo verificable es la pantalla, no la URI del delegate.
    expect(find.text('Creá una contraseña nueva'), findsOneWidget);
    expect(find.byKey(const ValueKey('forgot-password-email')), findsOneWidget);
  });

  testWidgets('recovery requires an identifier and then confirms the send', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    await _pump(tester, auth, RoutePaths.forgotPassword);

    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();
    expect(find.text('Este campo es obligatorio.'), findsOneWidget);
    expect(auth.resetEmailCalls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('forgot-password-email')),
      'ana@example.com',
    );
    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();

    expect(auth.resetEmailCalls, 1);
    expect(auth.lastResetEmail, 'ana@example.com');
    expect(
      find.textContaining('Si existe una cuenta con esos datos'),
      findsOneWidget,
    );
  });

  testWidgets('recovery surfaces repository errors', (tester) async {
    final auth = FakeAuthRepository()
      ..resetEmailError = const AppException(
        code: 'authentication',
        message: 'Esperá un momento antes de pedir otro correo.',
      );
    addTearDown(auth.dispose);
    await _pump(tester, auth, RoutePaths.forgotPassword);

    await tester.enterText(
      find.byKey(const ValueKey('forgot-password-email')),
      'ana@example.com',
    );
    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();

    expect(
      find.text('Esperá un momento antes de pedir otro correo.'),
      findsOneWidget,
    );
  });

  testWidgets('the new password screen validates length and confirmation', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: const AppUser(id: 'user-1', email: 'ana@example.com'),
    );
    addTearDown(auth.dispose);
    await _pump(tester, auth, RoutePaths.newPassword);

    await tester.enterText(find.byKey(const ValueKey('new-password')), '123');
    await tester.enterText(
      find.byKey(const ValueKey('new-password-confirm')),
      '123',
    );
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();
    expect(find.text('Debe tener al menos 6 caracteres.'), findsOneWidget);
    expect(auth.lastUpdatedPassword, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('new-password')),
      'clavesegura',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password-confirm')),
      'otracosa',
    );
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(auth.lastUpdatedPassword, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('new-password-confirm')),
      'clavesegura',
    );
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();
    expect(auth.lastUpdatedPassword, 'clavesegura');
  });

  testWidgets('the new password screen rejects a spent link', (tester) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    await _pump(tester, auth, RoutePaths.newPassword);

    expect(find.text('El enlace ya no sirve'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-password')), findsNothing);
  });
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeAuthRepository auth,
  String route,
) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WoofyApp()),
  );
  container.read(routerProvider).go(route);
  await tester.pumpAndSettle();
  return container;
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile> ensureCurrentUserProfile(AppUser user) async =>
      UserProfile(id: user.id, role: 'adopter', email: user.email);

  @override
  Future<UserProfile?> fetchCurrentProfile(AppUser user) async => null;

  @override
  Future<String?> fetchEmailByFullName(String name) async => null;

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async => UserProfile(id: userId, role: 'adopter');
}
