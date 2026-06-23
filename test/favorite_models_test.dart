import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/features/favorites/data/favorite_models.dart';

void main() {
  test('Favorite.fromJson parses the real favorites columns', () {
    final favorite = Favorite.fromJson({
      'user_id': 'user-1',
      'dog_id': 'dog-1',
      'created_at': '2026-06-21T12:00:00Z',
    });

    expect(favorite.userId, 'user-1');
    expect(favorite.dogId, 'dog-1');
    expect(favorite.createdAt, DateTime.utc(2026, 6, 21, 12));
  });
}
