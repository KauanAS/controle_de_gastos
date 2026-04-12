// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_enum.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryEnumAdapter extends TypeAdapter<CategoryEnum> {
  @override
  final int typeId = 2;

  @override
  CategoryEnum read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CategoryEnum.alimentacao;
      case 1:
        return CategoryEnum.mercado;
      case 2:
        return CategoryEnum.gasolina;
      case 3:
        return CategoryEnum.transporte;
      case 4:
        return CategoryEnum.lazer;
      case 5:
        return CategoryEnum.assinaturas;
      case 6:
        return CategoryEnum.saude;
      case 7:
        return CategoryEnum.educacao;
      case 8:
        return CategoryEnum.moradia;
      case 9:
        return CategoryEnum.outros;
      default:
        return CategoryEnum.alimentacao;
    }
  }

  @override
  void write(BinaryWriter writer, CategoryEnum obj) {
    switch (obj) {
      case CategoryEnum.alimentacao:
        writer.writeByte(0);
        break;
      case CategoryEnum.mercado:
        writer.writeByte(1);
        break;
      case CategoryEnum.gasolina:
        writer.writeByte(2);
        break;
      case CategoryEnum.transporte:
        writer.writeByte(3);
        break;
      case CategoryEnum.lazer:
        writer.writeByte(4);
        break;
      case CategoryEnum.assinaturas:
        writer.writeByte(5);
        break;
      case CategoryEnum.saude:
        writer.writeByte(6);
        break;
      case CategoryEnum.educacao:
        writer.writeByte(7);
        break;
      case CategoryEnum.moradia:
        writer.writeByte(8);
        break;
      case CategoryEnum.outros:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEnumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
