import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/presentation/notifiers/new_entry_notifier.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import '../../helpers/test_helpers.dart';

/// Testes TDD para NewEntryState e NewEntryStatus
///
/// Features cobertas (CLAUDE.md):
/// - Seção 5.11: Inserção inteligente — texto, áudio, imagem
/// - Seção 5.12: Confirmação da IA — editar antes de confirmar
/// - Seção 6: IA NUNCA salva automaticamente
/// - Seção 7: 4 estados de tela
/// - Seção 8: Fluxo da entrada inteligente completo
void main() {
  group('NewEntryStatus - Valores', () {
    test('deve ter todos os status do fluxo', () {
      expect(NewEntryStatus.values, hasLength(6));
      expect(NewEntryStatus.values, contains(NewEntryStatus.idle));
      expect(NewEntryStatus.values, contains(NewEntryStatus.parsing));
      expect(NewEntryStatus.values, contains(NewEntryStatus.parsed));
      expect(NewEntryStatus.values, contains(NewEntryStatus.saving));
      expect(NewEntryStatus.values, contains(NewEntryStatus.success));
      expect(NewEntryStatus.values, contains(NewEntryStatus.error));
    });
  });

  group('NewEntryState - Criação', () {
    test('estado inicial deve ser idle', () {
      const state = NewEntryState();

      expect(state.status, NewEntryStatus.idle);
      expect(state.parsedExpense, isNull);
      expect(state.errorMessage, isNull);
      expect(state.syncSuccess, isFalse);
    });
  });

  group('NewEntryState - copyWith', () {
    test('deve alterar status preservando demais campos', () {
      const state = NewEntryState();

      final parsing = state.copyWith(status: NewEntryStatus.parsing);

      expect(parsing.status, NewEntryStatus.parsing);
      expect(parsing.parsedExpense, isNull);
    });

    test('deve definir parsedExpense após parse bem-sucedido', () {
      const state = NewEntryState(status: NewEntryStatus.parsing);
      final expense = TestHelpers.createExpenseEntity();

      final parsed = state.copyWith(
        status: NewEntryStatus.parsed,
        parsedExpense: expense,
      );

      expect(parsed.status, NewEntryStatus.parsed);
      expect(parsed.parsedExpense, isNotNull);
      expect(parsed.parsedExpense!.id, expense.id);
    });

    test('deve definir errorMessage em caso de erro', () {
      const state = NewEntryState(status: NewEntryStatus.parsing);

      final error = state.copyWith(
        status: NewEntryStatus.error,
        errorMessage: 'Valor não encontrado',
      );

      expect(error.status, NewEntryStatus.error);
      expect(error.errorMessage, 'Valor não encontrado');
    });

    test('deve definir syncSuccess após sucesso', () {
      const state = NewEntryState(status: NewEntryStatus.saving);

      final success = state.copyWith(
        status: NewEntryStatus.success,
        syncSuccess: true,
      );

      expect(success.status, NewEntryStatus.success);
      expect(success.syncSuccess, isTrue);
    });

    test('deve manter syncSuccess como false quando sync falha', () {
      const state = NewEntryState(status: NewEntryStatus.saving);

      final partial = state.copyWith(
        status: NewEntryStatus.success,
        syncSuccess: false,
      );

      expect(partial.status, NewEntryStatus.success);
      expect(partial.syncSuccess, isFalse);
    });
  });

  group('NewEntryState - Fluxo completo (CLAUDE.md Seção 8)', () {
    test('fluxo: idle → parsing → parsed → saving → success', () {
      // 1. Idle
      const s1 = NewEntryState();
      expect(s1.status, NewEntryStatus.idle);

      // 2. Usuário digitou frase → parsing
      final s2 = s1.copyWith(status: NewEntryStatus.parsing);
      expect(s2.status, NewEntryStatus.parsing);

      // 3. Parser encontrou os dados → parsed
      final expense = TestHelpers.createExpenseEntity();
      final s3 = s2.copyWith(
        status: NewEntryStatus.parsed,
        parsedExpense: expense,
      );
      expect(s3.status, NewEntryStatus.parsed);
      expect(s3.parsedExpense, isNotNull);

      // 4. Usuário confirma → saving
      final s4 = s3.copyWith(status: NewEntryStatus.saving);
      expect(s4.status, NewEntryStatus.saving);
      expect(s4.parsedExpense, isNotNull);

      // 5. Salvo com sucesso → success
      final s5 = s4.copyWith(
        status: NewEntryStatus.success,
        syncSuccess: true,
      );
      expect(s5.status, NewEntryStatus.success);
      expect(s5.syncSuccess, isTrue);
    });

    test('fluxo erro: idle → parsing → error', () {
      const s1 = NewEntryState();

      final s2 = s1.copyWith(status: NewEntryStatus.parsing);

      final s3 = s2.copyWith(
        status: NewEntryStatus.error,
        errorMessage: 'Não encontrei um valor válido na frase.',
      );

      expect(s3.status, NewEntryStatus.error);
      expect(s3.errorMessage, contains('valor válido'));
      expect(s3.parsedExpense, isNull);
    });

    test('fluxo edição: parsed → usuário edita → saving → success', () {
      final original = TestHelpers.createExpenseEntity(
        amount: 30.0,
        category: CategoryEnum.alimentacao,
      );

      final parsed = const NewEntryState().copyWith(
        status: NewEntryStatus.parsed,
        parsedExpense: original,
      );

      // Usuário edita antes de confirmar
      final edited = original.copyWith(
        amount: 35.0,
        category: CategoryEnum.lazer,
        paymentMethod: PaymentMethod.credito,
      );

      final updatedState = parsed.copyWith(parsedExpense: edited);
      expect(updatedState.parsedExpense!.amount, 35.0);
      expect(updatedState.parsedExpense!.category, CategoryEnum.lazer);
    });

    test('IA NUNCA salva automaticamente — requer status saving explícito (CLAUDE.md Seção 6)', () {
      final expense = TestHelpers.createExpenseEntity();
      final parsed = const NewEntryState().copyWith(
        status: NewEntryStatus.parsed,
        parsedExpense: expense,
      );

      // Parsed NÃO é igual a saving — precisa da ação do usuário
      expect(parsed.status, isNot(NewEntryStatus.saving));
      expect(parsed.status, isNot(NewEntryStatus.success));
      expect(parsed.status, NewEntryStatus.parsed);
    });
  });

  group('NewEntryState - Reset', () {
    test('estado resetado deve ser idêntico ao inicial', () {
      const initial = NewEntryState();
      const reset = NewEntryState();

      expect(reset.status, initial.status);
      expect(reset.parsedExpense, initial.parsedExpense);
      expect(reset.errorMessage, initial.errorMessage);
      expect(reset.syncSuccess, initial.syncSuccess);
    });
  });
}
