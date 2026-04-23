import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/presentation/notifiers/income_notifier.dart';
import 'package:controle_de_gastos/presentation/providers/income_providers.dart';
import 'package:controle_de_gastos/domain/repositories/income_repository.dart';
import 'package:controle_de_gastos/domain/entities/income_entity.dart';
import 'package:controle_de_gastos/domain/enums/income_category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

class MockIncomeRepository implements IncomeRepository {
  List<IncomeEntity> mockStorage = [];

  @override
  Future<List<IncomeEntity>> getIncomes() async => mockStorage;

  @override
  Future<void> saveIncome(IncomeEntity income) async {
    mockStorage.add(income);
  }

  @override
  Future<void> deleteIncome(String id) async {
    mockStorage.removeWhere((x) => x.id == id);
  }

  @override
  Future<void> syncPendingIncomes() async {}
}

void main() {
  group('IncomeNotifier (Receitas)', () {
    late MockIncomeRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockIncomeRepository();
      container = ProviderContainer(
        overrides: [
          incomeRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('deve iniciar no estado de carregamento e depois emitir as receitas', () async {
      mockRepo.mockStorage = [
        IncomeEntity(id: '1', description: 'Salário', amount: 3000, category: IncomeCategoryEnum.salario, dateTime: DateTime.now(), createdAt: DateTime.now())
      ];

      final state = container.read(incomeNotifierProvider);
      expect(state.isLoading, true); // inicia carregando

      // Aguarda fetch inicial
      await Future.delayed(const Duration(milliseconds: 50));
      final nextState = container.read(incomeNotifierProvider);
      expect(nextState.isLoading, false);
      expect(nextState.incomes.length, 1);
    });

    test('criar renda altera a aba de status adequadamente', () async {
      final notifier = container.read(incomeNotifierProvider.notifier);
      
      final future = notifier.addIncome(
        description: 'Venda de bolo', 
        amount: 50, 
        category: IncomeCategoryEnum.vendas, 
        dateTime: DateTime.now(), 
        observation: 'Pix'
      );

      final stateMid = container.read(incomeNotifierProvider);
      expect(stateMid.status, IncomeStatus.saving);

      await future;

      final stateEnd = container.read(incomeNotifierProvider);
      expect(stateEnd.status, IncomeStatus.success);
      expect(mockRepo.mockStorage.length, 1);
      expect(mockRepo.mockStorage.first.description, 'Venda de bolo');
    });
  });
}
