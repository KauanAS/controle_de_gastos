import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/domain/services/phrase_parser_service.dart';
import 'package:controle_de_gastos/presentation/providers/expense_providers.dart';
import 'package:controle_de_gastos/data/sync/sync_service.dart';

// ─── Estado ────────────────────────────────────────────────────────────────

enum NewEntryStatus { idle, parsing, parsed, saving, success, error }

class NewEntryState {
  final NewEntryStatus status;
  final ExpenseEntity? parsedExpense;
  final String? errorMessage;
  final bool syncSuccess;

  const NewEntryState({
    this.status = NewEntryStatus.idle,
    this.parsedExpense,
    this.errorMessage,
    this.syncSuccess = false,
  });

  NewEntryState copyWith({
    NewEntryStatus? status,
    ExpenseEntity? parsedExpense,
    String? errorMessage,
    bool? syncSuccess,
  }) {
    return NewEntryState(
      status: status ?? this.status,
      parsedExpense: parsedExpense ?? this.parsedExpense,
      errorMessage: errorMessage ?? this.errorMessage,
      syncSuccess: syncSuccess ?? this.syncSuccess,
    );
  }
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class NewEntryNotifier extends StateNotifier<NewEntryState> {
  final PhraseParserService _parser;
  final SyncService _sync;
  final Ref _ref;

  NewEntryNotifier(this._parser, this._sync, this._ref)
      : super(const NewEntryState());

  /// Interpreta a frase e atualiza o estado com o resultado.
  Future<void> parsePhrase(String phrase) async {
    if (phrase.trim().isEmpty) {
      state = state.copyWith(
        status: NewEntryStatus.error,
        errorMessage: 'Digite uma frase para continuar.',
      );
      return;
    }

    state = state.copyWith(status: NewEntryStatus.parsing);

    final result = await _parser.parse(phrase);

    switch (result) {
      case ParseSuccess(:final expense):
        state = state.copyWith(
          status: NewEntryStatus.parsed,
          parsedExpense: expense,
          errorMessage: null,
        );
      case ParseError(:final message):
        state = state.copyWith(
          status: NewEntryStatus.error,
          errorMessage: message,
        );
    }
  }

  /// Confirma o lançamento: salva localmente e tenta sincronizar.
  Future<void> confirmExpense(ExpenseEntity expense) async {
    state = state.copyWith(status: NewEntryStatus.saving);

    final repo = _ref.read(expenseRepositoryProvider);

    // 1. Salva localmente primeiro (offline first)
    await repo.saveLocal(expense);

    // 2. Invalida os providers de dados para forçar re-leitura
    _ref.invalidate(allExpensesProvider);
    _ref.invalidate(currentMonthExpensesProvider);
    _ref.invalidate(monthlySummaryProvider);

    // 3. Tenta sincronizar com o backend (não bloqueia se falhar)
    final syncResult = await _sync.syncOne(expense);

    // 4. Invalida novamente para refletir status de sync atualizado
    _ref.invalidate(allExpensesProvider);
    _ref.invalidate(currentMonthExpensesProvider);
    _ref.invalidate(monthlySummaryProvider);

    state = NewEntryState(
      status: NewEntryStatus.success,
      parsedExpense: state.parsedExpense,
      syncSuccess: syncResult.success,
      errorMessage: syncResult.success ? null : syncResult.errorMessage,
    );
  }

  /// Atualiza a entidade parseada (quando usuário edita na tela de confirmação).
  void updateParsedExpense(ExpenseEntity expense) {
    state = state.copyWith(parsedExpense: expense);
  }

  /// Reseta o estado para novo lançamento.
  void reset() {
    state = const NewEntryState();
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────

// CORREÇÃO: removido .autoDispose — o estado precisa sobreviver à navegação
// NewEntry → Confirmation → pop → NewEntry, senão o parse é perdido.
final newEntryProvider =
    StateNotifierProvider<NewEntryNotifier, NewEntryState>((ref) {
  return NewEntryNotifier(
    ref.watch(phraseParserProvider),
    ref.watch(syncServiceProvider),
    ref,
  );
});