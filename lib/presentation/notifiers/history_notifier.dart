import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/presentation/providers/expense_providers.dart';
import 'package:controle_de_gastos/data/sync/sync_service.dart';

// ─── Filtro ────────────────────────────────────────────────────────────────

class HistoryFilter {
  final int? year;
  final int? month;
  final CategoryEnum? category;
  final SyncStatus? syncStatus;

  const HistoryFilter({
    this.year,
    this.month,
    this.category,
    this.syncStatus,
  });

  HistoryFilter copyWith({
    int? year,
    int? month,
    CategoryEnum? category,
    SyncStatus? syncStatus,
    bool clearCategory = false,
    bool clearSyncStatus = false,
    bool clearMonth = false,
  }) {
    return HistoryFilter(
      year: year ?? this.year,
      month: clearMonth ? null : (month ?? this.month),
      category: clearCategory ? null : (category ?? this.category),
      syncStatus: clearSyncStatus ? null : (syncStatus ?? this.syncStatus),
    );
  }

  bool get hasActiveFilters =>
      month != null || category != null || syncStatus != null;
}

// ─── Estado ────────────────────────────────────────────────────────────────

class HistoryState {
  final List<ExpenseEntity> expenses;
  final HistoryFilter filter;
  final bool isLoading;
  final String? retryingId;
  final String? deletingId;
  final String? errorMessage;

  const HistoryState({
    this.expenses = const [],
    this.filter = const HistoryFilter(),
    this.isLoading = false,
    this.retryingId,
    this.deletingId,
    this.errorMessage,
  });

  HistoryState copyWith({
    List<ExpenseEntity>? expenses,
    HistoryFilter? filter,
    bool? isLoading,
    String? retryingId,
    String? deletingId,
    String? errorMessage,
    bool clearRetrying = false,
    bool clearDeleting = false,
    bool clearError = false,
  }) {
    return HistoryState(
      expenses: expenses ?? this.expenses,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      retryingId: clearRetrying ? null : (retryingId ?? this.retryingId),
      deletingId: clearDeleting ? null : (deletingId ?? this.deletingId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;

  HistoryNotifier(this._ref) : super(const HistoryState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(expenseRepositoryProvider);
      final filter = state.filter;

      List<ExpenseEntity> all;
      if (filter.month != null && filter.year != null) {
        all = await repo.getByMonth(filter.year!, filter.month!);
      } else {
        all = await repo.getAllLocal();
      }

      if (filter.category != null) {
        all = all.where((e) => e.category == filter.category).toList();
      }
      if (filter.syncStatus != null) {
        all = all.where((e) => e.syncStatus == filter.syncStatus).toList();
      }

      state = state.copyWith(expenses: all, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar histórico: $e',
      );
    }
  }

  void applyFilter(HistoryFilter filter) {
    state = state.copyWith(filter: filter);
    _load();
  }

  void clearFilters() {
    final now = DateTime.now();
    state = state.copyWith(
      filter: HistoryFilter(year: now.year, month: now.month),
    );
    _load();
  }

  /// Exclui o gasto do Hive local E do Supabase.
  /// Remove da lista imediatamente para a UI responder na hora.
  Future<void> deleteExpense(String id) async {
    // Marca como deletando (para feedback visual se quiser)
    state = state.copyWith(deletingId: id);

    // Remove da lista imediatamente — UI responde na hora
    state = state.copyWith(
      expenses: state.expenses.where((e) => e.id != id).toList(),
      clearDeleting: true,
    );

    // Apaga local + remoto em paralelo (não bloqueia a UI)
    final repo = _ref.read(expenseRepositoryProvider);
    await repo.deleteLocalAndRemote(id);

    // Invalida Home para atualizar resumo
    _ref.invalidate(allExpensesProvider);
    _ref.invalidate(currentMonthExpensesProvider);
    _ref.invalidate(monthlySummaryProvider);
  }

  /// Tenta reenviar item com falha ou pendente.
  Future<void> retrySync(ExpenseEntity expense) async {
    state = state.copyWith(retryingId: expense.id, clearError: true);
    final sync = _ref.read(syncServiceProvider);
    await sync.syncOne(expense);

    _ref.invalidate(allExpensesProvider);
    _ref.invalidate(currentMonthExpensesProvider);
    _ref.invalidate(monthlySummaryProvider);

    state = state.copyWith(clearRetrying: true);
    await _load();
  }

  Future<void> refresh() => _load();
}

// ─── Provider ──────────────────────────────────────────────────────────────

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref);
});
