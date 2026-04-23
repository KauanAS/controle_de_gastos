// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IncomeModelAdapter extends TypeAdapter<IncomeModel> {
  @override
  final int typeId = 5;

  @override
  IncomeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IncomeModel(
      hiveId: fields[0] as String,
      hiveDescription: fields[1] as String,
      hiveAmount: fields[2] as double,
      hiveCategory: fields[3] as IncomeCategoryEnum,
      hiveDateTime: fields[4] as DateTime,
      hiveObservation: fields[5] as String?,
      hiveSyncStatus: fields[6] as SyncStatus,
      hiveCreatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, IncomeModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.hiveId)
      ..writeByte(1)
      ..write(obj.hiveDescription)
      ..writeByte(2)
      ..write(obj.hiveAmount)
      ..writeByte(3)
      ..write(obj.hiveCategory)
      ..writeByte(4)
      ..write(obj.hiveDateTime)
      ..writeByte(5)
      ..write(obj.hiveObservation)
      ..writeByte(6)
      ..write(obj.hiveSyncStatus)
      ..writeByte(7)
      ..write(obj.hiveCreatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
