import 'package:flutter/material.dart';
import 'package:mi_app/core/utils/date_formatters.dart';
import 'package:mi_app/features/dogs/data/dog_models.dart';
import 'package:mi_app/shared/widgets/woofy_card.dart';

class DogMedicalEventsSection extends StatelessWidget {
  const DogMedicalEventsSection({required this.events, super.key});

  final List<DogMedicalEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return WoofyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial médico',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < events.length; index++) ...[
            if (index > 0) const Divider(height: 28),
            _MedicalEvent(event: events[index]),
          ],
        ],
      ),
    );
  }
}

class _MedicalEvent extends StatelessWidget {
  const _MedicalEvent({required this.event});

  final DogMedicalEvent event;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(event.title, style: Theme.of(context).textTheme.titleMedium),
        if (event.eventType != null || event.eventDate != null) ...[
          const SizedBox(height: 4),
          Text(
            [
              event.eventType,
              if (event.eventDate != null)
                DateFormatters.longSpanish(event.eventDate!),
            ].whereType<String>().join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (event.description case final description?) ...[
          const SizedBox(height: 6),
          Text(description),
        ],
      ],
    );
  }
}
