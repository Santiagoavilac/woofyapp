import 'package:flutter/material.dart';

/// Marca externa que se pinta con su propia identidad y no con la de Woofy.
///
/// Google y Apple ya exigían esto en el login: sus guías de marca prohíben
/// recolorear el logo o reemplazarlo por un ícono genérico. WhatsApp está en
/// la misma bolsa, y de paso el verde es lo que hace que el usuario reconozca
/// el botón antes de leerlo.
enum WoofyBrand {
  whatsapp(
    background: Color(0xFF25D366),
    foreground: Color(0xFFFFFFFF),
    asset: 'assets/images/whatsapp_logo.png',
    fallbackIcon: Icons.chat_rounded,
  );

  const WoofyBrand({
    required this.background,
    required this.foreground,
    required this.asset,
    required this.fallbackIcon,
  });

  final Color background;
  final Color foreground;

  /// Logo oficial. Va como PNG porque el proyecto no usa SVG.
  final String asset;

  /// Si el asset falta el botón tiene que seguir siendo usable, no romperse.
  final IconData fallbackIcon;
}

/// Botón con los colores y el logo de una marca externa.
class WoofyBrandButton extends StatelessWidget {
  const WoofyBrandButton({
    required this.brand,
    required this.label,
    required this.onPressed,
    this.isExpanded = false,
    super.key,
  });

  final WoofyBrand brand;
  final String label;
  final VoidCallback? onPressed;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = FilledButton(
      onPressed: onPressed,
      style: (theme.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
        backgroundColor: WidgetStatePropertyAll(brand.background),
        foregroundColor: WidgetStatePropertyAll(brand.foreground),
        iconColor: WidgetStatePropertyAll(brand.foreground),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            brand.asset,
            width: 20,
            height: 20,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) =>
                Icon(brand.fallbackIcon, size: 20, color: brand.foreground),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );

    if (!isExpanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
