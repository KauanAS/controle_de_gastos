import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/domain/models/expense_model.dart';
import 'package:controle_de_gastos/domain/repositories/expense_repository.dart';
import 'package:controle_de_gastos/domain/services/phrase_parser_service.dart';
import 'package:controle_de_gastos/data/datasources/local/expense_local_datasource.dart';
import 'package:controle_de_gastos/data/datasources/remote/expense_remote_datasource.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Mock: ExpenseRepository
// ═══════════════════════════════════════════════════════════════════════════

class MockExpenseRepository implements ExpenseRepository {
  final List<ExpenseEntity> _storage = [];
  bool shouldFail = false;
  String failMessage = 'Erro simulado';
  bool syncShouldFail = false;

  List<ExpenseEntity> get storage => List.unmodifiable(_storage);

  void seedExpenses(List<ExpenseEntity> expenses) {
    _storage
      ..clear()
      ..addAll(expenses);
  }

  @override
  Future<void> saveLocal(ExpenseEntity expense) async {
    if (shouldFail) throw Exception(failMessage);
    _storage.add(expense);
  }

  @override
  Future<void> updateLocal(ExpenseEntity expense) async {
    if (shouldFail) throw Exception(failMessage);
    final index = _storage.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _storage[index] = expense;
    }
  }

  @override
  Future<List<ExpenseEntity>> getAllLocal() async {
    if (shouldFail) throw Exception(failMessage);
    return List.from(_storage)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Future<List<ExpenseEntity>> getByMonth(int year, int month) async {
    if (shouldFail) throw Exception(failMessage);
    return _storage
        .where((e) => e.dateTime.year == year && e.dateTime.month == month)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Future<List<ExpenseEntity>> getByCategory(CategoryEnum category) async {
    if (shouldFail) throw Exception(failMessage);
    return _storage.where((e) => e.category == category).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Future<List<ExpenseEntity>> getPendingSync() async {
    if (shouldFail) throw Exception(failMessage);
    return _storage
        .where((e) =>
            e.syncStatus == SyncStatus.pending ||
            e.syncStatus == SyncStatus.failed)
        .toList();
  }

  @override
  Future<List<ExpenseEntity>> getBySyncStatus(SyncStatus status) async {
    if (shouldFail) throw Exception(failMessage);
    return _storage.where((e) => e.syncStatus == status).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Future<bool> syncToRemote(ExpenseEntity expense) async {
    if (shouldFail) throw Exception(failMessage);
    if (syncShouldFail) return false;
    final index = _storage.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _storage[index] = expense.copyWith(
        syncStatus: SyncStatus.synced,
        remoteId: 'remote-${expense.id}',
      );
    }
    return true;
  }

  @override
  Future<void> deleteLocal(String id) async {
    if (shouldFail) throw Exception(failMessage);
    _storage.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> deleteLocalAndRemote(String id) async {
    if (shouldFail) throw Exception(failMessage);
    _storage.removeWhere((e) => e.id == id);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Mock: PhraseParserService
// ═══════════════════════════════════════════════════════════════════════════

class MockPhraseParserService implements PhraseParserService {
  ParseResult? nextResult;
  bool shouldFail = false;
  String failMessage = 'Falha no parser';

  @override
  Future<ParseResult> parse(String phrase) async {
    if (shouldFail) {
      return ParseError(failMessage);
    }
    if (nextResult != null) return nextResult!;
    // Default: always return error if no result configured
    return const ParseError('Mock não configurado');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Mock: ExpenseLocalDataSource
// ═══════════════════════════════════════════════════════════════════════════

class MockExpenseLocalDataSource implements ExpenseLocalDataSource {
  final Map<String, ExpenseModel> _storage = {};
  bool shouldFail = false;

  void seedModels(List<ExpenseModel> models) {
    _storage.clear();
    for (final m in models) {
      _storage[m.id] = m;
    }
  }

  @override
  Future<void> save(ExpenseModel model) async {
    if (shouldFail) throw Exception('Erro local');
    _storage[model.id] = model;
  }

  @override
  Future<void> update(ExpenseModel model) async {
    if (shouldFail) throw Exception('Erro local');
    _storage[model.id] = model;
  }

  @override
  List<ExpenseModel> getAll() {
    final list = _storage.values.toList();
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  @override
  List<ExpenseModel> getByMonth(int year, int month) {
    return _storage.values
        .where((e) => e.dateTime.year == year && e.dateTime.month == month)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  List<ExpenseModel> getByCategory(CategoryEnum category) {
    return _storage.values.where((e) => e.category == category).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  List<ExpenseModel> getPendingSync() {
    return _storage.values
        .where((e) =>
            e.syncStatus == SyncStatus.pending ||
            e.syncStatus == SyncStatus.failed)
        .toList();
  }

  @override
  List<ExpenseModel> getBySyncStatus(SyncStatus status) {
    return _storage.values.where((e) => e.syncStatus == status).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  ExpenseModel? getById(String id) => _storage[id];

  @override
  Future<void> delete(String id) async {
    if (shouldFail) throw Exception('Erro local');
    _storage.remove(id);
  }

  @override
  int get count => _storage.length;
}

// ═══════════════════════════════════════════════════════════════════════════
// Mock: ExpenseRemoteDataSource
// ═══════════════════════════════════════════════════════════════════════════

class MockExpenseRemoteDataSource implements ExpenseRemoteDataSource {
  bool shouldFail = false;
  String failMessage = 'Erro remoto';
  final List<String> deletedIds = [];
  final List<ExpenseModel> sentExpenses = [];

  @override
  Future<RemoteSyncResult> sendExpense(ExpenseModel model) async {
    if (shouldFail) {
      return RemoteSyncResult(success: false, errorMessage: failMessage);
    }
    sentExpenses.add(model);
    return RemoteSyncResult(success: true, remoteId: 'remote-${model.id}');
  }

  @override
  Future<bool> deleteExpense(String localId) async {
    if (shouldFail) return false;
    deletedIds.add(localId);
    return true;
  }
}
