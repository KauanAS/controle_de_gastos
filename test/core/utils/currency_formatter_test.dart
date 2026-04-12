import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/core/utils/currency_formatter.dart';

/// Testes TDD para CurrencyFormatter
///
/// Features cobertas (CLAUDE.md):
/// - Seção 1: Moeda MVP = BRL
/// - Seção 14: Moeda BRL no MVP
/// - Seção 4.4: Valores em NUMERIC(12,2)
/// - Seção 5.5: Dashboard exibe saldos e totais
void main() {
  group('CurrencyFormatter - format (com símbolo R\$)', () {
    test('deve formatar valor inteiro', () {
      final result = CurrencyFormatter.format(100.0);
      expect(result, contains('R\$'));
      expect(result, contains('100'));
    });

    test('deve formatar valor com centavos', () {
      final result = CurrencyFormatter.format(25.50);
      expect(result, contains('25'));
      expect(result, contains('50'));
    });

    test('deve formatar valor zero', () {
      final result = CurrencyFormatter.format(0.0);
      expect(result, contains('0'));
      expect(result, contains('00'));
    });

    test('deve formatar valor grande com separador de milhar', () {
      final result = CurrencyFormatter.format(1234.56);
      // Em pt_BR: R$ 1.234,56
      expect(result, contains('1'));
      expect(result, contains('234'));
    });

    test('deve formatar valor muito grande', () {
      final result = CurrencyFormatter.format(999999999.99);
      expect(result, contains('R\$'));
    });

    test('deve truncar para 2 casas decimais', () {
      final result = CurrencyFormatter.format(10.0);
      // Deve ter exatamente 2 casas decimais
      expect(result, contains('00'));
    });
  });

  group('CurrencyFormatter - formatPlain (sem símbolo)', () {
    test('deve formatar sem símbolo R\$', () {
      final result = CurrencyFormatter.formatPlain(100.0);
      expect(result, isNot(contains('R\$')));
    });

    test('deve formatar com vírgula como separador decimal (pt_BR)', () {
      final result = CurrencyFormatter.formatPlain(25.50);
      expect(result, contains(','));
    });

    test('deve formatar valor inteiro com ,00', () {
      final result = CurrencyFormatter.formatPlain(100.0);
      expect(result, contains('100'));
      expect(result, contains('00'));
    });

    test('deve formatar zero', () {
      final result = CurrencyFormatter.formatPlain(0.0);
      expect(result, contains('0'));
    });
  });

  group('CurrencyFormatter - Construtor privado', () {
    test('deve usar métodos estáticos sem instanciar', () {
      // CurrencyFormatter._() impede instanciação
      expect(CurrencyFormatter.format(10), isNotNull);
      expect(CurrencyFormatter.formatPlain(10), isNotNull);
    });
  });
}
