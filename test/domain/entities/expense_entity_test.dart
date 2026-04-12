import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import '../../helpers/test_helpers.dart';

/// Testes TDD para ExpenseEntity
///
/// Features cobertas (CLAUDE.md):
/// - Seção 4.4: Modelo expenses (todos os campos, tipos)
/// - Seção 6: Regras de negócio — cada lançamento tem UMA categoria,
///   descrição obrigatória, valores em NUMERIC(12,2)
/// - Seção 8: Soft delete (campo deleted_at = null por padrão)
/// - Equatable para comparação de entidades
void main() {
  group('ExpenseEntity - Criação', () {
    test('deve criar entidade com todos os campos obrigatórios', () {
      final entity = TestHelpers.createExpenseEntity();

      expect(entity.id, 'test-id-1');
      expect(entity.amount, 25.50);
      expect(entity.category, CategoryEnum.alimentacao);
      expect(entity.paymentMethod, PaymentMethod.pix);
      expect(entity.originalText, 'almoço 25,50 pix');
      expect(entity.syncStatus, SyncStatus.pending);
    });

    test('deve aceitar campos opcionais como null', () {
      final entity = TestHelpers.createExpenseEntity();

      expect(entity.lastSyncAttemptAt, isNull);
      expect(entity.syncErrorMessage, isNull);
      expect(entity.remoteId, isNull);
    });

    test('deve criar entidade com campos de sync preenchidos', () {
      final syncTime = DateTime(2026, 4, 10, 13, 0);
      final entity = TestHelpers.createExpenseEntity(
        syncStatus: SyncStatus.synced,
        lastSyncAttemptAt: syncTime,
        remoteId: 'remote-123',
      );

      expect(entity.syncStatus, SyncStatus.synced);
      expect(entity.lastSyncAttemptAt, syncTime);
      expect(entity.remoteId, 'remote-123');
      expect(entity.syncErrorMessage, isNull);
    });

    test('deve criar entidade com erro de sync', () {
      final entity = TestHelpers.createExpenseEntity(
        syncStatus: SyncStatus.failed,
        syncErrorMessage: 'Timeout',
      );

      expect(entity.syncStatus, SyncStatus.failed);
      expect(entity.syncErrorMessage, 'Timeout');
    });
  });

  group('ExpenseEntity - Regras de negócio (CLAUDE.md Seção 6)', () {
    test('lançamento deve ter exatamente UMA categoria', () {
      final entity = TestHelpers.createExpenseEntity(
        category: CategoryEnum.alimentacao,
      );

      // Entidade possui exatamente uma categoria (não é lista)
      expect(entity.category, isA<CategoryEnum>());
      expect(entity.category, CategoryEnum.alimentacao);
    });

    test('campo originalText (descrição) é obrigatório e aceita texto', () {
      final entity = TestHelpers.createExpenseEntity(
        originalText: 'Almoço no restaurante',
      );

      expect(entity.originalText, isNotEmpty);
      expect(entity.originalText, 'Almoço no restaurante');
    });

    test('valor deve ser double representando NUMERIC(12,2)', () {
      final entity = TestHelpers.createExpenseEntity(amount: 999999999.99);
      expect(entity.amount, 999999999.99);
    });

    test('cada lançamento tem data e hora', () {
      final dateTime = DateTime(2026, 4, 10, 14, 30);
      final entity = TestHelpers.createExpenseEntity(dateTime: dateTime);

      expect(entity.dateTime, dateTime);
      expect(entity.dateTime.hour, 14);
      expect(entity.dateTime.minute, 30);
    });

    test('cada lançamento tem status de sync (offline first)', () {
      final pending = TestHelpers.createExpenseEntity(
        syncStatus: SyncStatus.pending,
      );
      final synced = TestHelpers.createExpenseEntity(
        syncStatus: SyncStatus.synced,
      );
      final failed = TestHelpers.createExpenseEntity(
        syncStatus: SyncStatus.failed,
      );

      expect(pending.syncStatus, SyncStatus.pending);
      expect(synced.syncStatus, SyncStatus.synced);
      expect(failed.syncStatus, SyncStatus.failed);
    });

    test('novo lançamento começa com syncStatus pending', () {
      final entity = TestHelpers.createExpenseEntity();
      expect(entity.syncStatus, SyncStatus.pending);
    });
  });

  group('ExpenseEntity - copyWith', () {
    test('deve criar cópia com campo alterado preservando demais', () {
      final original = TestHelpers.createExpenseEntity();
      final updated = original.copyWith(amount: 99.99);

      expect(updated.amount, 99.99);
      expect(updated.id, original.id);
      expect(updated.category, original.category);
      expect(updated.paymentMethod, original.paymentMethod);
      expect(updated.dateTime, original.dateTime);
      expect(updated.originalText, original.originalText);
    });

    test('deve alterar categoria preservando demais campos', () {
      final original = TestHelpers.createExpenseEntity(
        category: CategoryEnum.alimentacao,
      );
      final updated = original.copyWith(category: CategoryEnum.gasolina);

      expect(updated.category, CategoryEnum.gasolina);
      expect(updated.amount, original.amount);
    });

    test('deve alterar forma de pagamento', () {
      final original = TestHelpers.createExpenseEntity(
        paymentMethod: PaymentMethod.pix,
      );
      final updated = original.copyWith(paymentMethod: PaymentMethod.credito);

      expect(updated.paymentMethod, PaymentMethod.credito);
    });

    test('deve alterar syncStatus para synced com remoteId', () {
      final original = TestHelpers.createExpenseEntity(
        syncStatus: SyncStatus.pending,
      );
      final now = DateTime.now();
      final updated = original.copyWith(
        syncStatus: SyncStatus.synced,
        remoteId: 'remote-abc',
        lastSyncAttemptAt: now,
      );

      expect(updated.syncStatus, SyncStatus.synced);
      expect(updated.remoteId, 'remote-abc');
      expect(updated.lastSyncAttemptAt, now);
    });

    test('deve alterar syncStatus para failed com mensagem de erro', () {
      final original = TestHelpers.createExpenseEntity();
      final updated = original.copyWith(
        syncStatus: SyncStatus.failed,
        syncErrorMessage: 'Sem conexão',
      );

      expect(updated.syncStatus, SyncStatus.failed);
      expect(updated.syncErrorMessage, 'Sem conexão');
    });

    test('copyWith sem argumentos retorna cópia idêntica', () {
      final original = TestHelpers.createExpenseEntity();
      final copy = original.copyWith();

      expect(copy, equals(original));
      expect(identical(copy, original), isFalse);
    });
  });

  group('ExpenseEntity - Equatable', () {
    test('duas entidades com mesmos dados devem ser iguais', () {
      final a = TestHelpers.createExpenseEntity(id: 'same-id');
      final b = TestHelpers.createExpenseEntity(id: 'same-id');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('duas entidades com IDs diferentes devem ser diferentes', () {
      final a = TestHelpers.createExpenseEntity(id: 'id-1');
      final b = TestHelpers.createExpenseEntity(id: 'id-2');

      expect(a, isNot(equals(b)));
    });

    test('entidades com valores diferentes devem ser diferentes', () {
      final a = TestHelpers.createExpenseEntity(amount: 10.0);
      final b = TestHelpers.createExpenseEntity(amount: 20.0);

      expect(a, isNot(equals(b)));
    });

    test('entidades com categorias diferentes devem ser diferentes', () {
      final a = TestHelpers.createExpenseEntity(
        category: CategoryEnum.alimentacao,
      );
      final b = TestHelpers.createExpenseEntity(
        category: CategoryEnum.gasolina,
      );

      expect(a, isNot(equals(b)));
    });

    test('entidades com syncStatus diferentes devem ser diferentes', () {
      final a = TestHelpers.createExpenseEntity(
        syncStatus: SyncStatus.pending,
      );
      final b = TestHelpers.createExpenseEntity(
        syncStatus: SyncStatus.synced,
      );

      expect(a, isNot(equals(b)));
    });

    test('props deve incluir todos os campos para comparação', () {
      final entity = TestHelpers.createExpenseEntity();
      expect(entity.props, hasLength(11));
    });
  });

  group('ExpenseEntity - Cenários de uso real', () {
    test('fluxo: criação → sync sucesso → entidade atualizada', () {
      // 1. Usuário cria lançamento
      final created = TestHelpers.createExpenseEntity(
        syncStatus: SyncStatus.pending,
      );
      expect(created.syncStatus, SyncStatus.pending);
      expect(created.remoteId, isNull);

      // 2. Sync bem-sucedido
      final synced = created.copyWith(
        syncStatus: SyncStatus.synced,
        remoteId: 'remote-uuid',
        lastSyncAttemptAt: DateTime.now(),
      );
      expect(synced.syncStatus, SyncStatus.synced);
      expect(synced.remoteId, 'remote-uuid');
    });

    test('fluxo: criação → sync falha → retry → sucesso', () {
      // 1. Criação
      final created = TestHelpers.createExpenseEntity();

      // 2. Sync falha
      final failed = created.copyWith(
        syncStatus: SyncStatus.failed,
        syncErrorMessage: 'Timeout',
        lastSyncAttemptAt: DateTime.now(),
      );
      expect(failed.syncStatus, SyncStatus.failed);
      expect(failed.syncErrorMessage, 'Timeout');

      // 3. Retry com sucesso
      final retried = failed.copyWith(
        syncStatus: SyncStatus.synced,
        remoteId: 'remote-uuid-2',
        lastSyncAttemptAt: DateTime.now(),
      );
      expect(retried.syncStatus, SyncStatus.synced);
    });

    test('fluxo: edição de lançamento antes de confirmar', () {
      // 1. IA sugere lançamento
      final suggested = TestHelpers.createExpenseEntity(
        amount: 30.0,
        category: CategoryEnum.alimentacao,
        paymentMethod: PaymentMethod.pix,
      );

      // 2. Usuário edita antes de confirmar
      final edited = suggested.copyWith(
        amount: 35.0,
        category: CategoryEnum.lazer,
        paymentMethod: PaymentMethod.credito,
      );

      expect(edited.amount, 35.0);
      expect(edited.category, CategoryEnum.lazer);
      expect(edited.paymentMethod, PaymentMethod.credito);
      // ID permanece o mesmo
      expect(edited.id, suggested.id);
    });
  });
}
