import 'package:flutter/material.dart';
import 'package:mi_app/features/auth/data/auth_models.dart';
import 'package:mi_app/shared/widgets/woofy_card.dart';

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (_present(profile.fullName))
        _ProfileRow(
          icon: Icons.person_outline_rounded,
          label: 'Nombre',
          value: profile.fullName!,
        ),
      if (_present(profile.email))
        _ProfileRow(
          icon: Icons.email_outlined,
          label: 'Correo',
          value: profile.email!,
        ),
      if (_present(profile.phone))
        _ProfileRow(
          icon: Icons.phone_outlined,
          label: 'Teléfono',
          value: profile.phone!,
        ),
    ];

    return WoofyCard(
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            rows[index],
            if (index != rows.length - 1) const Divider(height: 28),
          ],
        ],
      ),
    );
  }

  static bool _present(String? value) => value?.trim().isNotEmpty ?? false;
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}
