import 'package:hive/hive.dart';
import 'package:controle_de_gastos/core/constants/app_constants.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

part 'expense_model.g.dart';

/// Model persistido no Hive.
/// Contém todos os campos necessários para offline first + sync futura.
@HiveType(typeId: AppConstants.hiveAdapterExpenseModel)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final CategoryEnum category;

  @HiveField(3)
  final PaymentMethod paymentMethod;

  @HiveField(4)
  final DateTime dateTime;

  @HiveField(5)
  final String originalText;

  @HiveField(6)
  SyncStatus syncStatus;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  DateTime? lastSyncAttemptAt;

  @HiveField(9)
  String? syncErrorMessage;

  @HiveField(10)
  String? remoteId;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.dateTime,
    required this.originalText,
    required this.syncStatus,
    required this.createdAt,
    this.lastSyncAttemptAt,
    this.syncErrorMessage,
    this.remoteId,
  });

  /// Converte para JSON no formato esperado pelo backend (Google Apps Script).
  Map<String, dynamic> toBackendJson() {
    return {
      'dataHora': dateTime.toIso8601String(),
      'tipo': category.backendKey,
      'valor': amount,
      'pagamento': paymentMethod.backendKey,
      'textoOriginal': originalText,
    };
  }
}