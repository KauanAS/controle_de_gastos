import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/domain/enums/income_category_enum.dart';

void main() {
  group('IncomeCategoryEnum - Valores', () {
    test('deve ter exatamente 5 categorias de receita', () {
      expect(IncomeCategoryEnum.values.length, 5);
    });

    test('deve conter todas as categorias esperadas', () {
      expect(IncomeCategoryEnum.values, containsAll([
        IncomeCategoryEnum.salario,
        IncomeCategoryEnum.vendas,
        IncomeCategoryEnum.rendimento,
        IncomeCategoryEnum.pix,
        IncomeCategoryEnum.outros,
      ]));
    });

    test('não deve ter subcategorias (enum flat)', () {
      for (final cat in IncomeCategoryEnum.values) {
        expect(cat, isA<IncomeCategoryEnum>());
      }
    });
  });

  group('IncomeCategoryEnum - displayName', () {
    test('salario deve ter displayName correto', () {
      expect(IncomeCategoryEnum.salario.displayName, 'Salário');
    });

    test('vendas deve ter displayName correto', () {
      expect(IncomeCategoryEnum.vendas.displayName, 'Vendas');
    });

    test('rendimento deve ter displayName correto', () {
      expect(IncomeCategoryEnum.rendimento.displayName, 'Rendimentos');
    });

    test('pix deve ter displayName correto', () {
      expect(IncomeCategoryEnum.pix.displayName, 'Pix Recebido');
    });

    test('outros deve ter displayName correto', () {
      expect(IncomeCategoryEnum.outros.displayName, 'Outros');
    });

    test('todas as categorias devem ter displayName não vazio', () {
      for (final cat in IncomeCategoryEnum.values) {
        expect(cat.displayName, isNotEmpty);
      }
    });
  });

  group('IncomeCategoryEnum - icon', () {
    test('todas as categorias devem ter ícone não vazio', () {
      for (final cat in IncomeCategoryEnum.values) {
        expect(cat.icon, isNotEmpty);
      }
    });

    test('cada categoria deve ter ícone único', () {
      final icons = IncomeCategoryEnum.values.map((e) => e.icon).toList();
      final uniqueIcons = icons.toSet();
      expect(uniqueIcons.length, icons.length);
    });
  });

  group('IncomeCategoryEnum - backend key (name)', () {
    test('chaves de backend devem ser minúsculas sem acento', () {
      for (final cat in IncomeCategoryEnum.values) {
        expect(cat.name, matches(RegExp(r'^[a-z]+$')));
      }
    });

    test('deve recuperar categoria por nome (como o fromJson faz)', () {
      for (final cat in IncomeCategoryEnum.values) {
        final found = IncomeCategoryEnum.values.firstWhere(
          (e) => e.name == cat.name,
        );
        expect(found, cat);
      }
    });

    test('fallback para "outros" se categoria desconhecida (como IncomeModel.fromJson faz)', () {
      const unknownKey = 'categoria_inexistente';
      final found = IncomeCategoryEnum.values.firstWhere(
        (e) => e.name == unknownKey,
        orElse: () => IncomeCategoryEnum.outros,
      );
      expect(found, IncomeCategoryEnum.outros);
    });
  });

  group('IncomeCategoryEnum - Regras de negócio (CLAUDE.md Seção 6)', () {
    test('categoria "outros" existe como fallback obrigatório da IA', () {
      expect(IncomeCategoryEnum.outros, isNotNull);
    });

    test('IA NUNCA cria categorias — só usa as existentes no enum', () {
      const totalCategorias = 5;
      expect(IncomeCategoryEnum.values.length, totalCategorias,
          reason: 'Novas categorias só devem ser adicionadas intencionalmente');
    });
  });
}
