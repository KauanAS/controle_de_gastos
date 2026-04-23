import 'package:controle_de_gastos/domain/entities/income_entity.dart';

abstract class IncomeRepository {
  Future<List<IncomeEntity>> getIncomes();
  Future<void> saveIncome(IncomeEntity income);
  Future<void> deleteIncome(String id);
  Future<void> syncPendingIncomes();
}
