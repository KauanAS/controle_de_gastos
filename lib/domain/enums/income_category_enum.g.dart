// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_category_enum.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IncomeCategoryEnumAdapter extends TypeAdapter<IncomeCategoryEnum> {
  @override
  final int typeId = 4;

  @override
  IncomeCategoryEnum read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return IncomeCategoryEnum.salario;
      case 1:
        return IncomeCategoryEnum.vendas;
      case 2:
        return IncomeCategoryEnum.rendimento;
      case 3:
        return IncomeCategoryEnum.pix;
      case 4:
        return IncomeCategoryEnum.outros;
      default:
        return IncomeCategoryEnum.salario;
    }
  }

  @override
  void write(BinaryWriter writer, IncomeCategoryEnum obj) {
    switch (obj) {
      case IncomeCategoryEnum.salario:
        writer.writeByte(0);
        break;
      case IncomeCategoryEnum.vendas:
        writer.writeByte(1);
        break;
      case IncomeCategoryEnum.rendimento:
        writer.writeByte(2);
        break;
      case IncomeCategoryEnum.pix:
        writer.writeByte(3);
        break;
      case IncomeCategoryEnum.outros:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeCategoryEnumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
