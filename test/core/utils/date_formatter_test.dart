import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:controle_de_gastos/core/utils/date_formatter.dart';

/// Testes TDD para DateFormatter
///
/// Features cobertas (CLAUDE.md):
/// - Seção 14: Formato de data dd/MM/yyyy, idioma PT-BR
/// - Seção 5.5: Dashboard exibe mês atual
/// - Seção 5.7: Lista com filtro por data
/// - Seção 5.8: Detalhe com data completa
void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });
  group('DateFormatter - formatDate', () {
    test('deve formatar data no padrão dd/MM/yyyy', () {
      final result = DateFormatter.formatDate(DateTime(2026, 4, 3));
      expect(result, '03/04/2026');
    });

    test('deve colocar zero à esquerda em dia e mês', () {
      final result = DateFormatter.formatDate(DateTime(2026, 1, 5));
      expect(result, '05/01/2026');
    });

    test('deve formatar data de dezembro', () {
      final result = DateFormatter.formatDate(DateTime(2026, 12, 31));
      expect(result, '31/12/2026');
    });
  });

  group('DateFormatter - formatDateTime', () {
    test('deve formatar data e hora no padrão dd/MM/yyyy HH:mm', () {
      final result = DateFormatter.formatDateTime(DateTime(2026, 4, 3, 14, 30));
      expect(result, '03/04/2026 14:30');
    });

    test('deve formatar meia-noite corretamente', () {
      final result = DateFormatter.formatDateTime(DateTime(2026, 4, 3, 0, 0));
      expect(result, '03/04/2026 00:00');
    });

    test('deve formatar hora com zero à esquerda', () {
      final result = DateFormatter.formatDateTime(DateTime(2026, 4, 3, 9, 5));
      expect(result, '03/04/2026 09:05');
    });
  });

  group('DateFormatter - formatMonthYear', () {
    test('deve formatar mês e ano em português', () {
      final result = DateFormatter.formatMonthYear(DateTime(2026, 4, 1));
      // Deve conter "abril" (em português) e "2026"
      expect(result.toLowerCase(), contains('abril'));
      expect(result, contains('2026'));
    });

    test('deve formatar janeiro corretamente', () {
      final result = DateFormatter.formatMonthYear(DateTime(2026, 1, 15));
      expect(result.toLowerCase(), contains('janeiro'));
    });

    test('deve formatar dezembro corretamente', () {
      final result = DateFormatter.formatMonthYear(DateTime(2026, 12, 25));
      expect(result.toLowerCase(), contains('dezembro'));
    });
  });

  group('DateFormatter - formatShort', () {
    test('deve formatar como dd MMM', () {
      final result = DateFormatter.formatShort(DateTime(2026, 4, 3));
      expect(result, contains('03'));
    });

    test('resultado deve ser curto (< 10 caracteres)', () {
      final result = DateFormatter.formatShort(DateTime(2026, 4, 3));
      expect(result.length, lessThan(10));
    });
  });

  group('DateFormatter - formatRelative', () {
    test('deve retornar "Hoje" para data de hoje', () {
      final now = DateTime.now();
      final result = DateFormatter.formatRelative(now);
      expect(result, 'Hoje');
    });

    test('deve retornar "Ontem" para data de ontem', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = DateFormatter.formatRelative(yesterday);
      expect(result, 'Ontem');
    });

    test('deve retornar data formatada para anteontem', () {
      final dayBeforeYesterday =
          DateTime.now().subtract(const Duration(days: 2));
      final result = DateFormatter.formatRelative(dayBeforeYesterday);
      // Não deve ser "Hoje" nem "Ontem"
      expect(result, isNot('Hoje'));
      expect(result, isNot('Ontem'));
      // Deve conter '/' (formato dd/MM/yyyy)
      expect(result, contains('/'));
    });

    test('deve retornar data formatada para data futura', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final result = DateFormatter.formatRelative(tomorrow);
      // Amanhã não é "Hoje" nem "Ontem"
      expect(result, isNot('Hoje'));
      expect(result, isNot('Ontem'));
    });

    test('deve ignorar hora ao comparar datas (apenas dia)', () {
      final today = DateTime.now();
      final todayMorning =
          DateTime(today.year, today.month, today.day, 6, 0);
      final todayNight =
          DateTime(today.year, today.month, today.day, 23, 59);

      expect(DateFormatter.formatRelative(todayMorning), 'Hoje');
      expect(DateFormatter.formatRelative(todayNight), 'Hoje');
    });
  });

  group('DateFormatter - Construtor privado', () {
    test('deve usar métodos estáticos sem instanciar', () {
      // DateFormatter._() impede instanciação
      expect(DateFormatter.formatDate(DateTime.now()), isNotNull);
    });
  });
}
