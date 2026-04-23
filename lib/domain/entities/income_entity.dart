import 'package:equatable/equatable.dart';
import 'package:controle_de_gastos/domain/enums/income_category_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

class IncomeEntity extends Equatable {
  final String id;
  final String description;
  final double amount;
  final IncomeCategoryEnum category;
  final DateTime dateTime;
  final String? observation;
  final SyncStatus syncStatus;
  final DateTime createdAt;

  const IncomeEntity({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.dateTime,
    this.observation,
    this.syncStatus = SyncStatus.pending,
    required this.createdAt,
  });

  IncomeEntity copyWith({
    String? id,
    String? description,
    double? amount,
    IncomeCategoryEnum? category,
    DateTime? dateTime,
    String? observation,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    bool clearObservation = false,
  }) {
    return IncomeEntity(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      observation: clearObservation ? null : (observation ?? this.observation),
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        description,
        amount,
        category,
        dateTime,
        observation,
        syncStatus,
        createdAt,
      ];
}
