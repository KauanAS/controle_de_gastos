import 'package:controle_de_gastos/data/datasources/local/expense_local_datasource.dart';
import 'package:controle_de_gastos/data/datasources/remote/expense_remote_datasource.dart';
import 'package:controle_de_gastos/domain/mappers/expense_mapper.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource _local;
  final ExpenseRemoteDataSource _remote;

  ExpenseRepositoryImpl({
    required ExpenseLocalDataSource local,
    required ExpenseRemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  @override
  Future<void> saveLocal(ExpenseEntity expense) async {
    await _local.save(ExpenseMapper.toModel(expense));
  }

  @override
  Future<void> updateLocal(ExpenseEntity expense) async {
    await _local.update(ExpenseMapper.toModel(expense));
  }

  @override
  Future<List<ExpenseEntity>> getAllLocal() async {
    return _local.getAll().map(ExpenseMapper.toEntity).toList();
  }

  @override
  Future<List<ExpenseEntity>> getByMonth(int year, int month) async {
    return _local.getByMonth(year, month).map(ExpenseMapper.toEntity).toList();
  }

  @override
  Future<List<ExpenseEntity>> getByCategory(CategoryEnum category) async {
    return _local.getByCategory(category).map(ExpenseMapper.toEntity).toList();
  }

  @override
  Future<List<ExpenseEntity>> getPendingSync() async {
    return _local.getPendingSync().map(ExpenseMapper.toEntity).toList();
  }

  @override
  Future<List<ExpenseEntity>> getBySyncStatus(SyncStatus status) async {
    return _local.getBySyncStatus(status).map(ExpenseMapper.toEntity).toList();
  }

  @override
  Future<bool> syncToRemote(ExpenseEntity expense) async {
    final model = _local.getById(expense.id);
    if (model == null) return false;

    final result = await _remote.sendExpense(model);

    ExpenseMapper.applySyncResult(
      model: model,
      status: result.success ? SyncStatus.synced : SyncStatus.failed,
      errorMessage: result.errorMessage,
      remoteId: result.remoteId,
    );
    await _local.update(model);

    return result.success;
  }

  @override
  Future<void> deleteLocal(String id) async {
    await _local.delete(id);
  }

  /// Apaga o gasto localmente (Hive) E no Supabase.
  /// A exclusão local sempre acontece — mesmo se o Supabase falhar.
  @override
  Future<void> deleteLocalAndRemote(String id) async {
    // 1. Remove do Hive primeiro (offline first — funciona sem internet)
    await _local.delete(id);

    // 2. Tenta remover do Supabase (falha silenciosa — não bloqueia o usuário)
    await _remote.deleteExpense(id);
  }
}
