import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/app/app.dart';
import 'package:mi_app/app/route_names.dart';
import 'package:mi_app/app/router.dart';
import 'package:mi_app/features/applications/data/application_models.dart';
import 'package:mi_app/features/applications/data/applications_providers.dart';
import 'package:mi_app/features/applications/data/applications_repository.dart';
import 'package:mi_app/features/auth/data/auth_models.dart';
import 'package:mi_app/features/auth/data/profile_repository.dart';
import 'package:mi_app/features/auth/providers/auth_providers.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';
import 'package:mi_app/features/dogs/data/dog_repository_provider.dart';
import 'package:mi_app/features/messages/data/message_models.dart';
import 'package:mi_app/features/messages/data/messages_providers.dart';
import 'package:mi_app/features/messages/data/messages_repository.dart';

import 'dogs_pages_test.dart' show FakeDogRepository, sampleDog;
import 'support/fake_auth_repository.dart';

void main() {
  final dog = sampleDog();
  final dogDetail = DogDetail(dog: dog);

  testWidgets('"Consultar" button is visible for unauthenticated user', (
    tester,
  ) async {
    final container = await _pumpDetail(
      tester,
      FakeDogRepository(dogs: [dog], detail: dogDetail),
    );
    await tester.pumpAndSettle();

    expect(find.text('Consultar'), findsOneWidget);
    container.dispose();
  });

  testWidgets('"Consultar" without session navigates to /auth', (tester) async {
    final container = await _pumpDetail(
      tester,
      FakeDogRepository(dogs: [dog], detail: dogDetail),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Consultar'));
    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();

    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RoutePaths.auth,
    );
    container.dispose();
  });

  testWidgets(
    '"Consultar" with session creates thread and navigates to conversation',
    (tester) async {
      const threadId = 'thread-inquiry-1';
      final messages = _FakeMessagesRepository(threadId: threadId);
      final container = await _pumpDetail(
        tester,
        FakeDogRepository(dogs: [dog], detail: dogDetail),
        auth: FakeAuthRepository(
          user: const AppUser(id: 'user-1', email: 'user@example.com'),
        ),
        messages: messages,
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Consultar'));
      await tester.tap(find.text('Consultar'));
      await tester.pumpAndSettle();

      expect(messages.inquiryCalls, 1);
      expect(find.text('Conversación'), findsOneWidget);
      container.dispose();
    },
  );

  testWidgets('"Consultar" reuses existing thread (same navigation target)', (
    tester,
  ) async {
    const threadId = 'thread-existing-1';
    final messages = _FakeMessagesRepository(threadId: threadId);
    final container = await _pumpDetail(
      tester,
      FakeDogRepository(dogs: [dog], detail: dogDetail),
      auth: FakeAuthRepository(
        user: const AppUser(id: 'user-1', email: 'user@example.com'),
      ),
      messages: messages,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Consultar'));
    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();

    expect(find.text('Conversación'), findsOneWidget);
    container.dispose();
  });

  testWidgets('back from conversation returns to dog detail', (tester) async {
    const threadId = 'thread-back-1';
    final container = await _pumpDetail(
      tester,
      FakeDogRepository(dogs: [dog], detail: dogDetail),
      auth: FakeAuthRepository(
        user: const AppUser(id: 'user-1', email: 'user@example.com'),
      ),
      messages: _FakeMessagesRepository(threadId: threadId),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Consultar'));
    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();

    expect(find.text('Conversación'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Perfil del perrito'), findsOneWidget);
    expect(find.text('Consultar'), findsOneWidget);
    container.dispose();
  });
}

Future<ProviderContainer> _pumpDetail(
  WidgetTester tester,
  FakeDogRepository dogRepository, {
  FakeAuthRepository? auth,
  _FakeMessagesRepository? messages,
}) async {
  final authRepo = auth ?? FakeAuthRepository();
  addTearDown(authRepo.dispose);
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepo),
      profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      dogRepositoryProvider.overrideWithValue(dogRepository),
      applicationsRepositoryProvider.overrideWithValue(
        _FakeApplicationsRepository(),
      ),
      if (messages != null)
        messagesRepositoryProvider.overrideWithValue(messages),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WoofyApp()),
  );
  container.read(routerProvider).go(RoutePaths.dogDetail(sampleDog().slug));
  await tester.pump();
  await tester.pump();
  return container;
}

class _FakeMessagesRepository implements MessagesRepository {
  _FakeMessagesRepository({required this.threadId});

  final String threadId;
  int inquiryCalls = 0;

  ConversationThread get _thread => ConversationThread(
    id: threadId,
    dogId: 'dog-1',
    shelterId: 'shelter-1',
    adopterId: 'user-1',
    status: 'open',
    createdAt: DateTime(2026, 6, 23),
    updatedAt: DateTime(2026, 6, 23),
    dogName: 'Milo',
    shelterName: 'Woofy',
  );

  @override
  Future<List<ConversationThread>> fetchMyThreads() async => [];

  @override
  Future<ConversationThread> fetchThreadById(String threadId) async => _thread;

  @override
  Future<ConversationThread?> fetchThreadForDog(String dogId) async => null;

  @override
  Future<ConversationThread> getOrCreateThreadForDog(String dogId) async =>
      _thread;

  @override
  Future<ConversationThread> getOrCreateInquiryThreadForDog(
    String dogId,
  ) async {
    inquiryCalls += 1;
    return _thread;
  }

  @override
  Future<List<Message>> fetchMessages(String threadId) async => const [];

  @override
  Future<void> sendMessage(String threadId, String body) async {}
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile?> fetchCurrentProfile(AppUser user) async => null;

  @override
  Future<UserProfile> ensureCurrentUserProfile(AppUser user) async =>
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

class _FakeApplicationsRepository implements ApplicationsRepository {
  @override
  Future<AdoptionApplication?> fetchMyApplicationForDog(String dogId) async =>
      null;

  @override
  Future<AdoptionApplication> createApplication(
    Dog dog,
    ApplicationFormData formData,
  ) {
    throw UnimplementedError();
  }
}
