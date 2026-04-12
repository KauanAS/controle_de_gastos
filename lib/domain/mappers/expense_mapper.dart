import 'package:controle_de_gastos/domain/models/expense_model.dart';
import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

/// Converte entre ExpenseModel (camada data) e ExpenseEntity (camada domain).
class ExpenseMapper {
  ExpenseMapper._();

  /// Model → Entity (para uso nas telas e regras de negócio)
  static ExpenseEntity toEntity(ExpenseModel model) {
    return ExpenseEntity(
      id: model.id,
      amount: model.amount,
      category: model.category,
      paymentMethod: model.paymentMethod,
      dateTime: model.dateTime,
      originalText: model.originalText,
      syncStatus: model.syncStatus,
      createdAt: model.createdAt,
      lastSyncAttemptAt: model.lastSyncAttemptAt,
      syncErrorMessage: model.syncErrorMessage,
      remoteId: model.remoteId,
    );
  }

  /// Entity → Model (para persistir no Hive)
  static ExpenseModel toModel(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      amount: entity.amount,
      category: entity.category,
      paymentMethod: entity.paymentMethod,
      dateTime: entity.dateTime,
      originalText: entity.originalText,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      lastSyncAttemptAt: entity.lastSyncAttemptAt,
      syncErrorMessage: entity.syncErrorMessage,
      remoteId: entity.remoteId,
    );
  }

  /// Atualiza um model existente com os dados de sync (evita recriar o HiveObject)
  static void applySyncResult({
    required ExpenseModel model,
    required SyncStatus status,
    String? errorMessage,
    String? remoteId,
  }) {
    model.syncStatus = status;
    model.lastSyncAttemptAt = DateTime.now();
    model.syncErrorMessage = errorMessage;
    model.remoteId = remoteId;
  }
}