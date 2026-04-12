import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/core/errors/failures.dart';

/// Testes TDD para Failures (classes de erro)
///
/// Features cobertas (CLAUDE.md):
/// - Seção 6: Tratamento de erros e campos nulos
/// - Seção 7: Todos as telas implementam estado de Erro
/// - Seção 8: Fluxo com falhas (sync, parse, rede)
/// - Seção 14: Requisitos não funcionais — resiliência
void main() {
  group('Failure - Classe base', () {
    test('deve ser Equatable e conter mensagem', () {
      const failure = LocalFailure('erro teste');
      expect(failure.message, 'erro teste');
    });

    test('duas failures com mesma mensagem devem ser iguais', () {
      const a = LocalFailure('erro');
      const b = LocalFailure('erro');
      expect(a, equals(b));
    });

    test('duas failures com mensagens diferentes devem ser diferentes', () {
      const a = LocalFailure('erro 1');
      const b = LocalFailure('erro 2');
      expect(a, isNot(equals(b)));
    });
  });

  group('LocalFailure', () {
    test('deve estender Failure', () {
      const failure = LocalFailure('erro local');
      expect(failure, isA<Failure>());
    });

    test('deve conter mensagem descritiva', () {
      const failure = LocalFailure('Falha ao salvar no Hive');
      expect(failure.message, 'Falha ao salvar no Hive');
    });

    test('props deve incluir mensagem', () {
      const failure = LocalFailure('teste');
      expect(failure.props, contains('teste'));
    });
  });

  group('RemoteFailure', () {
    test('deve estender Failure', () {
      const failure = RemoteFailure('erro remoto');
      expect(failure, isA<Failure>());
    });

    test('deve conter mensagem e statusCode', () {
      const failure = RemoteFailure('Erro 500', statusCode: 500);
      expect(failure.message, 'Erro 500');
      expect(failure.statusCode, 500);
    });

    test('statusCode deve ser nullable', () {
      const failure = RemoteFailure('Erro de rede');
      expect(failure.statusCode, isNull);
    });

    test('duas RemoteFailures com statusCode diferente devem ser diferentes', () {
      const a = RemoteFailure('erro', statusCode: 400);
      const b = RemoteFailure('erro', statusCode: 500);
      expect(a, isNot(equals(b)));
    });
  });

  group('ParseFailure', () {
    test('deve estender Failure', () {
      const failure = ParseFailure('falha no parser');
      expect(failure, isA<Failure>());
    });

    test('deve conter mensagem', () {
      const failure = ParseFailure('Não encontrei valor na frase');
      expect(failure.message, 'Não encontrei valor na frase');
    });
  });

  group('ValidationFailure', () {
    test('deve estender Failure', () {
      const failure = ValidationFailure('campo obrigatório');
      expect(failure, isA<Failure>());
    });

    test('deve conter mensagem de validação', () {
      const failure = ValidationFailure('Descrição é obrigatória');
      expect(failure.message, 'Descrição é obrigatória');
    });
  });

  group('NetworkFailure', () {
    test('deve estender Failure', () {
      const failure = NetworkFailure();
      expect(failure, isA<Failure>());
    });

    test('deve ter mensagem padrão sobre conexão', () {
      const failure = NetworkFailure();
      expect(failure.message, 'Sem conexão com a internet.');
    });

    test('duas NetworkFailures devem ser iguais', () {
      const a = NetworkFailure();
      const b = NetworkFailure();
      expect(a, equals(b));
    });
  });

  group('Failures - Cenários de uso real (CLAUDE.md)', () {
    test('erro ao salvar localmente no Hive', () {
      const failure = LocalFailure('Box não inicializado');
      expect(failure.message, contains('Box'));
    });

    test('erro de sincronização com Supabase', () {
      const failure = RemoteFailure(
        'Erro no banco: violação de chave única',
        statusCode: 409,
      );
      expect(failure.message, contains('chave única'));
      expect(failure.statusCode, 409);
    });

    test('erro de parse de frase sem valor', () {
      const failure = ParseFailure(
        'Não encontrei um valor válido na frase.',
      );
      expect(failure.message, contains('valor válido'));
    });

    test('erro de validação — campo obrigatório', () {
      const failure = ValidationFailure(
        'Campo descrição é obrigatório',
      );
      expect(failure.message, contains('obrigatório'));
    });

    test('erro de rede — sem internet', () {
      const failure = NetworkFailure();
      expect(failure.message, contains('conexão'));
    });
  });
}
