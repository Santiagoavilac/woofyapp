class Favorite {
  const Favorite({
    required this.userId,
    required this.dogId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
    userId: json['user_id'] as String,
    dogId: json['dog_id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String userId;
  final String dogId;
  final DateTime createdAt;
}
