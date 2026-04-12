import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/domain/models/expense_model.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import '../../helpers/test_helpers.dart';

/// Testes TDD para ExpenseModel (camada de dados - Hive)
///
/// Features cobertas (CLAUDE.md):
/// - Seção 3: Hive como armazenamento local
/// - Seção 4.4: Modelo de dados expenses
/// - Seção 5: APIs — formato toBackendJson
/// - Seção 17: Nomenclatura — campos do banco em português
void main() {
  group('ExpenseModel - Criação', () {
    test('deve criar model com todos os campos obrigatórios', () {
      final model = TestHelpers.createExpenseModel();

      expect(model.id, 'model-id-1');
      expect(model.amount, 25.50);
      expect(model.category, CategoryEnum.alimentacao);
      expect(model.paymentMethod, PaymentMethod.pix);
      expect(model.originalText, 'almoço 25,50 pix');
      expect(model.syncStatus, SyncStatus.pending);
    });

    test('deve aceitar campos opcionais null', () {
      final model = TestHelpers.createExpenseModel();

      expect(model.lastSyncAttemptAt, isNull);
      expect(model.syncErrorMessage, isNull);
      expect(model.remoteId, isNull);
    });
  });

  group('ExpenseModel - Mutabilidade de campos de sync', () {
    test('syncStatus deve ser mutável (para atualização in-place no Hive)', () {
      final model = TestHelpers.createExpenseModel(
        syncStatus: SyncStatus.pending,
      );

      model.syncStatus = SyncStatus.synced;
      expect(model.syncStatus, SyncStatus.synced);
    });

    test('lastSyncAttemptAt deve ser mutável', () {
      final model = TestHelpers.createExpenseModel();
      final now = DateTime.now();

      model.lastSyncAttemptAt = now;
      expect(model.lastSyncAttemptAt, now);
    });

    test('syncErrorMessage deve ser mutável', () {
      final model = TestHelpers.createExpenseModel();

      model.syncErrorMessage = 'Erro de rede';
      expect(model.syncErrorMessage, 'Erro de rede');
    });

    test('remoteId deve ser mutável', () {
      final model = TestHelpers.createExpenseModel();

      model.remoteId = 'remote-123';
      expect(model.remoteId, 'remote-123');
    });
  });

  group('ExpenseModel - toBackendJson (CLAUDE.md Seção 5)', () {
    test('deve gerar JSON com campos corretos para o backend', () {
      final dt = DateTime(2026, 4, 10, 14, 30);
      final model = TestHelpers.createExpenseModel(
        dateTime: dt,
        category: CategoryEnum.alimentacao,
        amount: 45.50,
        paymentMethod: PaymentMethod.pix,
        originalText: '45,50 almoço pix',
      );

      final json = model.toBackendJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['dataHora'], dt.toIso8601String());
      expect(json['tipo'], 'ALIMENTACAO');
      expect(json['valor'], 45.50);
      expect(json['pagamento'], 'PIX');
      expect(json['textoOriginal'], '45,50 almoço pix');
    });

    test('JSON deve ter exatamente 5 campos', () {
      final model = TestHelpers.createExpenseModel();
      final json = model.toBackendJson();

      expect(json.keys, hasLength(5));
      expect(json.keys, containsAll([
        'dataHora', 'tipo', 'valor', 'pagamento', 'textoOriginal',
      ]));
    });

    test('dataHora deve ser ISO 8601', () {
      final model = TestHelpers.createExpenseModel(
        dateTime: DateTime(2026, 4, 10, 14, 30, 0),
      );

      final json = model.toBackendJson();
      final dataHora = json['dataHora'] as String;

      expect(dataHora, contains('2026'));
      expect(dataHora, contains('T'));
    });

    test('tipo deve ser a backendKey da categoria (UPPERCASE)', () {
      final model = TestHelpers.createExpenseModel(
        category: CategoryEnum.gasolina,
      );

      final json = model.toBackendJson();
      expect(json['tipo'], 'GASOLINA');
    });

    test('pagamento deve ser a backendKey do pagamento (UPPERCASE)', () {
      final model = TestHelpers.createExpenseModel(
        paymentMethod: PaymentMethod.credito,
      );

      final json = model.toBackendJson();
      expect(json['pagamento'], 'CREDITO');
    });

    test('JSON para cada categoria deve usar backendKey correto', () {
      for (final cat in CategoryEnum.values) {
        final model = TestHelpers.createExpenseModel(category: cat);
        final json = model.toBackendJson();
        expect(json['tipo'], cat.backendKey,
            reason: 'backendKey incorreto para ${cat.name}');
      }
    });

    test('JSON para cada forma de pagamento deve usar backendKey correto', () {
      for (final pm in PaymentMethod.values) {
        final model = TestHelpers.createExpenseModel(paymentMethod: pm);
        final json = model.toBackendJson();
        expect(json['pagamento'], pm.backendKey,
            reason: 'backendKey incorreto para ${pm.name}');
      }
    });
  });

  group('ExpenseModel - Cenários de uso', () {
    test('model deve representar um gasto pendente de sync', () {
      final model = TestHelpers.createExpenseModel(
        syncStatus: SyncStatus.pending,
        remoteId: null,
      );

      expect(model.syncStatus, SyncStatus.pending);
      expect(model.remoteId, isNull);
    });

    test('model deve representar um gasto sincronizado', () {
      final model = TestHelpers.createExpenseModel(
        syncStatus: SyncStatus.synced,
        remoteId: 'remote-uuid',
        lastSyncAttemptAt: DateTime.now(),
      );

      expect(model.syncStatus, SyncStatus.synced);
      expect(model.remoteId, isNotNull);
    });

    test('model deve representar um gasto com falha de sync', () {
      final model = TestHelpers.createExpenseModel(
        syncStatus: SyncStatus.failed,
        syncErrorMessage: 'Timeout',
        lastSyncAttemptAt: DateTime.now(),
      );

      expect(model.syncStatus, SyncStatus.failed);
      expect(model.syncErrorMessage, 'Timeout');
    });
  });
}
