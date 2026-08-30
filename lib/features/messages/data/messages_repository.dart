import 'package:woofy/core/errors/app_exception.dart';
import 'package:woofy/features/messages/data/message_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class MessagesRepository {
  Future<List<ConversationThread>> fetchMyThreads();

  Future<ConversationThread> fetchThreadById(String threadId);

  Future<ConversationThread?> fetchThreadForDog(String dogId);

  Future<ConversationThread> getOrCreateThreadForDog(String dogId);

  Future<ConversationThread> getOrCreateInquiryThreadForDog(String dogId);

  Future<List<Message>> fetchMessages(String threadId);

  Future<void> sendMessage(String threadId, String body);

  /// Cuántos mensajes ajenos sin leer tengo, por conversación.
  Future<List<UnreadThread>> fetchUnreadThreads();

  /// Marca como leídos los mensajes ajenos de un hilo.
  Future<void> markThreadRead(String threadId);
}

abstract interface class MessagesDataSource {
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> fetchThreads(String adopterId);

  Future<Map<String, dynamic>> fetchThread(String threadId, String adopterId);

  Future<Map<String, dynamic>?> fetchThreadForDog(
    String dogId,
    String adopterId,
  );

  Future<Map<String, dynamic>?> fetchApplicationForDog(
    String dogId,
    String adopterId,
  );

  Future<Map<String, dynamic>?> fetchDogShelterInfo(String dogId);

  Future<Map<String, dynamic>> insertThread(Map<String, dynamic> values);

  Future<List<Map<String, dynamic>>> fetchMessages(String threadId);

  Future<Map<String, dynamic>?> fetchLatestMessage(String threadId);

  Future<void> insertMessage(Map<String, dynamic> values);

  Future<void> updateThreadTimestamp(String threadId, String timestamp);

  Future<List<Map<String, dynamic>>> fetchUnreadMessages(String adopterId);

  Future<void> markThreadRead(String threadId);

  String getPublicDogPhotoUrl(String storagePath);
}

class SupabaseMessagesDataSource implements MessagesDataSource {
  SupabaseMessagesDataSource(this._client);

  static const _threadSelect = '''
    id, dog_id, shelter_id, adopter_id, status, last_message_at, created_at, updated_at,
    dogs(name, slug, dog_photos(storage_path, is_cover, position)),
    shelters(name),
    profiles(full_name, email)
  ''';

  static const _messageSelect = '''
    id, thread_id, sender_id, sender_shelter_id, body, read_at, hidden_by_admin, created_at,
    profiles(full_name, email)
  ''';

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> fetchThreads(String adopterId) => _client
      .from('conversation_threads')
      .select(_threadSelect)
      .eq('adopter_id', adopterId)
      .order('last_message_at', ascending: false, nullsFirst: false)
      .order('created_at', ascending: false);

  @override
  Future<Map<String, dynamic>> fetchThread(String threadId, String adopterId) =>
      _client
          .from('conversation_threads')
          .select(_threadSelect)
          .eq('id', threadId)
          .eq('adopter_id', adopterId)
          .single();

  @override
  Future<Map<String, dynamic>?> fetchThreadForDog(
    String dogId,
    String adopterId,
  ) => _client
      .from('conversation_threads')
      .select(_threadSelect)
      .eq('dog_id', dogId)
      .eq('adopter_id', adopterId)
      .maybeSingle();

  @override
  Future<Map<String, dynamic>?> fetchApplicationForDog(
    String dogId,
    String adopterId,
  ) => _client
      .from('applications')
      .select('id, dog_id, adopter_id, shelter_id, status, created_at')
      .eq('dog_id', dogId)
      .eq('adopter_id', adopterId)
      .maybeSingle();

  @override
  Future<Map<String, dynamic>?> fetchDogShelterInfo(String dogId) => _client
      .from('dogs')
      .select('id, shelter_id')
      .eq('id', dogId)
      .maybeSingle();

  @override
  Future<Map<String, dynamic>> insertThread(Map<String, dynamic> values) =>
      _client
          .from('conversation_threads')
          .insert(values)
          .select(_threadSelect)
          .single();

  @override
  Future<List<Map<String, dynamic>>> fetchMessages(String threadId) => _client
      .from('messages')
      .select(_messageSelect)
      .eq('thread_id', threadId)
      .order('created_at', ascending: true);

  @override
  Future<Map<String, dynamic>?> fetchLatestMessage(String threadId) => _client
      .from('messages')
      .select('body, hidden_by_admin, created_at')
      .eq('thread_id', threadId)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();

  // La policy "Participants can read messages" ya recorta la tabla a mis
  // hilos, así que una sola consulta trae todos los no leídos de todas mis
  // conversaciones. El `adopterId` se pasa igual para no depender de que la
  // policy siga siendo la misma mañana.
  @override
  Future<List<Map<String, dynamic>>> fetchUnreadMessages(String adopterId) =>
      _client
          .from('messages')
          .select('thread_id, created_at')
          .isFilter('read_at', null)
          .neq('sender_id', adopterId)
          .order('created_at', ascending: false);

  // Va por RPC y no por un `update` directo: `messages` no tiene ninguna
  // policy de UPDATE para adoptantes, así que un update desde el cliente
  // afecta 0 filas y NO tira error. El bug más silencioso posible.
  @override
  Future<void> markThreadRead(String threadId) async {
    await _client.rpc<void>(
      'mark_thread_read',
      params: {'p_thread_id': threadId},
    );
  }

  @override
  String getPublicDogPhotoUrl(String storagePath) =>
      _client.storage.from('dog-images').getPublicUrl(storagePath);

  @override
  Future<void> insertMessage(Map<String, dynamic> values) async {
    await _client.from('messages').insert(values);
  }

  @override
  Future<void> updateThreadTimestamp(String threadId, String timestamp) async {
    await _client
        .from('conversation_threads')
        .update({'last_message_at': timestamp, 'updated_at': timestamp})
        .eq('id', threadId);
  }
}

class SupabaseMessagesRepository implements MessagesRepository {
  SupabaseMessagesRepository(SupabaseClient client)
    : _source = SupabaseMessagesDataSource(client);

  SupabaseMessagesRepository.withDataSource(MessagesDataSource source)
    : _source = source;

  static const maxMessageLength = 1000;

  final MessagesDataSource _source;

  @override
  Future<List<ConversationThread>> fetchMyThreads() async {
    final userId = _requireUserId();
    try {
      final rows = await _source.fetchThreads(userId);
      final threads = <ConversationThread>[];
      for (final row in rows) {
        final latest = await _source.fetchLatestMessage(row['id'] as String);
        threads.add(
          ConversationThread.fromJson(
            row,
            dogPhotoUrlBuilder: _source.getPublicDogPhotoUrl,
            lastMessagePreview: _previewFromLatestMessage(latest),
          ),
        );
      }
      return threads;
    } catch (error, stackTrace) {
      throw _loadError(error, stackTrace);
    }
  }

  @override
  Future<ConversationThread> fetchThreadById(String threadId) async {
    final userId = _requireUserId();
    try {
      final row = await _source.fetchThread(threadId, userId);
      final latest = await _source.fetchLatestMessage(threadId);
      return ConversationThread.fromJson(
        row,
        dogPhotoUrlBuilder: _source.getPublicDogPhotoUrl,
        lastMessagePreview: _previewFromLatestMessage(latest),
      );
    } catch (error, stackTrace) {
      if (error is PostgrestException && error.code == 'PGRST116') {
        throw AppException(
          code: 'conversation_not_found',
          message: 'No pudimos abrir esta conversación.',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      throw AppException(
        code: 'conversation_load',
        message: 'No pudimos abrir esta conversación.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<ConversationThread?> fetchThreadForDog(String dogId) async {
    final userId = _requireUserId();
    try {
      final row = await _source.fetchThreadForDog(dogId, userId);
      if (row == null) return null;
      final threadId = row['id'] as String;
      final latest = await _source.fetchLatestMessage(threadId);
      return ConversationThread.fromJson(
        row,
        dogPhotoUrlBuilder: _source.getPublicDogPhotoUrl,
        lastMessagePreview: _previewFromLatestMessage(latest),
      );
    } catch (error, stackTrace) {
      throw AppException(
        code: 'conversation_lookup',
        message: 'No pudimos abrir esta conversación.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<ConversationThread> getOrCreateThreadForDog(String dogId) async {
    final userId = _requireUserId();
    try {
      final existing = await _source.fetchThreadForDog(dogId, userId);
      if (existing != null) return _threadFromRow(existing);

      final application = await _source.fetchApplicationForDog(dogId, userId);
      if (application == null) {
        throw const AppException(
          code: 'application_required_for_conversation',
          message: 'Necesitás postular antes de escribir al refugio.',
        );
      }

      try {
        final created = await _source.insertThread({
          'dog_id': dogId,
          'adopter_id': userId,
          'shelter_id': application['shelter_id'] as String,
        });
        return _threadFromRow(created);
      } on PostgrestException catch (error) {
        if (error.code != '23505') rethrow;
        final thread = await _source.fetchThreadForDog(dogId, userId);
        if (thread == null) rethrow;
        return _threadFromRow(thread);
      }
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw AppException(
        code: 'conversation_open',
        message: 'No pudimos abrir esta conversación.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<ConversationThread> getOrCreateInquiryThreadForDog(
    String dogId,
  ) async {
    final userId = _requireUserId();
    try {
      final existing = await _source.fetchThreadForDog(dogId, userId);
      if (existing != null) return _threadFromRow(existing);

      final dogInfo = await _source.fetchDogShelterInfo(dogId);
      if (dogInfo == null) {
        throw const AppException(
          code: 'dog_not_found',
          message: 'No pudimos abrir esta conversación.',
        );
      }

      final shelterId = dogInfo['shelter_id'] as String;
      try {
        final created = await _source.insertThread({
          'dog_id': dogId,
          'adopter_id': userId,
          'shelter_id': shelterId,
        });
        return _threadFromRow(created);
      } on PostgrestException catch (error) {
        if (error.code != '23505') rethrow;
        final thread = await _source.fetchThreadForDog(dogId, userId);
        if (thread == null) rethrow;
        return _threadFromRow(thread);
      }
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw AppException(
        code: 'conversation_open',
        message: 'No pudimos abrir esta conversación.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Message>> fetchMessages(String threadId) async {
    _requireUserId();
    try {
      final rows = await _source.fetchMessages(threadId);
      return rows.map(Message.fromJson).toList();
    } catch (error, stackTrace) {
      throw AppException(
        code: 'messages_load',
        message: 'No pudimos abrir esta conversación.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> sendMessage(String threadId, String body) async {
    final userId = _requireUserId();
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw const AppException(
        code: 'empty_message',
        message: 'Escribí un mensaje antes de enviarlo.',
      );
    }
    if (trimmed.length > maxMessageLength) {
      throw const AppException(
        code: 'message_too_long',
        message: 'El mensaje no puede superar 1.000 caracteres.',
      );
    }

    try {
      await _source.insertMessage({
        'thread_id': threadId,
        'sender_id': userId,
        'body': trimmed,
      });
      await _source.updateThreadTimestamp(
        threadId,
        DateTime.now().toUtc().toIso8601String(),
      );
    } on PostgrestException catch (error, stackTrace) {
      if (error.code == '23514') {
        throw const AppException(
          code: 'message_invalid',
          message: 'El mensaje no puede superar 1.000 caracteres.',
        );
      }
      if (error.code == '42501') {
        throw AppException(
          code: 'message_forbidden',
          message: 'No pudimos enviar tu mensaje.',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      throw _sendError(error, stackTrace);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      throw _sendError(error, stackTrace);
    }
  }

  @override
  Future<List<UnreadThread>> fetchUnreadThreads() async {
    final userId = _requireUserId();
    try {
      final rows = await _source.fetchUnreadMessages(userId);
      final counts = <String, int>{};
      final latest = <String, DateTime>{};
      for (final row in rows) {
        final threadId = row['thread_id'];
        final createdAt = row['created_at'];
        if (threadId is! String || createdAt is! String) continue;
        final at = DateTime.parse(createdAt);
        counts[threadId] = (counts[threadId] ?? 0) + 1;
        final known = latest[threadId];
        if (known == null || at.isAfter(known)) latest[threadId] = at;
      }
      final unread =
          counts.entries
              .map(
                (entry) => UnreadThread(
                  threadId: entry.key,
                  count: entry.value,
                  latestAt: latest[entry.key]!,
                ),
              )
              .toList()
            ..sort((a, b) => b.latestAt.compareTo(a.latestAt));
      return unread;
    } catch (error, stackTrace) {
      throw _loadError(error, stackTrace);
    }
  }

  @override
  Future<void> markThreadRead(String threadId) async {
    _requireUserId();
    try {
      await _source.markThreadRead(threadId);
    } catch (error, stackTrace) {
      throw AppException(
        code: 'messages_mark_read',
        message: 'No pudimos marcar la conversación como leída.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _requireUserId() {
    final userId = _source.currentUserId;
    if (userId == null) {
      throw const AppException(
        code: 'auth_required',
        message: 'Necesitás iniciar sesión para ver tus mensajes.',
      );
    }
    return userId;
  }

  Future<ConversationThread> _threadFromRow(Map<String, dynamic> row) async {
    final threadId = row['id'] as String;
    final latest = await _source.fetchLatestMessage(threadId);
    return ConversationThread.fromJson(
      row,
      dogPhotoUrlBuilder: _source.getPublicDogPhotoUrl,
      lastMessagePreview: _previewFromLatestMessage(latest),
    );
  }

  String? _previewFromLatestMessage(Map<String, dynamic>? row) {
    if (row == null) return null;
    if (row['hidden_by_admin'] == true) {
      return 'Mensaje ocultado por moderación.';
    }
    final body = row['body'];
    if (body is! String) return null;
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length <= 90 ? trimmed : '${trimmed.substring(0, 90)}…';
  }

  AppException _loadError(Object error, StackTrace stackTrace) {
    if (error is AppException) {
      return error;
    }
    return AppException(
      code: 'messages_load',
      message: 'No pudimos cargar tus mensajes.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  AppException _sendError(Object error, StackTrace stackTrace) => AppException(
    code: 'message_send',
    message: 'No pudimos enviar tu mensaje.',
    cause: error,
    stackTrace: stackTrace,
  );
}
