import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';

/// Testes TDD para PaymentMethod enum
///
/// Features cobertas (CLAUDE.md):
/// - Seção 4.3: Formas de pagamento
/// - Seção 5.5: Dashboard com gráfico por pagamento
/// - Seção 5.10: Cadastro manual com forma de pagamento
void main() {
  group('PaymentMethod - Valores', () {
    test('deve ter 6 formas de pagamento', () {
      expect(PaymentMethod.values, hasLength(6));
    });

    test('deve incluir todas as formas de pagamento', () {
      expect(PaymentMethod.values, contains(PaymentMethod.pix));
      expect(PaymentMethod.values, contains(PaymentMethod.dinheiro));
      expect(PaymentMethod.values, contains(PaymentMethod.debito));
      expect(PaymentMethod.values, contains(PaymentMethod.credito));
      expect(PaymentMethod.values, contains(PaymentMethod.boleto));
      expect(PaymentMethod.values, contains(PaymentMethod.outro));
    });

    test('deve ter fallback "outro" disponível', () {
      expect(PaymentMethod.outro, isNotNull);
    });
  });

  group('PaymentMethod - displayName', () {
    test('pix deve exibir "Pix"', () {
      expect(PaymentMethod.pix.displayName, 'Pix');
    });

    test('dinheiro deve exibir "Dinheiro"', () {
      expect(PaymentMethod.dinheiro.displayName, 'Dinheiro');
    });

    test('debito deve exibir "Débito"', () {
      expect(PaymentMethod.debito.displayName, 'Débito');
    });

    test('credito deve exibir "Crédito"', () {
      expect(PaymentMethod.credito.displayName, 'Crédito');
    });

    test('boleto deve exibir "Boleto"', () {
      expect(PaymentMethod.boleto.displayName, 'Boleto');
    });

    test('outro deve exibir "Outro"', () {
      expect(PaymentMethod.outro.displayName, 'Outro');
    });

    test('todas as formas de pagamento devem ter displayName', () {
      for (final pm in PaymentMethod.values) {
        expect(pm.displayName, isNotEmpty,
            reason: '${pm.name} tem displayName vazio');
      }
    });
  });

  group('PaymentMethod - icon (emoji)', () {
    test('todas devem ter ícone não vazio', () {
      for (final pm in PaymentMethod.values) {
        expect(pm.icon, isNotEmpty,
            reason: '${pm.name} tem icon vazio');
      }
    });

    test('pix deve ter emoji de raio', () {
      expect(PaymentMethod.pix.icon, '⚡');
    });

    test('dinheiro deve ter emoji de nota', () {
      expect(PaymentMethod.dinheiro.icon, '💵');
    });

    test('débito e crédito devem ter emoji de cartão', () {
      expect(PaymentMethod.debito.icon, '💳');
      expect(PaymentMethod.credito.icon, '💳');
    });
  });

  group('PaymentMethod - backendKey', () {
    test('backendKey deve ser o nome em UPPERCASE', () {
      expect(PaymentMethod.pix.backendKey, 'PIX');
      expect(PaymentMethod.dinheiro.backendKey, 'DINHEIRO');
      expect(PaymentMethod.debito.backendKey, 'DEBITO');
      expect(PaymentMethod.credito.backendKey, 'CREDITO');
      expect(PaymentMethod.boleto.backendKey, 'BOLETO');
      expect(PaymentMethod.outro.backendKey, 'OUTRO');
    });

    test('todas devem gerar backendKey válido', () {
      for (final pm in PaymentMethod.values) {
        expect(pm.backendKey, equals(pm.name.toUpperCase()));
      }
    });
  });
}
