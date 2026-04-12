import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
  static final _monthYearFormatter = DateFormat('MMMM yyyy', 'pt_BR');
  static final _shortDateFormatter = DateFormat('dd MMM', 'pt_BR');

  /// Ex: 03/04/2026
  static String formatDate(DateTime date) => _dateFormatter.format(date);

  /// Ex: 03/04/2026 14:30
  static String formatDateTime(DateTime date) => _dateTimeFormatter.format(date);

  /// Ex: abril 2026
  static String formatMonthYear(DateTime date) => _monthYearFormatter.format(date);

  /// Ex: 03 abr
  static String formatShort(DateTime date) => _shortDateFormatter.format(date);

  /// Retorna "Hoje", "Ontem" ou a data formatada
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Hoje';
    if (d == today.subtract(const Duration(days: 1))) return 'Ontem';
    return formatDate(date);
  }
}