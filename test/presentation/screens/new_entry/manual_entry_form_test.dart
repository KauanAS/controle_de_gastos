import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/presentation/screens/new_entry/new_entry_screen.dart';

void main() {
  testWidgets('NewEntryScreen deve conter abas para Mágica (IA) e Manual', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NewEntryScreen(),
        ),
      ),
    );

    // Verifica a presenca da TabBar
    expect(find.text('Mágica'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);

    // Na aba inicial (Mágica), deve existir o TextField de descrição e o botão Interpretar
    expect(find.text('Descreva o gasto em português:'), findsOneWidget);
    expect(find.text('Interpretar'), findsOneWidget);

    // Alterna para aba Manual
    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();

    // Na aba Manual, deve existir o formulário manual: Descricao, Valor, Categoria, Pagamento
    expect(find.text('Descrição do gasto'), findsOneWidget);
    expect(find.text('Valor'), findsOneWidget);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Salvar Lançamento'), findsOneWidget);
  });
}
