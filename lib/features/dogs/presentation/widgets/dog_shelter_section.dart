import 'package:flutter/material.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';
import 'package:mi_app/shared/widgets/woofy_card.dart';

class DogShelterSection extends StatelessWidget {
  const DogShelterSection({required this.shelter, super.key});

  final DogShelter shelter;

  @override
  Widget build(BuildContext context) {
    final location = [
      shelter.city,
      shelter.address,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    return WoofyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Refugio', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(shelter.name, style: Theme.of(context).textTheme.titleMedium),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(location)),
              ],
            ),
          ],
          if (shelter.description case final description?) ...[
            const SizedBox(height: 10),
            Text(description),
          ],
          if (shelter.locationNotes case final notes?) ...[
            const SizedBox(height: 8),
            Text(notes),
          ],
        ],
      ),
    );
  }
}
