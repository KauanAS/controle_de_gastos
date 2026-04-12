import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/domain/mappers/expense_mapper.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import '../../helpers/test_helpers.dart';

/// Testes TDD para ExpenseMapper
///
/// Features cobertas (CLAUDE.md):
/// - Seção 13: Camadas — mapeamento entre Domain e Data
/// - Seção 2: Separação Model (Hive) ↔ Entity (domain)
/// - Seção 6: Integridade dos dados na conversão
void main() {
  group('ExpenseMapper - toEntity (Model → Entity)', () {
    test('deve converter model para entity preservando todos os campos', () {
      final model = TestHelpers.createExpenseModel(
        id: 'model-1',
        amount: 99.99,
        category: CategoryEnum.gasolina,
        paymentMethod: PaymentMethod.credito,
        originalText: '99,99 gasolina crédito',
        syncStatus: SyncStatus.pending,
      );

      final entity = ExpenseMapper.toEntity(model);

      expect(entity, isA<ExpenseEntity>());
      expect(entity.id, 'model-1');
      expect(entity.amount, 99.99);
      expect(entity.category, CategoryEnum.gasolina);
      expect(entity.paymentMethod, PaymentMethod.credito);
      expect(entity.originalText, '99,99 gasolina crédito');
      expect(entity.syncStatus, SyncStatus.pending);
    });

    test('deve converter campos opcionais null corretamente', () {
      final model = TestHelpers.createExpenseModel(
        lastSyncAttemptAt: null,
        syncErrorMessage: null,
        remoteId: null,
      );

      final entity = ExpenseMapper.toEntity(model);

      expect(entity.lastSyncAttemptAt, isNull);
      expect(entity.syncErrorMessage, isNull);
      expect(entity.remoteId, isNull);
    });

    test('deve converter campos opcionais preenchidos corretamente', () {
      final syncTime = DateTime(2026, 4, 10, 14, 0);
      final model = TestHelpers.createExpenseModel(
        syncStatus: SyncStatus.synced,
        lastSyncAttemptAt: syncTime,
        remoteId: 'remote-abc',
      );

      final entity = ExpenseMapper.toEntity(model);

      expect(entity.syncStatus, SyncStatus.synced);
      expect(entity.lastSyncAttemptAt, syncTime);
      expect(entity.remoteId, 'remote-abc');
    });

    test('deve preservar dateTime e createdAt na conversão', () {
      final dt = DateTime(2026, 3, 15, 10, 30);
      final ct = DateTime(2026, 3, 15, 10, 30, 5);
      final model = TestHelpers.createExpenseModel(
        dateTime: dt,
        createdAt: ct,
      );

      final entity = ExpenseMapper.toEntity(model);

      expect(entity.dateTime, dt);
      expect(entity.createdAt, ct);
    });
  });

  group('ExpenseMapper - toModel (Entity → Model)', () {
    test('deve converter entity para model preservando todos os campos', () {
      final entity = TestHelpers.createExpenseEntity(
        id: 'entity-1',
        amount: 150.00,
        category: CategoryEnum.mercado,
        paymentMethod: PaymentMethod.debito,
        originalText: '150 mercado débito',
        syncStatus: SyncStatus.pending,
      );

      final model = ExpenseMapper.toModel(entity);

      expect(model.id, 'entity-1');
      expect(model.amount, 150.00);
      expect(model.category, CategoryEnum.mercado);
      expect(model.paymentMethod, PaymentMethod.debito);
      expect(model.originalText, '150 mercado débito');
      expect(model.syncStatus, SyncStatus.pending);
    });

    test('deve converter campos opcionais corretamente', () {
      final entity = TestHelpers.createExpenseEntity(
        remoteId: 'remote-xyz',
        syncErrorMessage: null,
      );

      final model = ExpenseMapper.toModel(entity);

      expect(model.remoteId, 'remote-xyz');
      expect(model.syncErrorMessage, isNull);
    });
  });

  group('ExpenseMapper - Roundtrip (Entity → Model → Entity)', () {
    test('roundtrip deve preservar todos os dados', () {
      final original = TestHelpers.createExpenseEntity(
        id: 'roundtrip-1',
        amount: 75.50,
        category: CategoryEnum.lazer,
        paymentMethod: PaymentMethod.pix,
        originalText: '75,50 cinema pix',
        syncStatus: SyncStatus.synced,
        remoteId: 'remote-rt1',
      );

      final model = ExpenseMapper.toModel(original);
      final restored = ExpenseMapper.toEntity(model);

      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.category, original.category);
      expect(restored.paymentMethod, original.paymentMethod);
      expect(restored.originalText, original.originalText);
      expect(restored.syncStatus, original.syncStatus);
      expect(restored.remoteId, original.remoteId);
      expect(restored.dateTime, original.dateTime);
      expect(restored.createdAt, original.createdAt);
    });
  });

  group('ExpenseMapper - applySyncResult', () {
    test('deve atualizar status para synced com remoteId', () {
      final model = TestHelpers.createExpenseModel(
        syncStatus: SyncStatus.pending,
      );

      ExpenseMapper.applySyncResult(
        model: model,
        status: SyncStatus.synced,
        remoteId: 'remote-sync-1',
      );

      expect(model.syncStatus, SyncStatus.synced);
      expect(model.remoteId, 'remote-sync-1');
      expect(model.lastSyncAttemptAt, isNotNull);
      expect(model.syncErrorMessage, isNull);
    });

    test('deve atualizar status para failed com mensagem de erro', () {
      final model = TestHelpers.createExpenseModel(
        syncStatus: SyncStatus.pending,
      );

      ExpenseMapper.applySyncResult(
        model: model,
        status: SyncStatus.failed,
        errorMessage: 'Timeout de conexão',
      );

      expect(model.syncStatus, SyncStatus.failed);
      expect(model.syncErrorMessage, 'Timeout de conexão');
      expect(model.lastSyncAttemptAt, isNotNull);
      expect(model.remoteId, isNull);
    });

    test('deve atualizar lastSyncAttemptAt para agora', () {
      final model = TestHelpers.createExpenseModel();
      final before = DateTime.now();

      ExpenseMapper.applySyncResult(
        model: model,
        status: SyncStatus.synced,
      );

      final after = DateTime.now();
      expect(model.lastSyncAttemptAt!.millisecondsSinceEpoch,
          greaterThanOrEqualTo(before.millisecondsSinceEpoch));
      expect(model.lastSyncAttemptAt!.millisecondsSinceEpoch,
          lessThanOrEqualTo(after.millisecondsSinceEpoch));
    });
  });
}
