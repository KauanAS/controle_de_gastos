// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method_enum.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentMethodAdapter extends TypeAdapter<PaymentMethod> {
  @override
  final int typeId = 3;

  @override
  PaymentMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentMethod.pix;
      case 1:
        return PaymentMethod.dinheiro;
      case 2:
        return PaymentMethod.debito;
      case 3:
        return PaymentMethod.credito;
      case 4:
        return PaymentMethod.boleto;
      case 5:
        return PaymentMethod.outro;
      default:
        return PaymentMethod.pix;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentMethod obj) {
    switch (obj) {
      case PaymentMethod.pix:
        writer.writeByte(0);
        break;
      case PaymentMethod.dinheiro:
        writer.writeByte(1);
        break;
      case PaymentMethod.debito:
        writer.writeByte(2);
        break;
      case PaymentMethod.credito:
        writer.writeByte(3);
        break;
      case PaymentMethod.boleto:
        writer.writeByte(4);
        break;
      case PaymentMethod.outro:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
