import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_app/core/services/supabase_service.dart';
import 'package:mi_app/features/auth/providers/auth_providers.dart';
import 'package:mi_app/features/messages/data/message_models.dart';
import 'package:mi_app/features/messages/data/messages_repository.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>(
  (ref) => SupabaseMessagesRepository(ref.watch(supabaseClientProvider)),
);

final myThreadsProvider = FutureProvider<List<ConversationThread>>((ref) async {
  if (ref.watch(currentUserProvider) == null) {
    return const <ConversationThread>[];
  }
  return ref.watch(messagesRepositoryProvider).fetchMyThreads();
});

final threadProvider = FutureProvider.family<ConversationThread, String>((
  ref,
  threadId,
) async {
  return ref.watch(messagesRepositoryProvider).fetchThreadById(threadId);
});

final threadForDogProvider = FutureProvider.family<ConversationThread?, String>(
  (ref, dogId) async {
    if (ref.watch(currentUserProvider) == null) {
      return null;
    }
    return ref.watch(messagesRepositoryProvider).fetchThreadForDog(dogId);
  },
);

final threadMessagesProvider = FutureProvider.family<List<Message>, String>((
  ref,
  threadId,
) async {
  return ref.watch(messagesRepositoryProvider).fetchMessages(threadId);
});

final sendMessageControllerProvider =
    NotifierProvider.family<SendMessageController, bool, String>(
      SendMessageController.new,
    );

final dogConversationControllerProvider =
    NotifierProvider.family<DogConversationController, bool, String>(
      DogConversationController.new,
    );

class SendMessageController extends Notifier<bool> {
  SendMessageController(this.threadId);

  final String threadId;

  @override
  bool build() => false;

  Future<void> send(String body) async {
    if (state) return;
    state = true;
    try {
      await ref.read(messagesRepositoryProvider).sendMessage(threadId, body);
      ref.invalidate(threadProvider(threadId));
      ref.invalidate(threadMessagesProvider(threadId));
      ref.invalidate(myThreadsProvider);
    } finally {
      state = false;
    }
  }
}

class DogConversationController extends Notifier<bool> {
  DogConversationController(this.dogId);

  final String dogId;

  @override
  bool build() => false;

  Future<ConversationThread?> open() async {
    if (state) return null;
    state = true;
    try {
      final thread = await ref
          .read(messagesRepositoryProvider)
          .getOrCreateThreadForDog(dogId);
      ref.invalidate(threadProvider(thread.id));
      ref.invalidate(threadMessagesProvider(thread.id));
      ref.invalidate(threadForDogProvider(dogId));
      ref.invalidate(myThreadsProvider);
      return thread;
    } finally {
      state = false;
    }
  }
}

final dogInquiryControllerProvider =
    NotifierProvider.family<DogInquiryController, bool, String>(
      DogInquiryController.new,
    );

class DogInquiryController extends Notifier<bool> {
  DogInquiryController(this.dogId);

  final String dogId;

  @override
  bool build() => false;

  Future<ConversationThread?> open() async {
    if (state) return null;
    state = true;
    try {
      final thread = await ref
          .read(messagesRepositoryProvider)
          .getOrCreateInquiryThreadForDog(dogId);
      ref.invalidate(threadProvider(thread.id));
      ref.invalidate(threadMessagesProvider(thread.id));
      ref.invalidate(threadForDogProvider(dogId));
      ref.invalidate(myThreadsProvider);
      return thread;
    } finally {
      state = false;
    }
  }
}
