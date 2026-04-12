import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:controle_de_gastos/presentation/screens/history/history_screen.dart';
import 'package:controle_de_gastos/presentation/providers/expense_providers.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  group('HistoryScreen', () {
    testWidgets('deve renderizar o titulo da appbar, e o empty state quando vazio', (tester) async {
      final mockRepo = MockExpenseRepository();
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Wait for data to load

      // Verify AppBar
      expect(find.text('Histórico'), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget); // filter button
      
      // Verify Empty State
      expect(find.text('Nenhum lançamento encontrado'), findsOneWidget);
      expect(find.text('Adicione seu primeiro gasto.'), findsOneWidget);
    });

    testWidgets('deve exibir os lancamentos fornecidos pelo notifier', (tester) async {
      final expense = ExpenseEntity(
        id: 'expense_123',
        amount: 25.50,
        category: CategoryEnum.alimentacao,
        paymentMethod: PaymentMethod.debito,
        originalText: 'Coxinha',
        dateTime: DateTime.now(),
        syncStatus: SyncStatus.synced,
        createdAt: DateTime.now(),
      );

      final mockRepo = MockExpenseRepository()..seedExpenses([expense]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Nao deve ter empty state
      expect(find.text('Nenhum lançamento encontrado'), findsNothing);

      // Deve ter lista de despesas
      expect(find.text('Coxinha'), findsOneWidget);
      expect(find.textContaining('Alimentação'), findsWidgets);
      expect(find.textContaining('25,50'), findsOneWidget);
    });

    testWidgets('deve abrir o modal de filtro ao clicar na action', (tester) async {
      final mockRepo = MockExpenseRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Toca no filter
      await tester.tap(find.byIcon(Icons.filter_list_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Filtros'), findsOneWidget);
      expect(find.text('Mês'), findsOneWidget);
      expect(find.text('Aplicar filtros'), findsOneWidget);
    });
  });
}
