import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/features/auth/data/auth_models.dart';
import 'package:woofy/features/auth/data/auth_repository.dart';
import 'package:woofy/features/auth/providers/auth_providers.dart';
import 'package:woofy/features/messages/data/message_models.dart';
import 'package:woofy/features/messages/data/messages_providers.dart';
import 'package:woofy/features/messages/data/messages_repository.dart';

void main() {
  const user = AppUser(id: 'user-1', email: 'ana@example.com');

  test(
    'myThreadsProvider returns empty when user is not authenticated',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository(null)),
          messagesRepositoryProvider.overrideWithValue(
            _FakeMessagesRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(myThreadsProvider.future), isEmpty);
    },
  );

  test('send controller blocks double submit and invalidates data', () async {
    final repository = _FakeMessagesRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user)),
        messagesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(myThreadsProvider.future);
    await container.read(threadMessagesProvider('thread-1').future);
    final futureA = container
        .read(sendMessageControllerProvider('thread-1').notifier)
        .send('Hola');
    final futureB = container
        .read(sendMessageControllerProvider('thread-1').notifier)
        .send('Duplicado');
    await Future.wait([futureA, futureB]);

    expect(repository.sentBodies, ['Hola']);
    expect(container.read(sendMessageControllerProvider('thread-1')), isFalse);
  });
}

class _FakeAuthRepository implements AuthRepository {

  @override
  bool get hasAppleIdentity => false;

  @override
  Future<AppUser> signInWithApple() async =>
      user ?? const AppUser(id: 'apple-user', email: 'apple@example.com');

  @override
  Future<String> reauthenticateWithApple() async => 'apple-auth-code';

  @override
  Stream<AuthLifecycleEvent> get authEvents => const Stream.empty();

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> resendConfirmationEmail({required String email}) async {}
  _FakeAuthRepository(this.user);

  final AppUser? user;

  @override
  AppUser? get currentUser => user;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(user);

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<RegistrationResult> signUpWithEmailAndPassword({
    required String fullName,
    required String? phone,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }
}

class _FakeMessagesRepository implements MessagesRepository {
  final sentBodies = <String>[];

  @override
  Future<List<ConversationThread>> fetchMyThreads() async => [
    ConversationThread(
      id: 'thread-1',
      dogId: 'dog-1',
      shelterId: 'shelter-1',
      adopterId: 'user-1',
      status: 'open',
      createdAt: DateTime(2026, 6, 23),
      updatedAt: DateTime(2026, 6, 23),
      dogName: 'Milo',
      shelterName: 'Woofy',
    ),
  ];

  @override
  Future<ConversationThread> fetchThreadById(String threadId) async =>
      (await fetchMyThreads()).first;

  @override
  Future<ConversationThread?> fetchThreadForDog(String dogId) async =>
      (await fetchMyThreads()).first;

  @override
  Future<ConversationThread> getOrCreateThreadForDog(String dogId) async =>
      (await fetchMyThreads()).first;

  @override
  Future<ConversationThread> getOrCreateInquiryThreadForDog(
    String dogId,
  ) async => (await fetchMyThreads()).first;

  @override
  Future<List<Message>> fetchMessages(String threadId) async => const [];

  @override
  Future<void> sendMessage(String threadId, String body) async {
    sentBodies.add(body);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}
