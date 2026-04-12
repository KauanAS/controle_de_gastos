import 'package:controle_de_gastos/domain/entities/expense_entity.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/domain/models/expense_model.dart';

/// Helpers para criação de objetos de teste.
class TestHelpers {
  TestHelpers._();

  /// Cria uma ExpenseEntity com valores padrão que podem ser sobrescritos.
  static ExpenseEntity createExpenseEntity({
    String id = 'test-id-1',
    double amount = 25.50,
    CategoryEnum category = CategoryEnum.alimentacao,
    PaymentMethod paymentMethod = PaymentMethod.pix,
    DateTime? dateTime,
    String originalText = 'almoço 25,50 pix',
    SyncStatus syncStatus = SyncStatus.pending,
    DateTime? createdAt,
    DateTime? lastSyncAttemptAt,
    String? syncErrorMessage,
    String? remoteId,
  }) {
    return ExpenseEntity(
      id: id,
      amount: amount,
      category: category,
      paymentMethod: paymentMethod,
      dateTime: dateTime ?? DateTime(2026, 4, 10, 12, 30),
      originalText: originalText,
      syncStatus: syncStatus,
      createdAt: createdAt ?? DateTime(2026, 4, 10, 12, 30),
      lastSyncAttemptAt: lastSyncAttemptAt,
      syncErrorMessage: syncErrorMessage,
      remoteId: remoteId,
    );
  }

  /// Cria uma ExpenseEntity já sincronizada.
  static ExpenseEntity createSyncedExpense({
    String id = 'synced-id-1',
    double amount = 100.0,
    CategoryEnum category = CategoryEnum.gasolina,
    PaymentMethod paymentMethod = PaymentMethod.credito,
    DateTime? dateTime,
  }) {
    return createExpenseEntity(
      id: id,
      amount: amount,
      category: category,
      paymentMethod: paymentMethod,
      dateTime: dateTime,
      originalText: '100 de gasolina no crédito',
      syncStatus: SyncStatus.synced,
      remoteId: 'remote-$id',
      lastSyncAttemptAt: DateTime(2026, 4, 10, 12, 35),
    );
  }

  /// Cria uma ExpenseEntity com falha de sync.
  static ExpenseEntity createFailedExpense({
    String id = 'failed-id-1',
    double amount = 50.0,
    DateTime? dateTime,
  }) {
    return createExpenseEntity(
      id: id,
      amount: amount,
      dateTime: dateTime,
      originalText: '50 reais no mercado',
      category: CategoryEnum.mercado,
      syncStatus: SyncStatus.failed,
      syncErrorMessage: 'Timeout de conexão',
      lastSyncAttemptAt: DateTime(2026, 4, 10, 12, 35),
    );
  }

  /// Cria um ExpenseModel para testes de camada de dados.
  static ExpenseModel createExpenseModel({
    String id = 'model-id-1',
    double amount = 25.50,
    CategoryEnum category = CategoryEnum.alimentacao,
    PaymentMethod paymentMethod = PaymentMethod.pix,
    DateTime? dateTime,
    String originalText = 'almoço 25,50 pix',
    SyncStatus syncStatus = SyncStatus.pending,
    DateTime? createdAt,
    DateTime? lastSyncAttemptAt,
    String? syncErrorMessage,
    String? remoteId,
  }) {
    return ExpenseModel(
      id: id,
      amount: amount,
      category: category,
      paymentMethod: paymentMethod,
      dateTime: dateTime ?? DateTime(2026, 4, 10, 12, 30),
      originalText: originalText,
      syncStatus: syncStatus,
      createdAt: createdAt ?? DateTime(2026, 4, 10, 12, 30),
      lastSyncAttemptAt: lastSyncAttemptAt,
      syncErrorMessage: syncErrorMessage,
      remoteId: remoteId,
    );
  }

  /// Cria uma lista variada de despesas para testes de filtro e relatórios.
  static List<ExpenseEntity> createExpenseList() {
    return [
      createExpenseEntity(
        id: 'e1',
        amount: 30.0,
        category: CategoryEnum.alimentacao,
        paymentMethod: PaymentMethod.pix,
        dateTime: DateTime(2026, 4, 1, 12, 0),
        originalText: '30 reais almoço pix',
      ),
      createExpenseEntity(
        id: 'e2',
        amount: 200.0,
        category: CategoryEnum.gasolina,
        paymentMethod: PaymentMethod.credito,
        dateTime: DateTime(2026, 4, 5, 15, 0),
        originalText: '200 reais gasolina crédito',
      ),
      createExpenseEntity(
        id: 'e3',
        amount: 450.0,
        category: CategoryEnum.mercado,
        paymentMethod: PaymentMethod.debito,
        dateTime: DateTime(2026, 4, 10, 9, 0),
        originalText: '450 reais mercado débito',
      ),
      createSyncedExpense(
        id: 'e4',
        amount: 100.0,
        category: CategoryEnum.lazer,
        paymentMethod: PaymentMethod.credito,
        dateTime: DateTime(2026, 3, 15, 20, 0), // mês anterior
      ),
      createFailedExpense(
        id: 'e5',
        amount: 55.0,
        dateTime: DateTime(2026, 4, 8, 18, 0),
      ),
    ];
  }

  /// Cria despesas de meses diferentes para testes de filtro por mês.
  static List<ExpenseEntity> createMultiMonthExpenses() {
    return [
      createExpenseEntity(
        id: 'jan-1',
        amount: 100.0,
        dateTime: DateTime(2026, 1, 15),
        category: CategoryEnum.alimentacao,
      ),
      createExpenseEntity(
        id: 'fev-1',
        amount: 200.0,
        dateTime: DateTime(2026, 2, 10),
        category: CategoryEnum.gasolina,
      ),
      createExpenseEntity(
        id: 'mar-1',
        amount: 300.0,
        dateTime: DateTime(2026, 3, 20),
        category: CategoryEnum.mercado,
      ),
      createExpenseEntity(
        id: 'abr-1',
        amount: 400.0,
        dateTime: DateTime(2026, 4, 5),
        category: CategoryEnum.moradia,
      ),
      createExpenseEntity(
        id: 'abr-2',
        amount: 150.0,
        dateTime: DateTime(2026, 4, 12),
        category: CategoryEnum.lazer,
      ),
    ];
  }
}
