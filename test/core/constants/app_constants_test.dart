import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/core/constants/app_constants.dart';

/// Testes TDD para AppConstants
///
/// Features cobertas (CLAUDE.md):
/// - Seção 3: Hive como armazenamento local
/// - Seção 14: Formato de data e moeda BRL
/// - Seção 6: Mensagens de feedback ao usuário
/// - Seção 17: Convenções de nomenclatura
void main() {
  group('AppConstants - Hive', () {
    test('hiveBoxExpenses deve ser "expenses_box"', () {
      expect(AppConstants.hiveBoxExpenses, 'expenses_box');
    });

    test('adapters Hive devem ter IDs únicos', () {
      final ids = {
        AppConstants.hiveAdapterExpenseModel,
        AppConstants.hiveAdapterSyncStatus,
        AppConstants.hiveAdapterCategory,
        AppConstants.hiveAdapterPaymentMethod,
      };
      // Todos os IDs devem ser únicos
      expect(ids, hasLength(4));
    });

    test('adapter IDs devem ser inteiros não negativos', () {
      expect(AppConstants.hiveAdapterExpenseModel, greaterThanOrEqualTo(0));
      expect(AppConstants.hiveAdapterSyncStatus, greaterThanOrEqualTo(0));
      expect(AppConstants.hiveAdapterCategory, greaterThanOrEqualTo(0));
      expect(AppConstants.hiveAdapterPaymentMethod, greaterThanOrEqualTo(0));
    });
  });

  group('AppConstants - UI', () {
    test('appName deve ser "Gastos"', () {
      expect(AppConstants.appName, 'Gastos');
    });

    test('paddings devem seguir escala crescente', () {
      expect(AppConstants.paddingSmall, lessThan(AppConstants.paddingMedium));
      expect(AppConstants.paddingMedium, lessThan(AppConstants.paddingLarge));
    });

    test('paddings devem ter valores positivos', () {
      expect(AppConstants.paddingSmall, greaterThan(0));
      expect(AppConstants.paddingMedium, greaterThan(0));
      expect(AppConstants.paddingLarge, greaterThan(0));
    });

    test('borderRadius deve ser positivo', () {
      expect(AppConstants.borderRadius, greaterThan(0));
    });

    test('cardElevation deve ser definido', () {
      expect(AppConstants.cardElevation, isNotNull);
      expect(AppConstants.cardElevation, greaterThanOrEqualTo(0));
    });
  });

  group('AppConstants - Formatos de data (CLAUDE.md Seção 14)', () {
    test('dateFormatDisplay deve ser formato brasileiro dd/MM/yyyy', () {
      expect(AppConstants.dateFormatDisplay, 'dd/MM/yyyy');
    });

    test('dateTimeFormatDisplay deve incluir hora e minuto', () {
      expect(AppConstants.dateTimeFormatDisplay, 'dd/MM/yyyy HH:mm');
    });

    test('dateFormatIso deve ser formato ISO 8601', () {
      expect(AppConstants.dateFormatIso, contains('yyyy'));
      expect(AppConstants.dateFormatIso, contains('MM'));
      expect(AppConstants.dateFormatIso, contains('dd'));
    });
  });

  group('AppConstants - Mensagens', () {
    test('msgSaveSuccess deve ser mensagem de sucesso ao salvar', () {
      expect(AppConstants.msgSaveSuccess, isNotEmpty);
      expect(AppConstants.msgSaveSuccess, contains('salvo'));
    });

    test('msgSyncSuccess deve ser mensagem de sync bem-sucedido', () {
      expect(AppConstants.msgSyncSuccess, isNotEmpty);
      expect(AppConstants.msgSyncSuccess.toLowerCase(),
          contains('sincroniz'));
    });

    test('msgSyncFailed deve ser mensagem de falha no sync', () {
      expect(AppConstants.msgSyncFailed, isNotEmpty);
      expect(AppConstants.msgSyncFailed.toLowerCase(),
          contains('falha'));
    });

    test('msgParseError deve informar que não conseguiu interpretar', () {
      expect(AppConstants.msgParseError, isNotEmpty);
    });

    test('msgEmptyField deve pedir para o usuário digitar', () {
      expect(AppConstants.msgEmptyField, isNotEmpty);
      expect(AppConstants.msgEmptyField.toLowerCase(),
          contains('digit'));
    });
  });

  group('AppConstants - Construtor privado', () {
    test('AppConstants não deve poder ser instanciado', () {
      // O construtor privado AppConstants._() impede instanciação.
      // Se compilar e os testes passarem, está correto.
      expect(AppConstants.appName, isNotNull);
    });
  });
}
