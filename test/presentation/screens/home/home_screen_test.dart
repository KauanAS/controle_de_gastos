import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:controle_de_gastos/presentation/screens/home/home_screen.dart';
import 'package:controle_de_gastos/presentation/providers/expense_providers.dart';
import 'package:controle_de_gastos/presentation/widgets/monthly_summary_card.dart';
import 'package:controle_de_gastos/presentation/widgets/expense_list_tile.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  group('HomeScreen', () {
    testWidgets('deve renderizar AppBar com título "Gastos"', (tester) async {
      final mockRepo = MockExpenseRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gastos'), findsOneWidget);
    });

    testWidgets('deve exibir empty state quando não há lançamentos', (tester) async {
      final mockRepo = MockExpenseRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nenhum lançamento ainda'), findsOneWidget);
    });

    testWidgets('deve exibir FAB com ícone de adição', (tester) async {
      final mockRepo = MockExpenseRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('deve exibir lançamentos quando houver dados', (tester) async {
      final expense = ExpenseEntity(
        id: 'test-1',
        amount: 49.90,
        category: CategoryEnum.alimentacao,
        paymentMethod: PaymentMethod.pix,
        originalText: 'Almoço no restaurante',
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
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Almoço no restaurante'), findsOneWidget);
      // O valor "49,90" aparece no tile E no card de resumo — findsWidgets é correto
      expect(find.textContaining('49,90'), findsWidgets);
      expect(find.text('Nenhum lançamento ainda'), findsNothing);
    });

    testWidgets('deve exibir MonthlySummaryCard com dados do mês', (tester) async {
      final expense = ExpenseEntity(
        id: 'test-summary',
        amount: 100.00,
        category: CategoryEnum.moradia,
        paymentMethod: PaymentMethod.debito,
        originalText: 'Conta de luz',
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
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // MonthlySummaryCard deve estar na tela
      expect(find.byType(MonthlySummaryCard), findsOneWidget);
    });

    testWidgets('FAB deve abrir modal com opções "Novo Gasto" e "Nova Receita"', (tester) async {
      final mockRepo = MockExpenseRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Novo Gasto'), findsOneWidget);
      expect(find.text('Nova Receita'), findsOneWidget);
    });

    testWidgets('deve exibir no máximo 20 lançamentos recentes', (tester) async {
      final expenses = List.generate(
        25,
        (i) => ExpenseEntity(
          id: 'expense-$i',
          amount: i * 10.0,
          category: CategoryEnum.lazer,
          paymentMethod: PaymentMethod.credito,
          originalText: 'Gasto $i',
          dateTime: DateTime.now().subtract(Duration(days: i)),
          syncStatus: SyncStatus.synced,
          createdAt: DateTime.now(),
        ),
      );

      final mockRepo = MockExpenseRepository()..seedExpenses(expenses);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll até o final da lista para forçar a renderização de todos os tiles visíveis
      await tester.scrollUntilVisible(
        find.text('Gasto 19'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // "Gasto 19" deve estar na árvore (é o 20º e último item exibido)
      expect(find.text('Gasto 19'), findsOneWidget);

      // "Gasto 20" NÃO deve estar na árvore (foi cortado pelo .take(20))
      expect(find.text('Gasto 20'), findsNothing);
    });
  });
}
