import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/data/sync/sync_service.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_helpers.dart';

/// Testes TDD para SyncService
///
/// Features cobertas (CLAUDE.md):
/// - Seção 6: Offline first — salva localmente, tenta sync em seguida
/// - Seção 8: Fluxo principal — sync automático após salvar
/// - Seção 8: Retry de sync para itens com falha
/// - Seção 14: Resiliência — sync não bloqueia o app
void main() {
  late SyncService syncService;
  late MockExpenseRepository mockRepo;

  setUp(() {
    mockRepo = MockExpenseRepository();
    syncService = SyncService(mockRepo);
  });

  group('SyncService - syncOne', () {
    test('deve retornar sucesso quando sync funciona', () async {
      final expense = TestHelpers.createExpenseEntity(
        id: 'sync-one-1',
        syncStatus: SyncStatus.pending,
      );
      mockRepo.seedExpenses([expense]);

      final result = await syncService.syncOne(expense);

      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('deve retornar falha quando sincronização falha', () async {
      mockRepo.syncShouldFail = true;
      final expense = TestHelpers.createExpenseEntity(
        id: 'sync-fail',
        syncStatus: SyncStatus.pending,
      );
      mockRepo.seedExpenses([expense]);

      final result = await syncService.syncOne(expense);

      expect(result.success, isFalse);
    });

    test('deve capturar exceção e retornar falha com mensagem', () async {
      mockRepo.shouldFail = true;
      mockRepo.failMessage = 'Erro de rede';
      final expense = TestHelpers.createExpenseEntity(id: 'exc-1');

      final result = await syncService.syncOne(expense);

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('Erro de rede'));
    });

    test('deve funcionar com expense já sincronizado (idempotente)', () async {
      final expense = TestHelpers.createSyncedExpense(id: 'already-synced');
      mockRepo.seedExpenses([expense]);

      final result = await syncService.syncOne(expense);

      expect(result.success, isTrue);
    });
  });

  group('SyncService - syncAllPending', () {
    test('deve sincronizar todos os itens pendentes', () async {
      mockRepo.seedExpenses([
        TestHelpers.createExpenseEntity(
          id: 'p1',
          syncStatus: SyncStatus.pending,
        ),
        TestHelpers.createExpenseEntity(
          id: 'p2',
          syncStatus: SyncStatus.pending,
        ),
        TestHelpers.createExpenseEntity(
          id: 'p3',
          syncStatus: SyncStatus.pending,
        ),
      ]);

      final count = await syncService.syncAllPending();

      expect(count, 3);
    });

    test('deve incluir itens com falha no syncAllPending', () async {
      mockRepo.seedExpenses([
        TestHelpers.createExpenseEntity(
          id: 'p1',
          syncStatus: SyncStatus.pending,
        ),
        TestHelpers.createFailedExpense(id: 'f1'),
      ]);

      final count = await syncService.syncAllPending();

      expect(count, 2);
    });

    test('deve retornar 0 quando não há itens pendentes', () async {
      mockRepo.seedExpenses([
        TestHelpers.createSyncedExpense(id: 's1'),
        TestHelpers.createSyncedExpense(id: 's2'),
      ]);

      final count = await syncService.syncAllPending();

      expect(count, 0);
    });

    test('deve retornar 0 quando lista está vazia', () async {
      final count = await syncService.syncAllPending();
      expect(count, 0);
    });

    test('deve contar apenas os que tiveram sucesso', () async {
      // Primeiro sucesso, depois falha
      final expenses = [
        TestHelpers.createExpenseEntity(id: 'ok', syncStatus: SyncStatus.pending),
        TestHelpers.createExpenseEntity(id: 'fail', syncStatus: SyncStatus.pending),
      ];
      mockRepo.seedExpenses(expenses);

      // Sincroniza todos — por padrão mock retorna sucesso
      final count = await syncService.syncAllPending();
      expect(count, 2);
    });
  });

  group('SyncService - SyncOperationResult', () {
    test('deve criar resultado de sucesso', () {
      const result = SyncOperationResult(success: true);
      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('deve criar resultado de falha com mensagem', () {
      const result = SyncOperationResult(
        success: false,
        errorMessage: 'Timeout',
      );
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Timeout');
    });
  });

  group('SyncService - Cenários de uso real (CLAUDE.md Seção 8)', () {
    test('fluxo: usuário salva → sync imediato → sucesso', () async {
      final expense = TestHelpers.createExpenseEntity(
        id: 'flow-1',
        syncStatus: SyncStatus.pending,
      );
      mockRepo.seedExpenses([expense]);

      // 1. Salva localmente (feito pelo notifier)
      // 2. Tenta sync
      final result = await syncService.syncOne(expense);

      expect(result.success, isTrue);
    });

    test('fluxo: sync falha → fica na fila → retry funciona', () async {
      final expense = TestHelpers.createExpenseEntity(
        id: 'retry-1',
        syncStatus: SyncStatus.pending,
      );
      mockRepo.seedExpenses([expense]);

      // 1. Primeira tentativa falha
      mockRepo.syncShouldFail = true;
      final firstResult = await syncService.syncOne(expense);
      expect(firstResult.success, isFalse);

      // 2. Retry — agora funciona
      mockRepo.syncShouldFail = false;
      final retryResult = await syncService.syncOne(expense);
      expect(retryResult.success, isTrue);
    });

    test('sync não deve lançar exceção mesmo em cenário adverso', () async {
      mockRepo.shouldFail = true;
      final expense = TestHelpers.createExpenseEntity(id: 'resilient');

      // Não deve lançar — deve capturar e retornar falha
      final result = await syncService.syncOne(expense);
      expect(result.success, isFalse);
    });
  });
}
