import 'package:uuid/uuid.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/domain/services/phrase_parser_service.dart';

class PhraseParserImpl implements PhraseParserService {
  final _uuid = const Uuid();

  static final _amountRegex = RegExp(
    r'R?\$?\s*(\d{1,6}(?:[.,]\d{1,2})?)',
    caseSensitive: false,
  );

  static const Map<CategoryEnum, List<String>> _categoryKeywords = {
    CategoryEnum.alimentacao: [
      'café', 'cafe', 'lanche', 'restaurante', 'comida', 'almoço', 'almoco',
      'jantar', 'pizza', 'hamburguer', 'hambúrguer', 'salgado', 'padaria',
      'ifood', 'rappi', 'delivery', 'refeição', 'refeicao', 'fast food',
    ],
    CategoryEnum.mercado: [
      'mercado', 'supermercado', 'feira', 'hortifruti', 'açougue', 'acougue',
      'padaria', 'atacado', 'atacadão', 'atacadao', 'compras',
    ],
    CategoryEnum.gasolina: [
      'gasolina', 'combustível', 'combustivel', 'etanol', 'diesel',
      'posto', 'abasteci', 'abastecimento',
    ],
    CategoryEnum.transporte: [
      'uber', '99', 'taxi', 'táxi', 'ônibus', 'onibus', 'metrô', 'metro',
      'passagem', 'transporte', 'mototaxi', 'bicicleta', 'bike', 'trem',
    ],
    CategoryEnum.lazer: [
      'cinema', 'teatro', 'show', 'ingresso', 'festa', 'balada', 'bar',
      'lazer', 'diversão', 'diversao', 'jogo', 'parque',
    ],
    CategoryEnum.assinaturas: [
      'netflix', 'spotify', 'amazon', 'prime', 'disney', 'hbo', 'apple',
      'youtube', 'assinatura', 'mensalidade', 'plano', 'subscription',
    ],
    CategoryEnum.saude: [
      'farmácia', 'farmacia', 'remédio', 'remedio', 'médico', 'medico',
      'consulta', 'exame', 'hospital', 'clínica', 'clinica', 'dentista',
      'plano de saúde', 'saúde', 'saude',
    ],
    CategoryEnum.educacao: [
      'curso', 'faculdade', 'escola', 'mensalidade', 'livro', 'educação',
      'educacao', 'aula', 'treinamento', 'apostila', 'udemy', 'alura',
    ],
    CategoryEnum.moradia: [
      'aluguel', 'condomínio', 'condominio', 'água', 'agua', 'luz',
      'energia', 'internet', 'telefone', 'gás', 'gas', 'iptu', 'moradia',
    ],
  };

  static const Map<PaymentMethod, List<String>> _paymentKeywords = {
    PaymentMethod.pix: ['pix'],
    PaymentMethod.dinheiro: ['dinheiro', 'espécie', 'especie', 'cash'],
    PaymentMethod.debito: ['débito', 'debito', 'debit'],
    PaymentMethod.credito: [
      'crédito', 'credito', 'cartão', 'cartao', 'credit', 'visa', 'master',
      'mastercard', 'elo',
    ],
    PaymentMethod.boleto: ['boleto', 'billet'],
  };

  @override
  Future<ParseResult> parse(String phrase) async {
    final normalized = _normalize(phrase);
    final amount = _extractAmount(normalized);

    if (amount == null || amount <= 0) {
      return const ParseError(
        'Não encontrei um valor válido na frase. Tente incluir o valor, ex: "45 reais de gasolina no pix".',
      );
    }

    final payment = _extractPayment(normalized);
    final category = _extractCategory(normalized);
    final now = DateTime.now();

    final entity = ExpenseEntity(
      id: _uuid.v4(),
      amount: amount,
      category: category,
      paymentMethod: payment,
      dateTime: now,
      originalText: phrase.trim(),
      syncStatus: SyncStatus.pending,
      createdAt: now,
    );

    return ParseSuccess(entity);
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãä]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n');
  }

  double? _extractAmount(String text) {
    final match = _amountRegex.firstMatch(text);
    if (match == null) return null;
    final raw = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(raw);
  }

  PaymentMethod _extractPayment(String text) {
    for (final entry in _paymentKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(_normalize(keyword))) {
          return entry.key;
        }
      }
    }
    return PaymentMethod.outro;
  }

  CategoryEnum _extractCategory(String text) {
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(_normalize(keyword))) {
          return entry.key;
        }
      }
    }
    return CategoryEnum.outros;
  }
}
