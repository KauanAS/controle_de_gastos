import 'package:hive/hive.dart';
import 'package:controle_de_gastos/core/constants/app_constants.dart';

part 'payment_method_enum.g.dart';

@HiveType(typeId: AppConstants.hiveAdapterPaymentMethod)
enum PaymentMethod {
  @HiveField(0)
  pix,

  @HiveField(1)
  dinheiro,

  @HiveField(2)
  debito,

  @HiveField(3)
  credito,

  @HiveField(4)
  boleto,

  @HiveField(5)
  outro,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.pix:
        return 'Pix';
      case PaymentMethod.dinheiro:
        return 'Dinheiro';
      case PaymentMethod.debito:
        return 'Débito';
      case PaymentMethod.credito:
        return 'Crédito';
      case PaymentMethod.boleto:
        return 'Boleto';
      case PaymentMethod.outro:
        return 'Outro';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.pix:
        return '⚡';
      case PaymentMethod.dinheiro:
        return '💵';
      case PaymentMethod.debito:
        return '💳';
      case PaymentMethod.credito:
        return '💳';
      case PaymentMethod.boleto:
        return '🧾';
      case PaymentMethod.outro:
        return '💰';
    }
  }

  /// Chave usada no envio ao backend
  String get backendKey => name.toUpperCase();
}
