import 'package:flutter/material.dart';
import 'package:woofy/features/applications/data/application_models.dart';
import 'package:woofy/shared/widgets/woofy_card.dart';

class ApplicationStatusCard extends StatelessWidget {
  const ApplicationStatusCard({
    required this.application,
    this.action,
    super.key,
  });

  final AdoptionApplication application;
  final Widget? action;

  @override
  Widget build(BuildContext context) => WoofyCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
        if (action != null) ...[
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: action!),
        ],
      ],
    ),
  );
}
