import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

abstract class ExpenseRepository {
  Future<void> saveLocal(ExpenseEntity expense);
  Future<void> updateLocal(ExpenseEntity expense);
  Future<List<ExpenseEntity>> getAllLocal();
  Future<List<ExpenseEntity>> getByMonth(int year, int month);
  Future<List<ExpenseEntity>> getByCategory(CategoryEnum category);
  Future<List<ExpenseEntity>> getPendingSync();
  Future<bool> syncToRemote(ExpenseEntity expense);

  /// Remove apenas do armazenamento local (Hive).
  Future<void> deleteLocal(String id);

  /// Remove do armazenamento local E do Supabase.
  Future<void> deleteLocalAndRemote(String id);

  Future<List<ExpenseEntity>> getBySyncStatus(SyncStatus status);
}
