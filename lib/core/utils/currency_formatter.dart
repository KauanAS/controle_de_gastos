import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  /// Formata um double como moeda brasileira. Ex: 1234.5 → "R$ 1.234,50"
  static String format(double value) => _formatter.format(value);

  /// Formata sem o símbolo. Ex: 1234.5 → "1.234,50"
  static String formatPlain(double value) =>
      NumberFormat('#,##0.00', 'pt_BR').format(value);
}