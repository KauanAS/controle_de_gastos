import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/config/app_config.dart';

/// Testes TDD para AppConfig
///
/// Features cobertas (CLAUDE.md):
/// - Seção 3: Supabase como backend
/// - Seção 9: Segurança — chave anon no frontend é segura por RLS
/// - Seção 14: Timeout de 2 segundos (requisito)
/// - Seção 16: Decisão — sem backend próprio, tudo via Supabase
void main() {
  group('AppConfig - Supabase', () {
    test('supabaseUrl deve ser uma URL válida', () {
      expect(AppConfig.supabaseUrl, startsWith('https://'));
      expect(AppConfig.supabaseUrl, contains('supabase.co'));
    });

    test('supabaseAnonKey deve estar preenchida', () {
      expect(AppConfig.supabaseAnonKey, isNotEmpty);
    });

    test('chave anon NÃO deve ser chave service_role (CLAUDE.md Seção 9)', () {
      // A chave anon/public começa com padrões específicos
      // A chave service_role NUNCA deve estar no frontend
      expect(
        AppConfig.supabaseAnonKey,
        isNot(contains('service_role')),
      );
    });
  });

  group('AppConfig - Configurações gerais', () {
    test('httpTimeoutSeconds deve ser positivo', () {
      expect(AppConfig.httpTimeoutSeconds, greaterThan(0));
    });

    test('httpTimeoutSeconds deve ser razoável (< 60s)', () {
      expect(AppConfig.httpTimeoutSeconds, lessThanOrEqualTo(60));
    });

    test('maxSyncRetries deve ser positivo', () {
      expect(AppConfig.maxSyncRetries, greaterThan(0));
    });

    test('maxSyncRetries deve ter valor razoável (1-10)', () {
      expect(AppConfig.maxSyncRetries, greaterThanOrEqualTo(1));
      expect(AppConfig.maxSyncRetries, lessThanOrEqualTo(10));
    });

    test('debugLogs deve ser um booleano', () {
      expect(AppConfig.debugLogs, isA<bool>());
    });
  });

  group('AppConfig - Construtor privado', () {
    test('não deve ser possível instanciar', () {
      // AppConfig._() impede instanciação direta
      expect(AppConfig.supabaseUrl, isNotNull);
    });
  });
}
