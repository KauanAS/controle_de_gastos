import 'package:flutter_test/flutter_test.dart';
import 'package:controle_de_gastos/data/models/income_model.dart';
import 'package:controle_de_gastos/domain/enums/income_category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

void main() {
  group('IncomeModel', () {
    final now = DateTime.now();
    
    test('deve converter corretamente de e para JSON', () {
      final json = {
        'id_local': 'income-123',
        'descricao': 'Venda de bicicleta',
        'valor': 1500.50,
        'categoria': 'vendas',
        'data_ocorrencia': now.toUtc().toIso8601String(),
        'observacao': 'Vendido no PIX',
        'criado_em': now.toUtc().toIso8601String(),
      };

      final model = IncomeModel.fromJson(json);

      expect(model.hiveId, 'income-123');
      expect(model.hiveDescription, 'Venda de bicicleta');
      expect(model.hiveAmount, 1500.50);
      expect(model.hiveCategory, IncomeCategoryEnum.vendas);
      expect(model.hiveObservation, 'Vendido no PIX');
      expect(model.hiveSyncStatus, SyncStatus.synced);

      final exportedJson = model.toJson();
      expect(exportedJson['id_local'], 'income-123');
      expect(exportedJson['valor'], 1500.50);
      expect(exportedJson['categoria'], 'vendas');
    });

    test('deve criar com sucesso a partir da entidade', () {
      final model = IncomeModel(
        hiveId: '2',
        hiveDescription: 'Salário',
        hiveAmount: 5000,
        hiveCategory: IncomeCategoryEnum.salario,
        hiveDateTime: now,
        hiveObservation: null,
        hiveSyncStatus: SyncStatus.pending,
        hiveCreatedAt: now,
      );

      final entity = model.toEntity();
      
      expect(entity.id, '2');
      expect(entity.description, 'Salário');
      expect(entity.syncStatus, SyncStatus.pending);

      final reModel = IncomeModel.fromEntity(entity);
      expect(reModel.hiveId, '2');
      expect(reModel.hiveDescription, 'Salário');
    });
  });
}
