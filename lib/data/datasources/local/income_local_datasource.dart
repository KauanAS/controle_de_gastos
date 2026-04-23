import 'package:controle_de_gastos/data/models/income_model.dart';
import 'package:controle_de_gastos/domain/entities/income_entity.dart';

abstract class IncomeLocalDataSource {
  Future<List<IncomeModel>> getIncomes();
  Future<void> saveIncome(IncomeModel income);
  Future<void> saveIncomes(List<IncomeModel> incomes);
  Future<void> deleteIncome(String id);
  Future<void> clearAll();
}
