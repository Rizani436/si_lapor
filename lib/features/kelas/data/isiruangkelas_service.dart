import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/isiruangkelasnama_model.dart';

class IsiRuangKelasService {
  final SupabaseClient _db;
  IsiRuangKelasService(this._db);

  Future<List<IsiRuangKelasNamaModel>> getByRuangKelas(int idRuangKelas) async {
    final res = await _db
        .from('isiruangkelas')
        .select('id, id_ruang_kelas, id_data_siswa, id_data_guru, id_user_siswa, id_user_guru')
        .eq('id_ruang_kelas', idRuangKelas)
        .order('id', ascending: true);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(IsiRuangKelasNamaModel.fromJson).toList();
  }
}
