import 'package:controle_de_gastos/data/models/income_model.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

abstract class IncomeRemoteDataSource {
  Future<List<IncomeModel>> getIncomes();
  Future<void> saveIncome(IncomeModel income);
  Future<void> deleteIncome(String id);
}
