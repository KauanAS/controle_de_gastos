import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:controle_de_gastos/data/datasources/local/income_local_datasource_impl.dart';
import 'package:controle_de_gastos/data/datasources/remote/income_remote_datasource_impl.dart';
import 'package:controle_de_gastos/data/repositories/income_repository_impl.dart';
import 'package:controle_de_gastos/domain/repositories/income_repository.dart';

final incomeLocalDataSourceProvider = Provider((ref) {
  return IncomeLocalDataSourceImpl();
});

final incomeRemoteDataSourceProvider = Provider((ref) {
  return IncomeRemoteDataSourceImpl(Supabase.instance.client);
});

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  final local = ref.watch(incomeLocalDataSourceProvider);
  final remote = ref.watch(incomeRemoteDataSourceProvider);
  return IncomeRepositoryImpl(local, remote);
});
