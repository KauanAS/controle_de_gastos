import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:controle_de_gastos/domain/models/expense_model.dart';

class RemoteSyncResult {
  final bool success;
  final String? remoteId;
  final String? errorMessage;

  const RemoteSyncResult({
    required this.success,
    this.remoteId,
    this.errorMessage,
  });
}

/// Gerencia comunicação com o Supabase (tabela: gastos).
class ExpenseRemoteDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  /// Insere um gasto na tabela 'gastos' do Supabase.
  Future<RemoteSyncResult> sendExpense(ExpenseModel model) async {
    try {
      final data = {
        'id_local':       model.id,
        'data_hora':      model.dateTime.toIso8601String(),
        'categoria':      model.category.name,
        'valor':          model.amount,
        'pagamento':      model.paymentMethod.name,
        'texto_original': model.originalText,
        'criado_em':      model.createdAt.toIso8601String(),
      };

      final response = await _client
          .from('gastos')
          .insert(data)
          .select('id')
          .single()
          .timeout(const Duration(seconds: 15));

      return RemoteSyncResult(
        success: true,
        remoteId: response['id']?.toString(),
      );
    } on PostgrestException catch (e) {
      return RemoteSyncResult(
        success: false,
        errorMessage: 'Erro no banco: ${e.message}',
      );
    } catch (e) {
      return RemoteSyncResult(
        success: false,
        errorMessage: 'Erro ao conectar: $e',
      );
    }
  }

  /// Apaga um gasto do Supabase pelo id_local (UUID gerado no app).
  /// Retorna true se apagou com sucesso ou se o registro não existia.
  Future<bool> deleteExpense(String localId) async {
    try {
      await _client
          .from('gastos')
          .delete()
          .eq('id_local', localId)
          .timeout(const Duration(seconds: 15));

      // O Supabase não lança erro se a linha não existir — apenas deleta 0 linhas.
      // Consideramos sucesso em ambos os casos.
      return true;
    } on PostgrestException catch (e) {
      // Loga mas não trava o app — o item local já será removido de qualquer forma
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        // ignore: avoid_print
        print('[Supabase] Erro ao deletar id_local=$localId: ${e.message}');
      }
      return false;
    } catch (e) {
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        // ignore: avoid_print
        print('[Supabase] Erro inesperado ao deletar: $e');
      }
      return false;
    }
  }
}
