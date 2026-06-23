import 'package:intl/intl.dart';

abstract final class DateFormatters {
  static String short(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  static String longSpanish(DateTime date) =>
      DateFormat("d 'de' MMMM 'de' y", 'es').format(date);
}
