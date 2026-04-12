import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/presentation/screens/confirmation/confirmation_screen.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  testWidgets('ConfirmationScreen deve exibir campos mockados e o botao salvar', (tester) async {
    final expense = ExpenseEntity(
      id: 'test_123',
      amount: 45.0,
      category: CategoryEnum.alimentacao,
      paymentMethod: PaymentMethod.pix,
      dateTime: DateTime(2023, 10, 15, 14, 30),
      originalText: 'Comida no pix 45 reais',
      syncStatus: SyncStatus.pending,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ConfirmationScreen(expense: expense),
        ),
      ),
    );

    // Texto original
    expect(find.text('"Comida no pix 45 reais"'), findsOneWidget);
    
    // Categorias
    expect(find.textContaining('Alimentação'), findsWidgets);
    
    // Pagamento
    expect(find.textContaining('Pix'), findsWidgets);
    
    // Valor
    expect(find.textContaining('45,00'), findsOneWidget); 
    
    // Botão de salvar
    expect(find.text('Confirmar'), findsOneWidget);
  });
}
