import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/app/app.dart';
import 'package:woofy/app/route_names.dart';
import 'package:woofy/app/router.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/data/profile_repository.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/legal/data/account_deletion_repository.dart';
import 'package:woofy/features/legal/providers/legal_providers.dart';

import 'support/fake_auth_repository.dart';

void main() {
  const user = AppUser(id: 'user-1', email: 'ana@example.com');

  testWidgets('requesting deletion registers the request and confirms', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: user);
    addTearDown(auth.dispose);
    final deletion = _FakeAccountDeletionRepository();
    await _pumpDeleteAccount(tester, auth, deletion);

    expect(find.text('Eliminar tu cuenta'), findsOneWidget);

    final submit = find.byKey(const ValueKey('request-deletion'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Solicitar eliminación'));
    await tester.pumpAndSettle();

    expect(deletion.requests, [user]);
    expect(find.textContaining('Recibimos tu solicitud'), findsOneWidget);
  });

  testWidgets('cancelling the dialog does not register a request', (
    tester,
  ) async {
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

    expect(deletion.requests, isEmpty);
  });
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
  final List<AppUser> requests = [];

  @override
  Future<void> requestDeletion(AppUser user, {String? reason}) async {
    requests.add(user);
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
