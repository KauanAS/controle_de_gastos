import 'package:hive_flutter/hive_flutter.dart';

part 'income_category_enum.g.dart';

@HiveType(typeId: 4)
enum IncomeCategoryEnum {
  @HiveField(0)
  salario,
  @HiveField(1)
  vendas,
  @HiveField(2)
  rendimento,
  @HiveField(3)
  pix,
  @HiveField(4)
  outros,
}

extension IncomeCategoryEnumExtension on IncomeCategoryEnum {
  String get displayName {
    switch (this) {
      case IncomeCategoryEnum.salario:
        return 'Salário';
      case IncomeCategoryEnum.vendas:
        return 'Vendas';
      case IncomeCategoryEnum.rendimento:
        return 'Rendimentos';
      case IncomeCategoryEnum.pix:
        return 'Pix Recebido';
      case IncomeCategoryEnum.outros:
        return 'Outros';
    }
  }

  String get icon {
    switch (this) {
      case IncomeCategoryEnum.salario:
        return '💼';
      case IncomeCategoryEnum.vendas:
        return '🏷️';
      case IncomeCategoryEnum.rendimento:
        return '📈';
      case IncomeCategoryEnum.pix:
        return '💸';
      case IncomeCategoryEnum.outros:
        return '📦';
    }
  }
}
