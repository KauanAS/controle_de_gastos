import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/presentation/screens/new_income/new_income_screen.dart';
import 'package:controle_de_gastos/presentation/notifiers/income_notifier.dart';
import 'package:controle_de_gastos/domain/entities/income_entity.dart';
import 'package:controle_de_gastos/domain/enums/income_category_enum.dart';

class MockIncomeNotifier extends IncomeNotifier {
  MockIncomeNotifier() : super(null) {
    state = const IncomeState(status: IncomeStatus.initial);
  }
}

void main() {
  group('NewIncomeScreen', () {
    testWidgets('deve renderizar os inputs de valor, descricao e botao de cadastro', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incomeNotifierProvider.overrideWith((ref) => MockIncomeNotifier()),
          ],
          child: const MaterialApp(
            home: NewIncomeScreen(),
          ),
        ),
      );

      expect(find.text('Nova Receita'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3)); // Valor, Descrição, Observação
      expect(find.text('Cadastrar Receita'), findsOneWidget);
    });

    testWidgets('quando clicar no cadastro com dados vazios deve mostrar validacao', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incomeNotifierProvider.overrideWith((ref) => MockIncomeNotifier()),
          ],
          child: const MaterialApp(
            home: NewIncomeScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Cadastrar Receita'));
      await tester.pump();

      expect(find.text('Informe um valor'), findsOneWidget);
      expect(find.text('Informe uma descrição'), findsOneWidget);
    });
  });
}
