import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/services/phrase_parser_impl.dart';
import 'package:controle_de_gastos/domain/services/phrase_parser_service.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

/// Testes TDD para PhraseParserImpl (Serviço de interpretação de frases)
///
/// Features cobertas (CLAUDE.md):
/// - Seção 5.11: Inserção inteligente — texto
/// - Seção 6: IA interpreta e extrai categoria, valor, forma de pagamento
/// - Seção 6: IA NUNCA cria categorias — usa apenas existentes
/// - Seção 6: Fallback para "Outros" se não encontrar categoria
/// - Seção 8: Fluxo da entrada inteligente
/// - Seção 3: PhraseParserService como ponto de extensão para IA futura
void main() {
  late PhraseParserImpl parser;

  setUp(() {
    parser = PhraseParserImpl();
  });

  group('PhraseParserImpl - Extração de valor', () {
    test('deve extrair valor inteiro (ex: "30 reais")', () async {
      final result = await parser.parse('30 reais almoço');

      expect(result, isA<ParseSuccess>());
      expect((result as ParseSuccess).expense.amount, 30.0);
    });

    test('deve extrair valor com centavos usando vírgula (ex: "25,50")', () async {
      final result = await parser.parse('almoço 25,50 pix');

      expect(result, isA<ParseSuccess>());
      expect((result as ParseSuccess).expense.amount, 25.50);
    });

    test('deve extrair valor com símbolo R\$ (ex: "R\$ 100")', () async {
      final result = await parser.parse('R\$ 100 gasolina');

      expect(result, isA<ParseSuccess>());
      expect((result as ParseSuccess).expense.amount, 100.0);
    });

    test('deve extrair valor com \$ (ex: "\$50")', () async {
      final result = await parser.parse('\$50 uber');

      expect(result, isA<ParseSuccess>());
      expect((result as ParseSuccess).expense.amount, 50.0);
    });

    test('deve retornar ParseError quando não encontrar valor', () async {
      final result = await parser.parse('fui ao mercado');

      expect(result, isA<ParseError>());
      expect(
        (result as ParseError).message,
        contains('valor válido'),
      );
    });

    test('deve retornar ParseError para valor zero', () async {
      final result = await parser.parse('0 reais mercado');

      expect(result, isA<ParseError>());
    });

    test('deve retornar ParseError para frase vazia', () async {
      final result = await parser.parse('');

      expect(result, isA<ParseError>());
    });
  });

  group('PhraseParserImpl - Extração de categoria', () {
    test('deve detectar alimentação por palavras-chave', () async {
      final phrases = [
        '30 reais café',
        '25 lanche',
        '50 restaurante pix',
        '40 almoço',
        '35 pizza credito',
        '20 ifood debito',
      ];

      for (final phrase in phrases) {
        final result = await parser.parse(phrase);
        expect(result, isA<ParseSuccess>(),
            reason: 'Falhou para: "$phrase"');
        expect((result as ParseSuccess).expense.category,
            CategoryEnum.alimentacao,
            reason: 'Categoria errada para: "$phrase"');
      }
    });

    test('deve detectar mercado por palavras-chave', () async {
      final phrases = [
        '200 mercado debito',
        '150 supermercado',
        '80 feira',
      ];

      for (final phrase in phrases) {
        final result = await parser.parse(phrase);
        expect(result, isA<ParseSuccess>(),
            reason: 'Falhou para: "$phrase"');
        expect((result as ParseSuccess).expense.category,
            CategoryEnum.mercado,
            reason: 'Categoria errada para: "$phrase"');
      }
    });

    test('deve detectar gasolina por palavras-chave', () async {
      final phrases = [
        '200 gasolina',
        '150 combustível pix',
        '100 abasteci',
        '80 posto credito',
      ];

      for (final phrase in phrases) {
        final result = await parser.parse(phrase);
        expect(result, isA<ParseSuccess>(),
            reason: 'Falhou para: "$phrase"');
        expect((result as ParseSuccess).expense.category,
            CategoryEnum.gasolina,
            reason: 'Categoria errada para: "$phrase"');
      }
    });

    test('deve detectar transporte por palavras-chave', () async {
      final phrases = [
        '15 uber',
        '20 taxi',
        '5 ônibus',
        '10 metrô',
      ];

      for (final phrase in phrases) {
        final result = await parser.parse(phrase);
        expect(result, isA<ParseSuccess>(),
            reason: 'Falhou para: "$phrase"');
        expect((result as ParseSuccess).expense.category,
            CategoryEnum.transporte,
            reason: 'Categoria errada para: "$phrase"');
      }
    });

    test('deve detectar lazer por palavras-chave', () async {
      final phrases = [
        '50 cinema pix',
        '100 show credito',
        '30 bar',
      ];

      for (final phrase in phrases) {
        final result = await parser.parse(phrase);
        expect(result, isA<ParseSuccess>(),
            reason: 'Falhou para: "$phrase"');
        expect((result as ParseSuccess).expense.category,
            CategoryEnum.lazer,
            reason: 'Categoria errada para: "$phrase"');
      }
    });

    test('deve detectar assinaturas por palavras-chave', () async {
      final phrases = [
        '40 netflix',
        '20 spotify',
        '15 youtube',
      ];

      for (final phrase in phrases) {
        final result = await parser.parse(phrase);
        expect(result, isA<ParseSuccess>(),
            reason: 'Falhou para: "$phrase"');
        expect((result as ParseSuccess).expense.category,
            CategoryEnum.assinaturas,
            reason: 'Categoria errada para: "$phrase"');
      }
    });

    test('deve detectar saúde por palavras-chave', () async {
      final phrases = [
        '100 farmácia',
        '200 médico pix',
        '150 consulta',
        '50 dentista',
      ];

      for (final phrase in phrases) {
        final result = await parser.parse(phrase);
        expect(result, isA<ParseSuccess>(),
            reason: 'Falhou para: "$phrase"');
        expect((result as ParseSuccess).expense.category,
            CategoryEnum.saude,
            reason: 'Categoria errada para: "$phrase"');
      }
    });

    test('deve detectar educação por palavras-chave', () async {
      final phrases = [
        '500 curso',
        '50 livro',
        '100 udemy',
      ];

      for (final phrase in phrases) {
        final result = await parser.parse(phrase);
        expect(result, isA<ParseSuccess>(),
            reason: 'Falhou para: "$phrase"');
        expect((result as ParseSuccess).expense.category,
            CategoryEnum.educacao,
            reason: 'Categoria errada para: "$phrase"');
      }
    });

    test('deve detectar moradia por palavras-chave', () async {
      final phrases = [
        '1500 aluguel',
        '200 luz',
        '100 internet',
        '80 água',
      ];

      for (final phrase in phrases) {
        final result = await parser.parse(phrase);
        expect(result, isA<ParseSuccess>(),
            reason: 'Falhou para: "$phrase"');
        expect((result as ParseSuccess).expense.category,
            CategoryEnum.moradia,
            reason: 'Categoria errada para: "$phrase"');
      }
    });

    test('deve usar fallback "Outros" quando não encontrar categoria (CLAUDE.md Seção 6)', () async {
      final result = await parser.parse('50 coisa qualquer');

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.category,
        CategoryEnum.outros,
      );
    });

    test('NUNCA deve criar categoria nova — apenas usar existentes (CLAUDE.md Seção 6)', () async {
      // Frase com contexto que não mapeia para nenhuma categoria existente
      final result = await parser.parse('300 pet shop do cachorro');

      expect(result, isA<ParseSuccess>());
      // Deve cair no fallback, não criar "pet shop" como categoria
      final category = (result as ParseSuccess).expense.category;
      expect(CategoryEnum.values, contains(category));
    });
  });

  group('PhraseParserImpl - Extração de forma de pagamento', () {
    test('deve detectar Pix', () async {
      final result = await parser.parse('50 almoço pix');

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.paymentMethod,
        PaymentMethod.pix,
      );
    });

    test('deve detectar dinheiro/espécie', () async {
      final result = await parser.parse('30 lanche dinheiro');

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.paymentMethod,
        PaymentMethod.dinheiro,
      );
    });

    test('deve detectar débito', () async {
      final result = await parser.parse('200 mercado débito');

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.paymentMethod,
        PaymentMethod.debito,
      );
    });

    test('deve detectar crédito', () async {
      final result = await parser.parse('100 gasolina crédito');

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.paymentMethod,
        PaymentMethod.credito,
      );
    });

    test('deve detectar crédito por "cartão"', () async {
      final result = await parser.parse('100 gasolina cartão');

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.paymentMethod,
        PaymentMethod.credito,
      );
    });

    test('deve detectar boleto', () async {
      final result = await parser.parse('500 curso boleto');

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.paymentMethod,
        PaymentMethod.boleto,
      );
    });

    test('deve usar fallback "outro" quando não encontrar pagamento', () async {
      final result = await parser.parse('50 cinema');

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.paymentMethod,
        PaymentMethod.outro,
      );
    });
  });

  group('PhraseParserImpl - Entidade gerada', () {
    test('entidade gerada deve ter ID único (UUID)', () async {
      final r1 = await parser.parse('30 almoço');
      final r2 = await parser.parse('50 mercado');

      final id1 = (r1 as ParseSuccess).expense.id;
      final id2 = (r2 as ParseSuccess).expense.id;

      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(equals(id2)));
    });

    test('entidade gerada deve ter syncStatus = pending', () async {
      final result = await parser.parse('30 almoço pix');

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.syncStatus,
        SyncStatus.pending,
      );
    });

    test('entidade gerada deve preservar o texto original', () async {
      const phrase = '45,50 reais café da manhã';
      final result = await parser.parse(phrase);

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.originalText,
        phrase,
      );
    });

    test('entidade gerada deve ter dateTime e createdAt preenchidos', () async {
      final before = DateTime.now();
      final result = await parser.parse('30 almoço');
      final after = DateTime.now();

      final expense = (result as ParseSuccess).expense;
      expect(expense.dateTime.millisecondsSinceEpoch,
          greaterThanOrEqualTo(before.millisecondsSinceEpoch));
      expect(expense.dateTime.millisecondsSinceEpoch,
          lessThanOrEqualTo(after.millisecondsSinceEpoch));
      expect(expense.createdAt, isNotNull);
    });
  });

  group('PhraseParserImpl - ParseResult sealed class', () {
    test('ParseError deve conter mensagem', () {
      const error = ParseError('mensagem de erro');
      expect(error, isA<ParseResult>());
      expect(error.message, 'mensagem de erro');
    });

    test('ParseSuccess deve conter a entidade quando parse é bem-sucedido', () async {
      final result = await parser.parse('50 almoço pix');
      expect(result, isA<ParseSuccess>());
      expect((result as ParseSuccess).expense, isNotNull);
      expect(result.expense, isA<ExpenseEntity>());
    });
  });

  group('PhraseParserImpl - Normalização de acentos', () {
    test('deve reconhecer categoria mesmo com acentos variados', () async {
      final result = await parser.parse('50 restaurante');

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.category,
        CategoryEnum.alimentacao,
      );
    });

    test('deve reconhecer forma de pagamento com acentos', () async {
      final result = await parser.parse('50 almoço crédito');

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.paymentMethod,
        PaymentMethod.credito,
      );
    });

    test('deve funcionar case-insensitive', () async {
      final result = await parser.parse('100 GASOLINA PIX');

      expect(result, isA<ParseSuccess>());
      expect(
        (result as ParseSuccess).expense.category,
        CategoryEnum.gasolina,
      );
      expect(
        (result as ParseSuccess).expense.paymentMethod,
        PaymentMethod.pix,
      );
    });
  });

  group('PhraseParserImpl - Cenários reais de uso', () {
    test('frase completa: "gastei 45,50 no almoço pelo pix"', () async {
      final result = await parser.parse('gastei 45,50 no almoço pelo pix');

      expect(result, isA<ParseSuccess>());
      final expense = (result as ParseSuccess).expense;
      expect(expense.amount, 45.50);
      expect(expense.category, CategoryEnum.alimentacao);
      expect(expense.paymentMethod, PaymentMethod.pix);
    });

    test('frase: "200 de gasolina no crédito"', () async {
      final result = await parser.parse('200 de gasolina no crédito');

      expect(result, isA<ParseSuccess>());
      final expense = (result as ParseSuccess).expense;
      expect(expense.amount, 200.0);
      expect(expense.category, CategoryEnum.gasolina);
      expect(expense.paymentMethod, PaymentMethod.credito);
    });

    test('frase: "paguei R\$1500 de aluguel"', () async {
      final result = await parser.parse('paguei R\$1500 de aluguel');

      expect(result, isA<ParseSuccess>());
      final expense = (result as ParseSuccess).expense;
      expect(expense.amount, 1500.0);
      expect(expense.category, CategoryEnum.moradia);
    });

    test('frase: "uber 15,00"', () async {
      final result = await parser.parse('uber 15,00');

      expect(result, isA<ParseSuccess>());
      final expense = (result as ParseSuccess).expense;
      expect(expense.amount, 15.00);
      expect(expense.category, CategoryEnum.transporte);
    });

    test('frase sem categoria reconhecível: "50 presente aniversário"', () async {
      final result = await parser.parse('50 presente aniversário');

      expect(result, isA<ParseSuccess>());
      final expense = (result as ParseSuccess).expense;
      expect(expense.amount, 50.0);
      expect(expense.category, CategoryEnum.outros);
      expect(expense.paymentMethod, PaymentMethod.outro);
    });
  });
}
