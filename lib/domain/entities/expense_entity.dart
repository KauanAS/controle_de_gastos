import 'package:equatable/equatable.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';

/// Entidade central do domínio.
/// Não depende de Hive, Flutter ou qualquer framework externo.
class ExpenseEntity extends Equatable {
  /// ID único local (UUID v4)
  final String id;

  /// Valor em reais
  final double amount;

  /// Categoria do gasto
  final CategoryEnum category;

  /// Forma de pagamento
  final PaymentMethod paymentMethod;

  /// Data e hora do gasto
  final DateTime dateTime;

  /// Texto original digitado/falado pelo usuário
  final String originalText;

  /// Status de sincronização com o backend
  final SyncStatus syncStatus;

  /// Data de criação do registro local
  final DateTime createdAt;

  /// Última tentativa de sincronização (null se nunca tentou)
  final DateTime? lastSyncAttemptAt;

  /// Mensagem de erro da última tentativa (null se não houve erro)
  final String? syncErrorMessage;

  /// ID gerado pelo backend após sync bem-sucedido (null enquanto não sincronizado)
  final String? remoteId;

  const ExpenseEntity({
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

  /// Cria uma cópia com campos alterados.
  ExpenseEntity copyWith({
    String? id,
    double? amount,
    CategoryEnum? category,
    PaymentMethod? paymentMethod,
    DateTime? dateTime,
    String? originalText,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? lastSyncAttemptAt,
    String? syncErrorMessage,
    String? remoteId,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      dateTime: dateTime ?? this.dateTime,
      originalText: originalText ?? this.originalText,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      lastSyncAttemptAt: lastSyncAttemptAt ?? this.lastSyncAttemptAt,
      syncErrorMessage: syncErrorMessage ?? this.syncErrorMessage,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        category,
        paymentMethod,
        dateTime,
        originalText,
        syncStatus,
        createdAt,
        lastSyncAttemptAt,
        syncErrorMessage,
        remoteId,
      ];
}