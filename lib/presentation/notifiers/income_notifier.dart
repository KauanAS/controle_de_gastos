import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:controle_de_gastos/domain/entities/income_entity.dart';
import 'package:controle_de_gastos/domain/enums/income_category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/presentation/providers/income_providers.dart';

enum IncomeStatus { initial, loading, success, saving, error }

class IncomeState {
  final IncomeStatus status;
  final List<IncomeEntity> incomes;
  final String? errorMessage;
  final bool isLoading;

  const IncomeState({
    this.status = IncomeStatus.initial,
    this.incomes = const [],
    this.errorMessage,
    this.isLoading = false,
  });

  IncomeState copyWith({
    IncomeStatus? status,
    List<IncomeEntity>? incomes,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
  }) {
    return IncomeState(
      status: status ?? this.status,
      incomes: incomes ?? this.incomes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class IncomeNotifier extends StateNotifier<IncomeState> {
  final dynamic _repository;

  IncomeNotifier(this._repository) : super(const IncomeState(isLoading: true)) {
    if (_repository != null) {
      _loadIncomes();
    }
  }

  Future<void> _loadIncomes() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _repository.getIncomes();
      state = state.copyWith(
        isLoading: false,
        incomes: data,
        status: IncomeStatus.success,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: IncomeStatus.error,
        errorMessage: 'Erro ao carregar receitas: $e',
      );
    }
  }

  Future<void> addIncome({
    required String description,
    required double amount,
    required IncomeCategoryEnum category,
    required DateTime dateTime,
    String? observation,
  }) async {
    state = state.copyWith(status: IncomeStatus.saving, clearError: true);
    try {
      final income = IncomeEntity(
        id: const Uuid().v4(),
        description: description,
        amount: amount,
        category: category,
        dateTime: dateTime,
        observation: observation,
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(),
      );

      await _repository.saveIncome(income);
      await _loadIncomes(); // Recarrega para atualizar estado
    } catch (e) {
      state = state.copyWith(
        status: IncomeStatus.error,
        errorMessage: 'Erro ao salvar a receita: $e',
      );
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await _repository.deleteIncome(id);
      await _loadIncomes();
    } catch (e) {
      state = state.copyWith(
        status: IncomeStatus.error,
        errorMessage: 'Erro ao excluir: $e',
      );
    }
  }
}

final incomeNotifierProvider = StateNotifierProvider<IncomeNotifier, IncomeState>((ref) {
  final repo = ref.watch(incomeRepositoryProvider);
  return IncomeNotifier(repo);
});
