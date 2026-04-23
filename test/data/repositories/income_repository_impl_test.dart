import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/data/repositories/income_repository_impl.dart';
import 'package:controle_de_gastos/data/models/income_model.dart';
import 'package:controle_de_gastos/domain/entities/income_entity.dart';
import 'package:controle_de_gastos/domain/enums/income_category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/data/datasources/local/income_local_datasource.dart';
import 'package:controle_de_gastos/data/datasources/remote/income_remote_datasource.dart';

class MockIncomeLocalDataSource implements IncomeLocalDataSource {
  final List<IncomeModel> storage = [];

  @override
  Future<List<IncomeModel>> getIncomes() async => storage;

  @override
  Future<void> saveIncome(IncomeModel income) async {
    storage.removeWhere((e) => e.hiveId == income.hiveId);
    storage.add(income);
  }

  @override
  Future<void> saveIncomes(List<IncomeModel> incomes) async {
    storage.clear();
    storage.addAll(incomes);
  }

  @override
  Future<void> deleteIncome(String id) async {
    storage.removeWhere((e) => e.hiveId == id);
  }

  @override
  Future<void> clearAll() async => storage.clear();
}

class MockIncomeRemoteDataSource implements IncomeRemoteDataSource {
  bool shouldThrow = false;
  final List<IncomeModel> serverStorage = [];

  @override
  Future<List<IncomeModel>> getIncomes() async {
    if (shouldThrow) throw Exception('No network');
    return serverStorage;
  }

  @override
  Future<void> saveIncome(IncomeModel income) async {
    if (shouldThrow) throw Exception('No network');
    serverStorage.add(income);
  }

  @override
  Future<void> deleteIncome(String id) async {
    if (shouldThrow) throw Exception('No network');
    serverStorage.removeWhere((e) => e.hiveId == id);
  }
}

void main() {
  late IncomeRepositoryImpl repository;
  late MockIncomeLocalDataSource local;
  late MockIncomeRemoteDataSource remote;

  setUp(() {
    local = MockIncomeLocalDataSource();
    remote = MockIncomeRemoteDataSource();
    repository = IncomeRepositoryImpl(local, remote);
  });

  group('IncomeRepositoryImpl - getIncomes', () {
    test('deve retornar dados locais instantaneamente se network falhar e houver dados mantidos em cache local', () async {
      remote.shouldThrow = true;
      final localModel = IncomeModel(
        hiveId: '1', hiveDescription: 'A', hiveAmount: 1, 
        hiveCategory: IncomeCategoryEnum.salario, hiveDateTime: DateTime.now(), 
        hiveSyncStatus: SyncStatus.synced, hiveCreatedAt: DateTime.now(),
      );
      await local.saveIncome(localModel);

      final result = await repository.getIncomes();
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('deve atualizar o banco local com os dados remotos caso tenha net conectada', () async {
      remote.shouldThrow = false;
      final serverModel = IncomeModel(
        hiveId: '2', hiveDescription: 'B', hiveAmount: 2, 
        hiveCategory: IncomeCategoryEnum.rendimento, hiveDateTime: DateTime.now(), 
        hiveSyncStatus: SyncStatus.synced, hiveCreatedAt: DateTime.now(),
      );
      remote.serverStorage.add(serverModel);

      expect((await local.getIncomes()).length, 0);
      final result = await repository.getIncomes();
      expect(result.length, 1);
      expect(result.first.id, '2');
      expect((await local.getIncomes()).length, 1);
    });
  });

  group('IncomeRepositoryImpl - saveIncome', () {
    final entity = IncomeEntity(
      id: '3', description: 'C', amount: 3, 
      category: IncomeCategoryEnum.pix, dateTime: DateTime.now(), 
      createdAt: DateTime.now(),
    );

    test('salva como synced se remoto não falhou', () async {
      remote.shouldThrow = false;
      await repository.saveIncome(entity);

      final localList = await local.getIncomes();
      expect(localList.length, 1);
      expect(localList.first.hiveSyncStatus, SyncStatus.synced);
      expect(remote.serverStorage.length, 1);
    });

    test('salva como pending se tiver erro remoto', () async {
      remote.shouldThrow = true;
      await repository.saveIncome(entity);

      final localList = await local.getIncomes();
      expect(localList.length, 1);
      expect(localList.first.hiveSyncStatus, SyncStatus.pending);
      expect(remote.serverStorage.length, 0);
    });
  });

  group('IncomeRepositoryImpl - deleteIncome', () {
    test('exclui remotamente e localmente se tudo ok', () async {
      remote.shouldThrow = false;
      final model = IncomeModel.fromEntity(IncomeEntity(
        id: '1', description: 'desc', amount: 10, category: IncomeCategoryEnum.outros, 
        dateTime: DateTime.now(), createdAt: DateTime.now(),
      ));
      await local.saveIncome(model);
      remote.serverStorage.add(model);

      await repository.deleteIncome('1');
      expect((await local.getIncomes()).isEmpty, true);
      expect(remote.serverStorage.isEmpty, true);
    });
  });

  group('IncomeRepositoryImpl - syncPending', () {
    test('envia pendencias pro remote e atualiza as flags', () async {
      remote.shouldThrow = false;
      final model = IncomeModel(
        hiveId: 'pending-1',
        hiveDescription: 'D',
        hiveAmount: 4,
        hiveCategory: IncomeCategoryEnum.salario,
        hiveDateTime: DateTime.now(),
        hiveSyncStatus: SyncStatus.pending,
        hiveCreatedAt: DateTime.now(),
      );
      
      await local.saveIncome(model);

      await repository.syncPendingIncomes();

      final updatedLocal = (await local.getIncomes()).first;
      expect(updatedLocal.hiveSyncStatus, SyncStatus.synced);
      expect(remote.serverStorage.length, 1);
      expect(remote.serverStorage.first.hiveId, 'pending-1');
    });
  });
}
