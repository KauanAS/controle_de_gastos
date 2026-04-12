/// Constantes globais do aplicativo.
class AppConstants {
  AppConstants._();

  // --- Hive ---
  static const String hiveBoxExpenses = 'expenses_box';
  static const int hiveAdapterExpenseModel = 0;
  static const int hiveAdapterSyncStatus = 1;
  static const int hiveAdapterCategory = 2;
  static const int hiveAdapterPaymentMethod = 3;

  // --- UI ---
  static const String appName = 'Gastos';
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 0.0;

  // --- Datas ---
  static const String dateFormatDisplay = 'dd/MM/yyyy';
  static const String dateTimeFormatDisplay = 'dd/MM/yyyy HH:mm';
  static const String dateFormatIso = "yyyy-MM-dd'T'HH:mm:ss";

  // --- Mensagens ---
  static const String msgSaveSuccess = 'Lançamento salvo com sucesso!';
  static const String msgSyncSuccess = 'Sincronizado com sucesso!';
  static const String msgSyncFailed = 'Falha ao sincronizar. Tente novamente mais tarde.';
  static const String msgParseError = 'Não foi possível interpretar a frase. Tente ser mais específico.';
  static const String msgEmptyField = 'Digite uma frase para continuar.';
}