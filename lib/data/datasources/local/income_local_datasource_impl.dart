import 'package:hive_flutter/hive_flutter.dart';
import 'package:controle_de_gastos/data/datasources/local/income_local_datasource.dart';
import 'package:controle_de_gastos/data/models/income_model.dart';

class IncomeLocalDataSourceImpl implements IncomeLocalDataSource {
  static const String boxName = 'incomes_box';
  
  Future<Box<IncomeModel>> get _box async => await Hive.openBox<IncomeModel>(boxName);

  @override
  Future<List<IncomeModel>> getIncomes() async {
    final box = await _box;
    return box.values.toList();
  }

  @override
  Future<void> saveIncome(IncomeModel income) async {
    final box = await _box;
    await box.put(income.hiveId, income);
  }

  @override
  Future<void> saveIncomes(List<IncomeModel> incomes) async {
    final box = await _box;
    final Map<String, IncomeModel> map = { for (var e in incomes) e.hiveId : e };
    await box.putAll(map);
  }

  @override
  Future<void> deleteIncome(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  @override
  Future<void> clearAll() async {
    final box = await _box;
    await box.clear();
  }
}
