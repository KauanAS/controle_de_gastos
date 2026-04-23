import 'package:hive_flutter/hive_flutter.dart';
import 'package:controle_de_gastos/domain/entities/income_entity.dart';
import 'package:controle_de_gastos/domain/enums/income_category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

part 'income_model.g.dart';

@HiveType(typeId: 5)
class IncomeModel extends IncomeEntity {
  @HiveField(0)
  final String hiveId;

  @HiveField(1)
  final String hiveDescription;

  @HiveField(2)
  final double hiveAmount;

  @HiveField(3)
  final IncomeCategoryEnum hiveCategory;

  @HiveField(4)
  final DateTime hiveDateTime;

  @HiveField(5)
  final String? hiveObservation;

  @HiveField(6)
  final SyncStatus hiveSyncStatus;

  @HiveField(7)
  final DateTime hiveCreatedAt;

  const IncomeModel({
    required this.hiveId,
    required this.hiveDescription,
    required this.hiveAmount,
    required this.hiveCategory,
    required this.hiveDateTime,
    this.hiveObservation,
    required this.hiveSyncStatus,
    required this.hiveCreatedAt,
  }) : super(
          id: hiveId,
          description: hiveDescription,
          amount: hiveAmount,
          category: hiveCategory,
          dateTime: hiveDateTime,
          observation: hiveObservation,
          syncStatus: hiveSyncStatus,
          createdAt: hiveCreatedAt,
        );

  factory IncomeModel.fromEntity(IncomeEntity entity) {
    return IncomeModel(
      hiveId: entity.id,
      hiveDescription: entity.description,
      hiveAmount: entity.amount,
      hiveCategory: entity.category,
      hiveDateTime: entity.dateTime,
      hiveObservation: entity.observation,
      hiveSyncStatus: entity.syncStatus,
      hiveCreatedAt: entity.createdAt,
    );
  }

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      hiveId: json['id_local'] as String,
      hiveDescription: json['descricao'] as String,
      hiveAmount: (json['valor'] as num).toDouble(),
      hiveCategory: IncomeCategoryEnum.values.firstWhere(
        (e) => e.name == json['categoria'],
        orElse: () => IncomeCategoryEnum.outros,
      ),
      hiveDateTime: DateTime.parse(json['data_ocorrencia'] as String).toLocal(),
      hiveObservation: json['observacao'] as String?,
      hiveSyncStatus: SyncStatus.synced, // Dados vindos do DB sempre synced
      hiveCreatedAt: DateTime.parse(json['criado_em'] as String).toLocal(),
    );
  }

  // Não usamos toJson porque o repository escreve manualmente os dados
  // pro formato do Supabase (para lidar com user_id),
  // mas deixamos implementado por consistência local.
  Map<String, dynamic> toJson() {
    return {
      'id_local': hiveId,
      'descricao': hiveDescription,
      'valor': hiveAmount,
      'categoria': hiveCategory.name,
      'data_ocorrencia': hiveDateTime.toUtc().toIso8601String(),
      'observacao': hiveObservation,
      'criado_em': hiveCreatedAt.toUtc().toIso8601String(),
    };
  }

  IncomeEntity toEntity() {
    return IncomeEntity(
      id: hiveId,
      description: hiveDescription,
      amount: hiveAmount,
      category: hiveCategory,
      dateTime: hiveDateTime,
      observation: hiveObservation,
      syncStatus: hiveSyncStatus,
      createdAt: hiveCreatedAt,
    );
  }
}
