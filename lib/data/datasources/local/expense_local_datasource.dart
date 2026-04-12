import 'package:hive_flutter/hive_flutter.dart';
import 'package:controle_de_gastos/core/constants/app_constants.dart';
import 'package:controle_de_gastos/domain/models/expense_model.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

/// Responsável por todas as operações de leitura e escrita no Hive.
class ExpenseLocalDataSource {
  Box<ExpenseModel> get _box =>
      Hive.box<ExpenseModel>(AppConstants.hiveBoxExpenses);

  /// Salva ou sobrescreve um gasto pelo ID.
  Future<void> save(ExpenseModel model) async {
    await _box.put(model.id, model);
  }

  /// Atualiza um gasto existente (Hive usa put para upsert).
  Future<void> update(ExpenseModel model) async {
    await _box.put(model.id, model);
  }

  /// Retorna todos os gastos ordenados por data decrescente.
  List<ExpenseModel> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  /// Retorna gastos de um mês/ano específico.
  List<ExpenseModel> getByMonth(int year, int month) {
    return _box.values
        .where((e) => e.dateTime.year == year && e.dateTime.month == month)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Retorna gastos por categoria.
  List<ExpenseModel> getByCategory(CategoryEnum category) {
    return _box.values
        .where((e) => e.category == category)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Retorna gastos pendentes ou com falha de sync.
  List<ExpenseModel> getPendingSync() {
    return _box.values
        .where((e) =>
            e.syncStatus == SyncStatus.pending ||
            e.syncStatus == SyncStatus.failed)
        .toList();
  }

  /// Retorna gastos por status de sync.
  List<ExpenseModel> getBySyncStatus(SyncStatus status) {
    return _box.values.where((e) => e.syncStatus == status).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Busca um gasto pelo ID.
  ExpenseModel? getById(String id) => _box.get(id);

  /// Remove um gasto pelo ID.
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Retorna o total de gastos salvos.
  int get count => _box.length;
}