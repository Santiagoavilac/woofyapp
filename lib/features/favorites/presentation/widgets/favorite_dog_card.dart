import 'package:flutter/material.dart';
import 'package:woofy/features/dogs/data/dog_models.dart';
import 'package:woofy/features/dogs/presentation/widgets/dog_card.dart';
import 'package:woofy/features/favorites/presentation/widgets/favorite_toggle_button.dart';

class FavoriteDogCard extends StatelessWidget {
  const FavoriteDogCard({required this.dog, required this.onTap, super.key});

  final Dog dog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DogCard(
    dog: dog,
    onTap: onTap,
    overlay: FavoriteToggleButton(dogId: dog.id),
  );
}
