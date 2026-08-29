import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/theme/woofy_spacing.dart';

/// Editorial adoption banner. The artwork already carries its own rounded
/// card, copy and paw button, so the widget only makes the whole thing
/// tappable and gives screen readers the message the pixels spell out.
///
/// The torn white edge is part of the art: no [ClipRRect] here, it would
/// shave it off. On the ivory background it reads as a sticker.
class WoofyPromoBanner extends StatelessWidget {
  const WoofyPromoBanner({required this.onTap, super.key});

  /// Intrinsic size of `banner_adoptar.png` (1974x797).
  static const _aspectRatio = 1974 / 797;

  static const _message = 'Adoptar no cuesta nada. Cambia todo.';

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$_message Ver animales en adopción.',
      child: ExcludeSemantics(
        child: InkWell(
          key: const ValueKey('promo-banner'),
          onTap: onTap,
          borderRadius: WoofyRadius.cardLargeAll,
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: Image.asset(
              'assets/images/banner_adoptar.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const _BannerFallback(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown if the asset ever fails to decode, so the home never loses its
/// adoption message.
class _BannerFallback extends StatelessWidget {
  const _BannerFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: WoofyColors.accentSoft,
        borderRadius: WoofyRadius.cardLargeAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(WoofySpacing.lg),
        child: Row(
          children: [
            const Icon(
              Icons.pets_rounded,
              color: WoofyColors.accent,
              size: 32,
            ),
            const SizedBox(width: WoofySpacing.md),
            Expanded(
              child: Text(
                WoofyPromoBanner._message,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
