import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/data/repositories/expense_repository_impl.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_helpers.dart';

/// Testes TDD para ExpenseRepositoryImpl
///
/// Features cobertas (CLAUDE.md):
/// - Seção 6: Lançamentos — salvar, editar, excluir, filtrar
/// - Seção 6: Soft delete (deleteLocal)
/// - Seção 6: Offline first — salva localmente primeiro
/// - Seção 8: Fluxo principal — salvar → sync
/// - Seção 4.4: CRUD completo de despesas
/// - Seção 5.7: Lista com filtros por categoria, mês, sync status
void main() {
  late ExpenseRepositoryImpl repository;
  late MockExpenseLocalDataSource mockLocal;
  late MockExpenseRemoteDataSource mockRemote;

  setUp(() {
    mockLocal = MockExpenseLocalDataSource();
    mockRemote = MockExpenseRemoteDataSource();
    repository = ExpenseRepositoryImpl(local: mockLocal, remote: mockRemote);
  });

  group('ExpenseRepositoryImpl - saveLocal', () {
    test('deve salvar expense localmente', () async {
      final entity = TestHelpers.createExpenseEntity(id: 'save-1');

      await repository.saveLocal(entity);

      expect(mockLocal.count, 1);
      expect(mockLocal.getById('save-1'), isNotNull);
    });

    test('deve converter entity para model ao salvar', () async {
      final entity = TestHelpers.createExpenseEntity(
        id: 'save-2',
        amount: 99.99,
        category: CategoryEnum.gasolina,
      );

      await repository.saveLocal(entity);

      final saved = mockLocal.getById('save-2');
      expect(saved!.amount, 99.99);
      expect(saved.category, CategoryEnum.gasolina);
    });
  });

  group('ExpenseRepositoryImpl - updateLocal', () {
    test('deve atualizar expense existente', () async {
      final entity = TestHelpers.createExpenseEntity(id: 'upd-1');
      await repository.saveLocal(entity);

      final updated = entity.copyWith(amount: 50.0);
      await repository.updateLocal(updated);

      final result = mockLocal.getById('upd-1');
      expect(result!.amount, 50.0);
    });
  });

  group('ExpenseRepositoryImpl - getAllLocal', () {
    test('deve retornar lista vazia quando não há dados', () async {
      final result = await repository.getAllLocal();
      expect(result, isEmpty);
    });

    test('deve retornar todos os expenses salvos', () async {
      await repository.saveLocal(TestHelpers.createExpenseEntity(id: 'a'));
      await repository.saveLocal(TestHelpers.createExpenseEntity(id: 'b'));
      await repository.saveLocal(TestHelpers.createExpenseEntity(id: 'c'));

      final result = await repository.getAllLocal();
      expect(result, hasLength(3));
    });

    test('deve retornar expenses ordenados por data decrescente', () async {
      final older = TestHelpers.createExpenseEntity(
        id: 'old',
        dateTime: DateTime(2026, 1, 1),
      );
      final newer = TestHelpers.createExpenseEntity(
        id: 'new',
        dateTime: DateTime(2026, 4, 10),
      );

      await repository.saveLocal(older);
      await repository.saveLocal(newer);

      final result = await repository.getAllLocal();
      expect(result.first.id, 'new');
      expect(result.last.id, 'old');
    });
  });

  group('ExpenseRepositoryImpl - getByMonth (CLAUDE.md Seção 5.7)', () {
    test('deve retornar apenas expenses do mês solicitado', () async {
      final expenses = TestHelpers.createMultiMonthExpenses();
      for (final e in expenses) {
        await repository.saveLocal(e);
      }

      final abril = await repository.getByMonth(2026, 4);
      expect(abril, hasLength(2));
      for (final e in abril) {
        expect(e.dateTime.month, 4);
      }
    });

    test('deve retornar lista vazia para mês sem dados', () async {
      final expenses = TestHelpers.createMultiMonthExpenses();
      for (final e in expenses) {
        await repository.saveLocal(e);
      }

      final maio = await repository.getByMonth(2026, 5);
      expect(maio, isEmpty);
    });

    test('deve filtrar por ano e mês corretamente', () async {
      final e2025 = TestHelpers.createExpenseEntity(
        id: '2025-1',
        dateTime: DateTime(2025, 4, 10),
      );
      final e2026 = TestHelpers.createExpenseEntity(
        id: '2026-1',
        dateTime: DateTime(2026, 4, 10),
      );

      await repository.saveLocal(e2025);
      await repository.saveLocal(e2026);

      final result = await repository.getByMonth(2026, 4);
      expect(result, hasLength(1));
      expect(result.first.id, '2026-1');
    });
  });

  group('ExpenseRepositoryImpl - getByCategory (CLAUDE.md Seção 5.7)', () {
    test('deve retornar apenas expenses da categoria solicitada', () async {
      final expenses = TestHelpers.createExpenseList();
      for (final e in expenses) {
        await repository.saveLocal(e);
      }

      final alimentacao =
          await repository.getByCategory(CategoryEnum.alimentacao);
      for (final e in alimentacao) {
        expect(e.category, CategoryEnum.alimentacao);
      }
    });

    test('deve retornar lista vazia para categoria sem dados', () async {
      await repository.saveLocal(TestHelpers.createExpenseEntity(
        category: CategoryEnum.alimentacao,
      ));

      final educacao =
          await repository.getByCategory(CategoryEnum.educacao);
      expect(educacao, isEmpty);
    });
  });

  group('ExpenseRepositoryImpl - getPendingSync', () {
    test('deve retornar expenses pendentes e com falha', () async {
      await repository.saveLocal(TestHelpers.createExpenseEntity(
        id: 'p1',
        syncStatus: SyncStatus.pending,
      ));
      await repository.saveLocal(TestHelpers.createExpenseEntity(
        id: 'f1',
        syncStatus: SyncStatus.failed,
      ));
      await repository.saveLocal(TestHelpers.createSyncedExpense(id: 's1'));

      final pending = await repository.getPendingSync();
      expect(pending, hasLength(2));
    });

    test('não deve incluir expenses sincronizados', () async {
      await repository.saveLocal(TestHelpers.createSyncedExpense(id: 's1'));
      await repository.saveLocal(TestHelpers.createSyncedExpense(id: 's2'));

      final pending = await repository.getPendingSync();
      expect(pending, isEmpty);
    });
  });

  group('ExpenseRepositoryImpl - getBySyncStatus', () {
    test('deve filtrar por SyncStatus.pending', () async {
      await repository.saveLocal(TestHelpers.createExpenseEntity(
        id: 'p1',
        syncStatus: SyncStatus.pending,
      ));
      await repository.saveLocal(TestHelpers.createSyncedExpense(id: 's1'));

      final result =
          await repository.getBySyncStatus(SyncStatus.pending);
      expect(result, hasLength(1));
      expect(result.first.syncStatus, SyncStatus.pending);
    });

    test('deve filtrar por SyncStatus.failed', () async {
      await repository.saveLocal(TestHelpers.createFailedExpense(id: 'f1'));
      await repository.saveLocal(TestHelpers.createExpenseEntity(id: 'p1'));

      final result =
          await repository.getBySyncStatus(SyncStatus.failed);
      expect(result, hasLength(1));
      expect(result.first.syncStatus, SyncStatus.failed);
    });
  });

  group('ExpenseRepositoryImpl - syncToRemote (CLAUDE.md Seção 8)', () {
    test('deve enviar expense para o remote e atualizar status', () async {
      final entity = TestHelpers.createExpenseEntity(
        id: 'sync-1',
        syncStatus: SyncStatus.pending,
      );
      await repository.saveLocal(entity);

      final success = await repository.syncToRemote(entity);

      expect(success, isTrue);
      expect(mockRemote.sentExpenses, hasLength(1));
    });

    test('deve retornar false se expense não existe localmente', () async {
      final entity = TestHelpers.createExpenseEntity(id: 'inexistente');

      final success = await repository.syncToRemote(entity);

      expect(success, isFalse);
    });

    test('deve retornar false se remote falhar', () async {
      mockRemote.shouldFail = true;
      final entity = TestHelpers.createExpenseEntity(id: 'sync-fail');
      await repository.saveLocal(entity);

      final success = await repository.syncToRemote(entity);

      expect(success, isFalse);
    });

    test('deve atualizar model com resultado do sync', () async {
      final entity = TestHelpers.createExpenseEntity(
        id: 'sync-update',
        syncStatus: SyncStatus.pending,
      );
      await repository.saveLocal(entity);

      await repository.syncToRemote(entity);

      final model = mockLocal.getById('sync-update');
      expect(model!.syncStatus, SyncStatus.synced);
      expect(model.remoteId, 'remote-sync-update');
      expect(model.lastSyncAttemptAt, isNotNull);
    });
  });

  group('ExpenseRepositoryImpl - deleteLocal (Soft delete - CLAUDE.md Seção 6)', () {
    test('deve remover expense do armazenamento local', () async {
      await repository.saveLocal(
          TestHelpers.createExpenseEntity(id: 'del-1'));

      await repository.deleteLocal('del-1');

      expect(mockLocal.getById('del-1'), isNull);
      expect(mockLocal.count, 0);
    });

    test('deve suportar deleção de ID inexistente sem erro', () async {
      // Não deve lançar exceção
      await repository.deleteLocal('inexistente');
    });
  });

  group('ExpenseRepositoryImpl - deleteLocalAndRemote (CLAUDE.md Seção 6)', () {
    test('deve deletar local E remoto', () async {
      await repository.saveLocal(
          TestHelpers.createExpenseEntity(id: 'del-both'));

      await repository.deleteLocalAndRemote('del-both');

      expect(mockLocal.getById('del-both'), isNull);
      expect(mockRemote.deletedIds, contains('del-both'));
    });

    test('deve deletar local mesmo se remoto falhar (offline first)', () async {
      mockRemote.shouldFail = true;
      await repository.saveLocal(
          TestHelpers.createExpenseEntity(id: 'del-offline'));

      await repository.deleteLocalAndRemote('del-offline');

      // Local deve ter sido removido
      expect(mockLocal.getById('del-offline'), isNull);
    });
  });
}
