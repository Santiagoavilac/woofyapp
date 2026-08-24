import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/messages/data/messages_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('repository scopes thread reads to the authenticated adopter', () async {
    final source = _FakeMessagesDataSource();
    final repository = SupabaseMessagesRepository.withDataSource(source);

    await repository.fetchThreadById('thread-1');

    expect(source.threadLookup, ('thread-1', 'user-1'));
  });

  test('thread lookup by dog is scoped to the authenticated adopter', () async {
    final source = _FakeMessagesDataSource();
    final repository = SupabaseMessagesRepository.withDataSource(source);

    final thread = await repository.fetchThreadForDog('dog-1');

    expect(thread?.id, 'thread-1');
    expect(source.dogThreadLookup, ('dog-1', 'user-1'));
  });

  test(
    'getOrCreateThreadForDog creates only after a user application',
    () async {
      final source = _FakeMessagesDataSource(hasThread: false);
      final repository = SupabaseMessagesRepository.withDataSource(source);

      final thread = await repository.getOrCreateThreadForDog('dog-1');

      expect(thread.id, 'thread-created');
      expect(source.applicationLookup, ('dog-1', 'user-1'));
      expect(source.insertedThread, {
        'dog_id': 'dog-1',
        'adopter_id': 'user-1',
        'shelter_id': 'shelter-1',
      });
    },
  );

  test('getOrCreateThreadForDog does not create without application', () async {
    final source = _FakeMessagesDataSource(
      hasThread: false,
      hasApplication: false,
    );
    final repository = SupabaseMessagesRepository.withDataSource(source);

    await expectLater(
      repository.getOrCreateThreadForDog('dog-1'),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          'Necesitás postular antes de escribir al refugio.',
        ),
      ),
    );

    expect(source.insertedThread, isNull);
  });

  test(
    'getOrCreateThreadForDog refetches when unique constraint wins',
    () async {
      final source = _FakeMessagesDataSource(
        hasThread: false,
        uniqueThreadConflict: true,
      );
      final repository = SupabaseMessagesRepository.withDataSource(source);

      final thread = await repository.getOrCreateThreadForDog('dog-1');

      expect(thread.id, 'thread-1');
      expect(source.threadFetchCount, 2);
    },
  );

  test(
    'getOrCreateInquiryThreadForDog creates thread without requiring application',
    () async {
      final source = _FakeMessagesDataSource(
        hasThread: false,
        hasApplication: false,
      );
      final repository = SupabaseMessagesRepository.withDataSource(source);

      final thread = await repository.getOrCreateInquiryThreadForDog('dog-1');

      expect(thread.id, 'thread-created');
      expect(source.applicationLookup, isNull);
      expect(source.insertedThread, {
        'dog_id': 'dog-1',
        'adopter_id': 'user-1',
        'shelter_id': 'shelter-1',
      });
    },
  );

  test('getOrCreateInquiryThreadForDog reuses existing thread', () async {
    final source = _FakeMessagesDataSource();
    final repository = SupabaseMessagesRepository.withDataSource(source);

    final thread = await repository.getOrCreateInquiryThreadForDog('dog-1');

    expect(thread.id, 'thread-1');
    expect(source.insertedThread, isNull);
  });

  test('getOrCreateInquiryThreadForDog handles unique constraint', () async {
    final source = _FakeMessagesDataSource(
      hasThread: false,
      uniqueThreadConflict: true,
    );
    final repository = SupabaseMessagesRepository.withDataSource(source);

    final thread = await repository.getOrCreateInquiryThreadForDog('dog-1');

    expect(thread.id, 'thread-1');
    expect(source.threadFetchCount, 2);
  });

  test('getOrCreateInquiryThreadForDog fails if dog not found', () async {
    final source = _FakeMessagesDataSource(hasThread: false, hasDog: false);
    final repository = SupabaseMessagesRepository.withDataSource(source);

    await expectLater(
      repository.getOrCreateInquiryThreadForDog('dog-unknown'),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', 'dog_not_found'),
      ),
    );

    expect(source.insertedThread, isNull);
  });

  test(
    'sendMessage uses current user as sender and updates thread timestamp',
    () async {
      final source = _FakeMessagesDataSource();
      final repository = SupabaseMessagesRepository.withDataSource(source);

      await repository.sendMessage('thread-1', '  Hola refugio  ');

      expect(source.insertedMessage, {
        'thread_id': 'thread-1',
        'sender_id': 'user-1',
        'body': 'Hola refugio',
      });
      expect(source.updatedThreadId, 'thread-1');
    },
  );

  test('sendMessage rejects empty and long messages before insert', () async {
    final source = _FakeMessagesDataSource();
    final repository = SupabaseMessagesRepository.withDataSource(source);

    await expectLater(
      repository.sendMessage('thread-1', '   '),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          'Escribí un mensaje antes de enviarlo.',
        ),
      ),
    );
    await expectLater(
      repository.sendMessage('thread-1', List.filled(1001, 'x').join()),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          'El mensaje no puede superar 1.000 caracteres.',
        ),
      ),
    );

    expect(source.insertedMessage, isNull);
  });

  test('repository requires an authenticated user', () async {
    final repository = SupabaseMessagesRepository.withDataSource(
      _FakeMessagesDataSource(currentUserId: null),
    );

    await expectLater(
      repository.fetchMyThreads(),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          'Necesitás iniciar sesión para ver tus mensajes.',
        ),
      ),
    );
  });
}

class _FakeMessagesDataSource implements MessagesDataSource {
  _FakeMessagesDataSource({
    this.currentUserId = 'user-1',
    this.hasThread = true,
    this.hasApplication = true,
    this.uniqueThreadConflict = false,
    this.hasDog = true,
  });

  @override
  final String? currentUserId;
  final bool hasThread;
  final bool hasApplication;
  final bool uniqueThreadConflict;
  final bool hasDog;

  (String, String)? threadLookup;
  (String, String)? dogThreadLookup;
  (String, String)? applicationLookup;
  Map<String, dynamic>? insertedMessage;
  Map<String, dynamic>? insertedThread;
  String? updatedThreadId;
  int threadFetchCount = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchThreads(String adopterId) async => [
    _threadJson,
  ];

  @override
  Future<Map<String, dynamic>> fetchThread(
    String threadId,
    String adopterId,
  ) async {
    threadLookup = (threadId, adopterId);
    return _threadJson;
  }

  @override
  Future<Map<String, dynamic>?> fetchThreadForDog(
    String dogId,
    String adopterId,
  ) async {
    threadFetchCount += 1;
    dogThreadLookup = (dogId, adopterId);
    if (dogId != 'dog-1') return null;
    if (hasThread || threadFetchCount > 1) return _threadJson;
    return null;
  }

  @override
  Future<Map<String, dynamic>?> fetchApplicationForDog(
    String dogId,
    String adopterId,
  ) async {
    applicationLookup = (dogId, adopterId);
    return hasApplication
        ? {
            'id': 'application-1',
            'dog_id': dogId,
            'adopter_id': adopterId,
            'shelter_id': 'shelter-1',
            'status': 'submitted',
            'created_at': '2026-06-22T10:00:00Z',
          }
        : null;
  }

  @override
  Future<Map<String, dynamic>?> fetchDogShelterInfo(String dogId) async {
    if (!hasDog || dogId != 'dog-1') return null;
    return {'id': dogId, 'shelter_id': 'shelter-1'};
  }

  @override
  Future<Map<String, dynamic>> insertThread(Map<String, dynamic> values) async {
    insertedThread = values;
    if (uniqueThreadConflict) {
      throw const PostgrestException(message: 'duplicate key', code: '23505');
    }
    return {
      ..._threadJson,
      'id': 'thread-created',
      'dog_id': values['dog_id'],
      'adopter_id': values['adopter_id'],
      'shelter_id': values['shelter_id'],
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMessages(String threadId) async =>
      const [];

  @override
  Future<Map<String, dynamic>?> fetchLatestMessage(String threadId) async => {
    'body': 'Último mensaje',
    'hidden_by_admin': false,
  };

  @override
  String getPublicDogPhotoUrl(String storagePath) =>
      'https://cdn.example.com/$storagePath';

  @override
  Future<void> insertMessage(Map<String, dynamic> values) async {
    insertedMessage = values;
  }

  @override
  Future<void> updateThreadTimestamp(String threadId, String timestamp) async {
    updatedThreadId = threadId;
  }
}

const Map<String, dynamic> _threadJson = {
  'id': 'thread-1',
  'dog_id': 'dog-1',
  'shelter_id': 'shelter-1',
  'adopter_id': 'user-1',
  'status': 'open',
  'created_at': '2026-06-22T10:00:00Z',
  'updated_at': '2026-06-23T10:00:00Z',
  'dogs': {'name': 'Milo', 'slug': 'milo-demo'},
  'shelters': {'name': 'Woofy'},
};
