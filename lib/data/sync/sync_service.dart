import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/repositories/expense_repository.dart';

/// Resultado de uma operação de sync.
class SyncOperationResult {
  final bool success;
  final String? errorMessage;

  const SyncOperationResult({required this.success, this.errorMessage});
}

/// Orquestra a sincronização de gastos com o backend.
///
/// No MVP: tenta enviar imediatamente após salvar localmente.
/// PONTO DE EXTENSÃO: adicionar fila com workmanager/background_fetch
/// para sync automático em background sem modificar o restante do app.
class SyncService {
  final ExpenseRepository _repository;

  SyncService(this._repository);

  /// Tenta sincronizar um único gasto com o backend.
  /// Atualiza o status local com o resultado.
  Future<SyncOperationResult> syncOne(ExpenseEntity expense) async {
    try {
      final result = await _repository.syncToRemote(expense);
      return SyncOperationResult(
        success: result.success,
        errorMessage: result.errorMessage,
      );
    } catch (e) {
      return SyncOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Tenta sincronizar todos os itens pendentes/com falha.
  /// Retorna quantos foram sincronizados com sucesso.
  Future<int> syncAllPending() async {
    final pending = await _repository.getPendingSync();
    int successCount = 0;

    for (final expense in pending) {
      final result = await syncOne(expense);
      if (result.success) successCount++;
    }

    return successCount;
  }
}