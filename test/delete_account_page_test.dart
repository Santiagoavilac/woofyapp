import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/app/app.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/app/router.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/data/profile_repository.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/legal/data/account_deletion_repository.dart';
import 'package:woofy/features/legal/providers/legal_providers.dart';

import 'support/fake_auth_repository.dart';

void main() {
  const user = AppUser(id: 'user-1', email: 'ana@example.com');

  testWidgets('a non-Apple account deletes without an authorization code', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final deletion = _FakeAccountDeletionRepository();
    await _pumpDeleteAccount(tester, auth, deletion);

    expect(find.text('Eliminar tu cuenta'), findsOneWidget);

    await _confirmDeletion(tester);

    expect(deletion.calls, hasLength(1));
    expect(deletion.calls.single, isNull);
    expect(auth.appleReauthCalls, 0);
    expect(auth.signOutCalls, 1);
  });

  testWidgets('an Apple account revokes access before deleting', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: user)..appleIdentity = true;
    addTearDown(auth.dispose);
    final deletion = _FakeAccountDeletionRepository();
    await _pumpDeleteAccount(tester, auth, deletion);

    await _confirmDeletion(tester);

    expect(auth.appleReauthCalls, 1);
    expect(deletion.calls.single, 'apple-auth-code');
    expect(auth.signOutCalls, 1);
  });

  testWidgets('a failed Apple re-authentication keeps the account', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: user)
      ..appleIdentity = true
      ..appleReauthError = const AppException(
        code: 'apple_missing_code',
        message: 'Apple no devolvió el código de autorización.',
      );
    addTearDown(auth.dispose);
    final deletion = _FakeAccountDeletionRepository();
    await _pumpDeleteAccount(tester, auth, deletion);

    await _confirmDeletion(tester);

    expect(deletion.calls, isEmpty);
    expect(auth.signOutCalls, 0);
    expect(
      find.text('Apple no devolvió el código de autorización.'),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the dialog deletes nothing', (tester) async {
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final deletion = _FakeAccountDeletionRepository();
    await _pumpDeleteAccount(tester, auth, deletion);

    final submit = find.byKey(const ValueKey('request-deletion'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(deletion.calls, isEmpty);
    expect(auth.signOutCalls, 0);
  });
}

Future<void> _confirmDeletion(WidgetTester tester) async {
  final submit = find.byKey(const ValueKey('request-deletion'));
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Eliminar definitivamente'));
  await tester.pumpAndSettle();
}

Future<void> _pumpDeleteAccount(
  WidgetTester tester,
  FakeAuthRepository auth,
  AccountDeletionRepository deletion,
) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      accountDeletionRepositoryProvider.overrideWithValue(deletion),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WoofyApp()),
  );
  container.read(routerProvider).go(RoutePaths.deleteAccount);
  await tester.pumpAndSettle();
}

class _FakeAccountDeletionRepository implements AccountDeletionRepository {
  /// Guarda el código de Apple recibido en cada llamada, o null si no vino.
  final List<String?> calls = [];

  @override
  Future<void> deleteAccount({
    String? appleAuthorizationCode,
    String? reason,
  }) async {
    calls.add(appleAuthorizationCode);
  }
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile> ensureCurrentUserProfile(AppUser user) async =>
      UserProfile(id: user.id, role: 'adopter', email: user.email);

  @override
  Future<UserProfile?> fetchCurrentProfile(AppUser user) async =>
      UserProfile(id: user.id, role: 'adopter', email: user.email);

  @override
  Future<String?> fetchEmailByFullName(String name) async => null;

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async => UserProfile(id: userId, role: 'adopter');
}
