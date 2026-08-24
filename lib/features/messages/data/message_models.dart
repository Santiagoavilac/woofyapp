class ConversationThread {
  const ConversationThread({
    required this.id,
    required this.dogId,
    required this.shelterId,
    required this.adopterId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.dogName,
    this.dogSlug,
    this.dogPhotoUrl,
    this.shelterName,
    this.adopterName,
    this.adopterEmail,
    this.lastMessagePreview,
  });

  factory ConversationThread.fromJson(
    Map<String, dynamic> json, {
    String Function(String storagePath)? dogPhotoUrlBuilder,
    String? lastMessagePreview,
  }) {
    final dogJson = _singleMap(json['dogs']);
    final shelterJson = _singleMap(json['shelters']);
    final profileJson = _singleMap(json['profiles']);
    final photoJson = _firstDogPhoto(dogJson?['dog_photos']);
    final storagePath = _nullableString(photoJson?['storage_path']);
    return ConversationThread(
      id: _string(json['id']),
      dogId: _string(json['dog_id']),
      shelterId: _string(json['shelter_id']),
      adopterId: _string(json['adopter_id']),
      status: _string(json['status']),
      lastMessageAt: _date(json['last_message_at']),
      createdAt:
          _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _date(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      dogName: _nullableString(dogJson?['name']),
      dogSlug: _nullableString(dogJson?['slug']),
      dogPhotoUrl: storagePath == null
          ? null
          : dogPhotoUrlBuilder?.call(storagePath),
      shelterName: _nullableString(shelterJson?['name']),
      adopterName: _nullableString(profileJson?['full_name']),
      adopterEmail: _nullableString(profileJson?['email']),
      lastMessagePreview: _nullableString(lastMessagePreview),
    );
  }

  final String id;
  final String dogId;
  final String shelterId;
  final String adopterId;
  final String status;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? dogName;
  final String? dogSlug;
  final String? dogPhotoUrl;
  final String? shelterName;
  final String? adopterName;
  final String? adopterEmail;
  final String? lastMessagePreview;

  String get displayDogName => _present(dogName) ? dogName! : 'Perro';

  String get displayShelterName =>
      _present(shelterName) ? shelterName! : 'Refugio';

  DateTime get sortDate => lastMessageAt ?? createdAt;
}

class Message {
  const Message({
    required this.id,
    required this.threadId,
    required this.body,
    required this.hiddenByAdmin,
    required this.createdAt,
    this.senderId,
    this.senderShelterId,
    this.readAt,
    this.senderName,
    this.senderEmail,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final profileJson = _singleMap(json['profiles']);
    return Message(
      id: _string(json['id']),
      threadId: _string(json['thread_id']),
      senderId: _nullableString(json['sender_id']),
      senderShelterId: _nullableString(json['sender_shelter_id']),
      body: _string(json['body']),
      readAt: _date(json['read_at']),
      hiddenByAdmin: _bool(json['hidden_by_admin']) ?? false,
      createdAt:
          _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      senderName: _nullableString(profileJson?['full_name']),
      senderEmail: _nullableString(profileJson?['email']),
    );
  }

  final String id;
  final String threadId;
  final String? senderId;
  final String? senderShelterId;
  final String body;
  final DateTime? readAt;
  final bool hiddenByAdmin;
  final DateTime createdAt;
  final String? senderName;
  final String? senderEmail;

  bool isMine(String userId) => senderId == userId;

  String get displayBody =>
      hiddenByAdmin ? 'Mensaje ocultado por moderación.' : body;
}

String _string(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  return '';
}

String? _nullableString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _date(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

bool? _bool(Object? value) => value is bool ? value : null;

Map<String, dynamic>? _singleMap(Object? value) => switch (value) {
  Map<String, dynamic>() => value,
  Map() => value.cast<String, dynamic>(),
  List<dynamic>() when value.isNotEmpty && value.first is Map =>
    (value.first as Map).cast<String, dynamic>(),
  _ => null,
};

List<Map<String, dynamic>> _mapList(Object? value) => switch (value) {
  List<dynamic>() =>
    value.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList(),
  _ => const <Map<String, dynamic>>[],
};

Map<String, dynamic>? _firstDogPhoto(Object? value) {
  final photos = [..._mapList(value)]
    ..sort((a, b) {
      final coverA = a['is_cover'] == true ? 0 : 1;
      final coverB = b['is_cover'] == true ? 0 : 1;
      if (coverA != coverB) return coverA.compareTo(coverB);
      final positionA = a['position'] is int ? a['position'] as int : 0;
      final positionB = b['position'] is int ? b['position'] as int : 0;
      return positionA.compareTo(positionB);
    });
  return photos.isEmpty ? null : photos.first;
}

bool _present(String? value) => value != null && value.trim().isNotEmpty;
