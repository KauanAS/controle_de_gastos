import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/presentation/notifiers/history_notifier.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import '../../helpers/test_helpers.dart';

/// Testes TDD para HistoryFilter e HistoryState
///
/// Features cobertas (CLAUDE.md):
/// - Seção 5.7: Lista de despesas — filtros por categoria, pagamento, data
/// - Seção 7: Estados de tela (loading, empty, error, success)
/// - Seção 8: Fluxo — visualizar histórico com filtros
void main() {
  group('HistoryFilter - Criação', () {
    test('filtro vazio deve ter todos os campos null', () {
      const filter = HistoryFilter();

      expect(filter.year, isNull);
      expect(filter.month, isNull);
      expect(filter.category, isNull);
      expect(filter.syncStatus, isNull);
    });

    test('deve criar filtro com parâmetros específicos', () {
      const filter = HistoryFilter(
        year: 2026,
        month: 4,
        category: CategoryEnum.alimentacao,
        syncStatus: SyncStatus.pending,
      );

      expect(filter.year, 2026);
      expect(filter.month, 4);
      expect(filter.category, CategoryEnum.alimentacao);
      expect(filter.syncStatus, SyncStatus.pending);
    });
  });

  group('HistoryFilter - hasActiveFilters', () {
    test('filtro vazio não deve ter filtros ativos', () {
      const filter = HistoryFilter();
      expect(filter.hasActiveFilters, isFalse);
    });

    test('filtro com apenas year não deve ter filtros ativos', () {
      const filter = HistoryFilter(year: 2026);
      expect(filter.hasActiveFilters, isFalse);
    });

    test('filtro com month deve ter filtro ativo', () {
      const filter = HistoryFilter(month: 4);
      expect(filter.hasActiveFilters, isTrue);
    });

    test('filtro com category deve ter filtro ativo', () {
      const filter = HistoryFilter(category: CategoryEnum.gasolina);
      expect(filter.hasActiveFilters, isTrue);
    });

    test('filtro com syncStatus deve ter filtro ativo', () {
      const filter = HistoryFilter(syncStatus: SyncStatus.failed);
      expect(filter.hasActiveFilters, isTrue);
    });
  });

  group('HistoryFilter - copyWith', () {
    test('deve alterar mês preservando demais', () {
      const original = HistoryFilter(
        year: 2026,
        month: 3,
        category: CategoryEnum.alimentacao,
      );

      final updated = original.copyWith(month: 4);

      expect(updated.month, 4);
      expect(updated.year, 2026);
      expect(updated.category, CategoryEnum.alimentacao);
    });

    test('deve limpar categoria com clearCategory', () {
      const original = HistoryFilter(
        category: CategoryEnum.alimentacao,
      );

      final updated = original.copyWith(clearCategory: true);

      expect(updated.category, isNull);
    });

    test('deve limpar syncStatus com clearSyncStatus', () {
      const original = HistoryFilter(
        syncStatus: SyncStatus.pending,
      );

      final updated = original.copyWith(clearSyncStatus: true);

      expect(updated.syncStatus, isNull);
    });

    test('deve limpar mês com clearMonth', () {
      const original = HistoryFilter(year: 2026, month: 4);

      final updated = original.copyWith(clearMonth: true);

      expect(updated.month, isNull);
      expect(updated.year, 2026);
    });
  });

  group('HistoryState - Criação', () {
    test('estado inicial deve ter lista vazia e não loading', () {
      const state = HistoryState();

      expect(state.expenses, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.retryingId, isNull);
      expect(state.deletingId, isNull);
      expect(state.errorMessage, isNull);
    });

    test('filtro padrão deve ser vazio', () {
      const state = HistoryState();

      expect(state.filter.year, isNull);
      expect(state.filter.month, isNull);
      expect(state.filter.category, isNull);
    });
  });

  group('HistoryState - copyWith', () {
    test('deve atualizar expenses preservando demais', () {
      const state = HistoryState();
      final expenses = [TestHelpers.createExpenseEntity()];

      final updated = state.copyWith(expenses: expenses);

      expect(updated.expenses, hasLength(1));
      expect(updated.isLoading, isFalse);
    });

    test('deve ativar/desativar loading', () {
      const state = HistoryState();

      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);

      final notLoading = loading.copyWith(isLoading: false);
      expect(notLoading.isLoading, isFalse);
    });

    test('deve marcar retryingId e limpar com clearRetrying', () {
      const state = HistoryState();

      final retrying = state.copyWith(retryingId: 'retry-1');
      expect(retrying.retryingId, 'retry-1');

      final cleared = retrying.copyWith(clearRetrying: true);
      expect(cleared.retryingId, isNull);
    });

    test('deve marcar deletingId e limpar com clearDeleting', () {
      const state = HistoryState();

      final deleting = state.copyWith(deletingId: 'del-1');
      expect(deleting.deletingId, 'del-1');

      final cleared = deleting.copyWith(clearDeleting: true);
      expect(cleared.deletingId, isNull);
    });

    test('deve definir errorMessage e limpar com clearError', () {
      const state = HistoryState();

      final withError = state.copyWith(errorMessage: 'Erro ao carregar');
      expect(withError.errorMessage, 'Erro ao carregar');

      final cleared = withError.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('deve atualizar filtro', () {
      const state = HistoryState();
      const filter = HistoryFilter(year: 2026, month: 4);

      final updated = state.copyWith(filter: filter);

      expect(updated.filter.year, 2026);
      expect(updated.filter.month, 4);
    });
  });

  group('HistoryState - Estados da tela (CLAUDE.md Seção 7)', () {
    test('estado Carregando', () {
      const state = HistoryState(isLoading: true);
      expect(state.isLoading, isTrue);
      expect(state.expenses, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('estado Vazio', () {
      const state = HistoryState(isLoading: false);
      expect(state.isLoading, isFalse);
      expect(state.expenses, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('estado Erro', () {
      const state = HistoryState(
        isLoading: false,
        errorMessage: 'Falha na conexão',
      );
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Falha na conexão');
    });

    test('estado Sucesso', () {
      final state = HistoryState(
        isLoading: false,
        expenses: [TestHelpers.createExpenseEntity()],
      );
      expect(state.isLoading, isFalse);
      expect(state.expenses, isNotEmpty);
      expect(state.errorMessage, isNull);
    });
  });
}
