import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:controle_de_gastos/data/datasources/remote/income_remote_datasource.dart';
import 'package:controle_de_gastos/data/models/income_model.dart';

class IncomeRemoteDataSourceImpl implements IncomeRemoteDataSource {
  final SupabaseClient _supabase;

  IncomeRemoteDataSourceImpl(this._supabase);

  String get _userId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    return user.id;
  }

  @override
  Future<List<IncomeModel>> getIncomes() async {
    final response = await _supabase
        .from('receitas')
        .select()
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .order('data_ocorrencia', ascending: false);

    return (response as List).map((json) {
      return IncomeModel.fromJson(json);
    }).toList();
  }

  @override
  Future<void> saveIncome(IncomeModel income) async {
    final json = income.toJson();

    await _supabase.from('receitas').upsert(
      {
        'user_id': _userId,
        ...json,
      },
      onConflict: 'user_id,id_local',
    );
  }

  @override
  Future<void> deleteIncome(String id) async {
    // Delete direto no DB
    await _supabase.from('receitas').delete().eq('id_local', id).eq('user_id', _userId);
  }
}
