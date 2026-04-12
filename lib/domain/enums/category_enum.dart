import 'package:hive/hive.dart';
import 'package:controle_de_gastos/core/constants/app_constants.dart';

part 'category_enum.g.dart';

@HiveType(typeId: AppConstants.hiveAdapterCategory)
enum CategoryEnum {
  @HiveField(0)
  alimentacao,

  @HiveField(1)
  mercado,

  @HiveField(2)
  gasolina,

  @HiveField(3)
  transporte,

  @HiveField(4)
  lazer,

  @HiveField(5)
  assinaturas,

  @HiveField(6)
  saude,

  @HiveField(7)
  educacao,

  @HiveField(8)
  moradia,

  @HiveField(9)
  outros,
}

extension CategoryEnumExtension on CategoryEnum {
  String get displayName {
    switch (this) {
      case CategoryEnum.alimentacao:
        return 'Alimentação';
      case CategoryEnum.mercado:
        return 'Mercado';
      case CategoryEnum.gasolina:
        return 'Gasolina';
      case CategoryEnum.transporte:
        return 'Transporte';
      case CategoryEnum.lazer:
        return 'Lazer';
      case CategoryEnum.assinaturas:
        return 'Assinaturas';
      case CategoryEnum.saude:
        return 'Saúde';
      case CategoryEnum.educacao:
        return 'Educação';
      case CategoryEnum.moradia:
        return 'Moradia';
      case CategoryEnum.outros:
        return 'Outros';
    }
  }

  String get icon {
    switch (this) {
      case CategoryEnum.alimentacao:
        return '🍽️';
      case CategoryEnum.mercado:
        return '🛒';
      case CategoryEnum.gasolina:
        return '⛽';
      case CategoryEnum.transporte:
        return '🚌';
      case CategoryEnum.lazer:
        return '🎬';
      case CategoryEnum.assinaturas:
        return '📱';
      case CategoryEnum.saude:
        return '🏥';
      case CategoryEnum.educacao:
        return '📚';
      case CategoryEnum.moradia:
        return '🏠';
      case CategoryEnum.outros:
        return '📦';
    }
  }

  /// Chave usada no envio ao backend
  String get backendKey => name.toUpperCase();
}