import 'package:controle_de_gastos/domain/entities/expense_entity.dart';

/// Resultado do parser: pode ser sucesso (com entidade) ou falha (com mensagem).
sealed class ParseResult {
  const ParseResult();
}

class ParseSuccess extends ParseResult {
  final ExpenseEntity expense;
  const ParseSuccess(this.expense);
}

class ParseError extends ParseResult {
  final String message;
  const ParseError(this.message);
}

/// Contrato do serviço de interpretação de frases.
///
/// No MVP, a implementação usa regex + dicionários locais.
/// PONTO DE EXTENSÃO: substituir por OpenAI API, serviço NLP externo,
/// ou implementação híbrida (local + IA) sem alterar nada nas telas.
abstract class PhraseParserService {
  /// Interpreta uma frase em português e extrai os dados do gasto.
  Future<ParseResult> parse(String phrase);
}