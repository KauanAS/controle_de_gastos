import 'package:controle_de_gastos/data/datasources/local/income_local_datasource.dart';
import 'package:controle_de_gastos/data/datasources/remote/income_remote_datasource.dart';
import 'package:controle_de_gastos/data/models/income_model.dart';
import 'package:controle_de_gastos/domain/entities/income_entity.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/domain/repositories/income_repository.dart';
class IncomeRepositoryImpl implements IncomeRepository {
  final IncomeLocalDataSource _local;
  final IncomeRemoteDataSource _remote;

  IncomeRepositoryImpl(this._local, this._remote);

  @override
  Future<List<IncomeEntity>> getIncomes() async {
    try {
      final remoteModels = await _remote.getIncomes();
      final localData = await _local.getIncomes();
      final pending = localData.where((e) => e.hiveSyncStatus != SyncStatus.synced).toList();
      
      await _local.clearAll();
      await _local.saveIncomes([...remoteModels, ...pending]);
      
      await syncPendingIncomes();
    } catch (_) {
      // Fallback p/ cache local se servidor falhar
    }
    
    final localModels = await _local.getIncomes();
    localModels.sort((a, b) => b.hiveDateTime.compareTo(a.hiveDateTime));
    return localModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveIncome(IncomeEntity income) async {
    IncomeModel model = IncomeModel.fromEntity(income);

    try {
      await _remote.saveIncome(model);
      model = IncomeModel.fromEntity(income.copyWith(syncStatus: SyncStatus.synced));
    } catch (_) {
      model = IncomeModel.fromEntity(income.copyWith(syncStatus: SyncStatus.pending));
    }
    
    await _local.saveIncome(model);
  }

  @override
  Future<void> deleteIncome(String id) async {
    try {
      await _remote.deleteIncome(id);
    } catch (_) {
      // Ignora erro remoto
    }
    
    await _local.deleteIncome(id);
  }

  @override
  Future<void> syncPendingIncomes() async {
    final localModels = await _local.getIncomes();
    final pendingModels = localModels.where((m) => m.hiveSyncStatus != SyncStatus.synced).toList();

    for (var model in pendingModels) {
      try {
        await _remote.saveIncome(model);
        final syncedModel = IncomeModel.fromEntity(model.toEntity().copyWith(syncStatus: SyncStatus.synced));
        await _local.saveIncome(syncedModel);
      } catch (_) {
        break; // Se falhou um aborta o resto para não causar loops
      }
    }
  }
}
