import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/features/messages/data/message_models.dart';

void main() {
  test('ConversationThread parses real columns and optional relations', () {
    final thread = ConversationThread.fromJson(
      {
        'id': 'thread-1',
        'dog_id': 'dog-1',
        'shelter_id': 'shelter-1',
        'adopter_id': 'user-1',
        'status': 'open',
        'last_message_at': '2026-06-23T10:00:00Z',
        'created_at': '2026-06-22T10:00:00Z',
        'updated_at': '2026-06-23T10:00:00Z',
        'dogs': {
          'name': 'Milo',
          'slug': 'milo-demo',
          'dog_photos': [
            {'storage_path': 'dogs/milo.jpg', 'is_cover': true, 'position': 0},
          ],
        },
        'shelters': {'name': 'Woofy'},
        'profiles': {'full_name': 'Ana', 'email': 'ana@example.com'},
      },
      dogPhotoUrlBuilder: (path) => 'https://cdn.example.com/$path',
      lastMessagePreview: 'Hola refugio',
    );

    expect(thread.id, 'thread-1');
    expect(thread.dogId, 'dog-1');
    expect(thread.shelterId, 'shelter-1');
    expect(thread.adopterId, 'user-1');
    expect(thread.dogName, 'Milo');
    expect(thread.dogSlug, 'milo-demo');
    expect(thread.shelterName, 'Woofy');
    expect(thread.adopterName, 'Ana');
    expect(thread.dogPhotoUrl, 'https://cdn.example.com/dogs/milo.jpg');
    expect(thread.lastMessagePreview, 'Hola refugio');
  });

  test('ConversationThread uses clean fallbacks for missing relations', () {
    final thread = ConversationThread.fromJson({
      'id': 'thread-1',
      'dog_id': 'dog-1',
      'shelter_id': 'shelter-1',
      'adopter_id': 'user-1',
      'status': 'open',
      'created_at': '2026-06-22T10:00:00Z',
      'updated_at': '2026-06-23T10:00:00Z',
      'dogs': null,
      'shelters': null,
    });

    expect(thread.displayDogName, 'Perro');
    expect(thread.displayShelterName, 'Refugio');
    expect(thread.dogPhotoUrl, isNull);
    expect(thread.lastMessagePreview, isNull);
  });

  test('Message parses sender variants and moderation state', () {
    final adopterMessage = Message.fromJson({
      'id': 'message-1',
      'thread_id': 'thread-1',
      'sender_id': 'user-1',
      'sender_shelter_id': null,
      'body': 'Hola',
      'read_at': null,
      'hidden_by_admin': false,
      'created_at': '2026-06-23T10:00:00Z',
      'profiles': {'full_name': 'Ana', 'email': 'ana@example.com'},
    });
    final shelterMessage = Message.fromJson({
      'id': 'message-2',
      'thread_id': 'thread-1',
      'sender_id': null,
      'sender_shelter_id': 'shelter-1',
      'body': 'Oculto',
      'hidden_by_admin': true,
      'created_at': '2026-06-23T10:01:00Z',
    });

    expect(adopterMessage.isMine('user-1'), isTrue);
    expect(adopterMessage.senderName, 'Ana');
    expect(shelterMessage.senderShelterId, 'shelter-1');
    expect(shelterMessage.displayBody, 'Mensaje ocultado por moderación.');
  });
}
