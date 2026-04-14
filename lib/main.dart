import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:controle_de_gastos/core/theme/app_theme.dart';
import 'package:controle_de_gastos/core/routes/app_router.dart';
import 'package:controle_de_gastos/core/constants/app_constants.dart';
import 'package:controle_de_gastos/domain/models/expense_model.dart';
import 'package:controle_de_gastos/domain/enums/sync_status_enum.dart';
import 'package:controle_de_gastos/domain/enums/category_enum.dart';
import 'package:controle_de_gastos/domain/enums/payment_method_enum.dart';
import 'package:controle_de_gastos/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Esconde a barra de navegação do Android e a barra de status, exibindo sob demanda (Immersive mode)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Inicializa locale pt_BR
  await initializeDateFormatting('pt_BR');

  // Inicializa Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Inicializa Hive
  await Hive.initFlutter();
  Hive.registerAdapter(SyncStatusAdapter());
  Hive.registerAdapter(CategoryEnumAdapter());
  Hive.registerAdapter(PaymentMethodAdapter());
  Hive.registerAdapter(ExpenseModelAdapter());
  await Hive.openBox<ExpenseModel>(AppConstants.hiveBoxExpenses);

  runApp(
    const ProviderScope(
      child: GastosApp(),
    ),
  );
}

class GastosApp extends ConsumerWidget {
  const GastosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
