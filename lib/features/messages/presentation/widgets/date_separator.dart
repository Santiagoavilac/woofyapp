import 'package:flutter/material.dart';
import 'package:woofy/core/theme/woofy_colors.dart';
import 'package:woofy/core/theme/woofy_radius.dart';
import 'package:woofy/core/utils/date_formatters.dart';

/// El corte de día en una conversación.
///
/// Sin esto la charla se lee como un bloque continuo y "hace tres días que no
/// me contestan" no se nota. "Hoy" y "Ayer" en vez de la fecha porque es lo
/// que el ojo entiende sin hacer la cuenta.
class DateSeparator extends StatelessWidget {
  const DateSeparator({required this.date, super.key});

  final DateTime date;

  static String label(DateTime date, {DateTime? now}) {
    final today = _dayOf(now ?? DateTime.now());
    final day = _dayOf(date.toLocal());
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Ayer';
    // Numérica y no "14 de marzo": el formato largo necesita los datos de
    // locale cargados, y esto tiene que poder pintarse en cualquier contexto.
    return DateFormatters.short(day);
  }

  static DateTime _dayOf(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Si dos mensajes caen en días distintos.
  static bool splits(DateTime a, DateTime b) => _dayOf(a) != _dayOf(b);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: WoofyColors.surfaceMuted,
          borderRadius: WoofyRadius.controlAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Text(
            label(date),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
