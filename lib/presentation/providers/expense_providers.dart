import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/data/datasources/local/expense_local_datasource.dart';
import 'package:controle_de_gastos/data/datasources/remote/expense_remote_datasource.dart';
import 'package:controle_de_gastos/data/repositories/expense_repository_impl.dart';
import 'package:controle_de_gastos/domain/services/phrase_parser_impl.dart';
import 'package:controle_de_gastos/data/sync/sync_service.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/domain/repositories/expense_repository.dart';
import 'package:controle_de_gastos/domain/services/phrase_parser_service.dart';

// ─── Infraestrutura ────────────────────────────────────────────────────────

final localDataSourceProvider = Provider<ExpenseLocalDataSource>(
  (_) => ExpenseLocalDataSource(),
);

final remoteDataSourceProvider = Provider<ExpenseRemoteDataSource>(
  (_) => ExpenseRemoteDataSource(),
);

// ─── Repository ────────────────────────────────────────────────────────────

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(
    local: ref.watch(localDataSourceProvider),
    remote: ref.watch(remoteDataSourceProvider),
  );
});

// ─── Services ──────────────────────────────────────────────────────────────

final phraseParserProvider = Provider<PhraseParserService>(
  (_) => PhraseParserImpl(),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(expenseRepositoryProvider));
});

// ─── Dados ─────────────────────────────────────────────────────────────────

/// Lista de todos os gastos (usada pela HomeScreen e HistoryScreen).
final allExpensesProvider = FutureProvider<List<ExpenseEntity>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getAllLocal();
});

/// Gastos do mês/ano atual.
final currentMonthExpensesProvider =
    FutureProvider<List<ExpenseEntity>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  return repo.getByMonth(now.year, now.month);
});

/// Resumo financeiro do mês atual.
final monthlySummaryProvider =
    FutureProvider<MonthlySummary>((ref) async {
  final expenses = await ref.watch(currentMonthExpensesProvider.future);
  final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
  final pending = expenses
      .where((e) =>
          e.syncStatus == SyncStatus.pending ||
          e.syncStatus == SyncStatus.failed)
      .length;
  return MonthlySummary(
    total: total,
    count: expenses.length,
    pendingSyncCount: pending,
  );
});

/// Gastos filtrados por categoria (usado na HistoryScreen).
final expensesByCategoryProvider =
    FutureProvider.family<List<ExpenseEntity>, CategoryEnum>(
        (ref, category) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getByCategory(category);
});

/// Gastos filtrados por status de sync.
final expensesBySyncStatusProvider =
    FutureProvider.family<List<ExpenseEntity>, SyncStatus>(
        (ref, status) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getBySyncStatus(status);
});

// ─── Modelo auxiliar ───────────────────────────────────────────────────────

class MonthlySummary {
  final double total;
  final int count;
  final int pendingSyncCount;

  const MonthlySummary({
    required this.total,
    required this.count,
    required this.pendingSyncCount,
  });
}