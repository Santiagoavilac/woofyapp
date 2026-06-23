import 'package:flutter/material.dart';
import 'package:mi_app/features/applications/data/application_models.dart';
import 'package:mi_app/shared/widgets/woofy_card.dart';

class ApplicationStatusCard extends StatelessWidget {
  const ApplicationStatusCard({required this.application, super.key});

  final AdoptionApplication application;

  @override
  Widget build(BuildContext context) => WoofyCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.assignment_turned_in_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu postulación',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text('Estado: ${application.status.label}'),
            ],
          ),
        ),
      ],
    ),
  );
}
