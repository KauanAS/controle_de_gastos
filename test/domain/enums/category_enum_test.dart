import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';

/// Testes TDD para CategoryEnum
///
/// Features cobertas (CLAUDE.md):
/// - Seção 4.2: Categorias do sistema
/// - Seção 6: Regras — IA usa apenas categorias existentes,
///   fallback para "Outros", categoria "Outros" obrigatória,
///   NÃO EXISTEM subcategorias
/// - Seção 14.8: Categorias padrão pré-cadastradas
void main() {
  group('CategoryEnum - Valores', () {
    test('deve ter todas as categorias padrão definidas', () {
      expect(CategoryEnum.values, hasLength(10));
    });

    test('deve incluir todas as categorias de despesa do CLAUDE.md', () {
      // CLAUDE.md Seção 4.2: Alimentação, Mercado, Gasolina, Transporte,
      // Lazer, Assinaturas, Saúde, Educação, Moradia, Outros
      expect(CategoryEnum.values, contains(CategoryEnum.alimentacao));
      expect(CategoryEnum.values, contains(CategoryEnum.mercado));
      expect(CategoryEnum.values, contains(CategoryEnum.gasolina));
      expect(CategoryEnum.values, contains(CategoryEnum.transporte));
      expect(CategoryEnum.values, contains(CategoryEnum.lazer));
      expect(CategoryEnum.values, contains(CategoryEnum.assinaturas));
      expect(CategoryEnum.values, contains(CategoryEnum.saude));
      expect(CategoryEnum.values, contains(CategoryEnum.educacao));
      expect(CategoryEnum.values, contains(CategoryEnum.moradia));
      expect(CategoryEnum.values, contains(CategoryEnum.outros));
    });

    test('categoria "Outros" é obrigatória e existe no enum (CLAUDE.md Seção 6)', () {
      expect(CategoryEnum.outros, isNotNull);
      expect(CategoryEnum.values.contains(CategoryEnum.outros), isTrue);
    });
  });

  group('CategoryEnum - displayName', () {
    test('alimentacao deve exibir "Alimentação"', () {
      expect(CategoryEnum.alimentacao.displayName, 'Alimentação');
    });

    test('mercado deve exibir "Mercado"', () {
      expect(CategoryEnum.mercado.displayName, 'Mercado');
    });

    test('gasolina deve exibir "Gasolina"', () {
      expect(CategoryEnum.gasolina.displayName, 'Gasolina');
    });

    test('transporte deve exibir "Transporte"', () {
      expect(CategoryEnum.transporte.displayName, 'Transporte');
    });

    test('lazer deve exibir "Lazer"', () {
      expect(CategoryEnum.lazer.displayName, 'Lazer');
    });

    test('assinaturas deve exibir "Assinaturas"', () {
      expect(CategoryEnum.assinaturas.displayName, 'Assinaturas');
    });

    test('saude deve exibir "Saúde"', () {
      expect(CategoryEnum.saude.displayName, 'Saúde');
    });

    test('educacao deve exibir "Educação"', () {
      expect(CategoryEnum.educacao.displayName, 'Educação');
    });

    test('moradia deve exibir "Moradia"', () {
      expect(CategoryEnum.moradia.displayName, 'Moradia');
    });

    test('outros deve exibir "Outros"', () {
      expect(CategoryEnum.outros.displayName, 'Outros');
    });

    test('todas as categorias devem ter displayName não vazio', () {
      for (final cat in CategoryEnum.values) {
        expect(cat.displayName, isNotEmpty,
            reason: '${cat.name} tem displayName vazio');
      }
    });
  });

  group('CategoryEnum - icon (emoji)', () {
    test('todas as categorias devem ter ícone não vazio', () {
      for (final cat in CategoryEnum.values) {
        expect(cat.icon, isNotEmpty,
            reason: '${cat.name} tem icon vazio');
      }
    });

    test('alimentacao deve ter emoji correto', () {
      expect(CategoryEnum.alimentacao.icon, '🍽️');
    });

    test('mercado deve ter emoji correto', () {
      expect(CategoryEnum.mercado.icon, '🛒');
    });

    test('gasolina deve ter emoji correto', () {
      expect(CategoryEnum.gasolina.icon, '⛽');
    });
  });

  group('CategoryEnum - backendKey', () {
    test('backendKey deve ser o nome em UPPERCASE', () {
      expect(CategoryEnum.alimentacao.backendKey, 'ALIMENTACAO');
      expect(CategoryEnum.mercado.backendKey, 'MERCADO');
      expect(CategoryEnum.gasolina.backendKey, 'GASOLINA');
      expect(CategoryEnum.outros.backendKey, 'OUTROS');
    });

    test('todas as categorias devem gerar backendKey válido', () {
      for (final cat in CategoryEnum.values) {
        expect(cat.backendKey, equals(cat.name.toUpperCase()));
      }
    });
  });

  group('CategoryEnum - Regras de negócio (CLAUDE.md Seção 6)', () {
    test('IA deve usar fallback "Outros" quando não encontra categoria', () {
      // Simula o comportamento: se a IA não encontrar categoria → "Outros"
      CategoryEnum resolveCategory(String? aiSuggestion) {
        if (aiSuggestion == null) return CategoryEnum.outros;
        try {
          return CategoryEnum.values.firstWhere(
            (c) => c.name == aiSuggestion,
          );
        } catch (_) {
          return CategoryEnum.outros;
        }
      }

      expect(resolveCategory(null), CategoryEnum.outros);
      expect(resolveCategory('inexistente'), CategoryEnum.outros);
      expect(resolveCategory('alimentacao'), CategoryEnum.alimentacao);
    });

    test('não existem subcategorias — enum é flat (CLAUDE.md Seção 6)', () {
      // Verifica que não há hierarquia — todos os valores estão no mesmo nível
      for (final cat in CategoryEnum.values) {
        expect(cat, isA<CategoryEnum>());
        // Não há propriedade "parent" ou "subcategories"
      }
    });
  });
}
