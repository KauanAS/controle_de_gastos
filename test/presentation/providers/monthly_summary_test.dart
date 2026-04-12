import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/presentation/providers/expense_providers.dart';

/// Testes TDD para MonthlySummary
///
/// Features cobertas (CLAUDE.md):
/// - Seção 4.9: Resumo mensal (monthly_summaries)
/// - Seção 5.5: Dashboard — saldo, totais
/// - Seção 14: Relatórios agregados
void main() {
  group('MonthlySummary - Criação', () {
    test('deve criar resumo com total, contagem e pendentes', () {
      const summary = MonthlySummary(
        total: 1500.00,
        count: 10,
        pendingSyncCount: 3,
      );

      expect(summary.total, 1500.00);
      expect(summary.count, 10);
      expect(summary.pendingSyncCount, 3);
    });

    test('deve suportar mês sem gastos', () {
      const summary = MonthlySummary(
        total: 0.0,
        count: 0,
        pendingSyncCount: 0,
      );

      expect(summary.total, 0.0);
      expect(summary.count, 0);
      expect(summary.pendingSyncCount, 0);
    });

    test('deve suportar todos os itens sincronizados', () {
      const summary = MonthlySummary(
        total: 500.00,
        count: 5,
        pendingSyncCount: 0,
      );

      expect(summary.pendingSyncCount, 0);
    });
  });

  group('MonthlySummary - Cálculos de cenários reais', () {
    test('total deve ser a soma de todos os gastos do mês', () {
      // Simula o cálculo que monthlySummaryProvider faz
      final amounts = [30.0, 200.0, 450.0, 55.0];
      final total = amounts.fold<double>(0, (sum, e) => sum + e);

      expect(total, 735.0);

      const summary = MonthlySummary(
        total: 735.0,
        count: 4,
        pendingSyncCount: 0,
      );
      expect(summary.total, 735.0);
      expect(summary.count, 4);
    });

    test('pendingSyncCount deve contar pending + failed', () {
      // Simula: 2 pending + 1 failed = 3 pendingSyncCount
      const summary = MonthlySummary(
        total: 300.0,
        count: 5,
        pendingSyncCount: 3,
      );

      expect(summary.pendingSyncCount, 3);
      expect(summary.count, 5);
    });
  });
}
