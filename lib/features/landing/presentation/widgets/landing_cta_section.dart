import 'package:flutter/material.dart';
import 'package:mi_app/core/theme/woofy_colors.dart';
import 'package:mi_app/shared/widgets/woofy_button.dart';

class LandingCtaSection extends StatelessWidget {
  const LandingCtaSection({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 590),
        child: Column(
          children: [
            Text(
              'Encontrá a tu próximo mejor amigo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: WoofyColors.white,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Conectamos perritos en adopción con personas listas para darles un hogar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: WoofyColors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: WoofyButton(
                label: 'Ver perros en adopción',
                isExpanded: true,
                onPressed: onPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
