import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/isi_ruang_kelas_model.dart';

class IsiRuangKelasService {
  final SupabaseClient _db;
  IsiRuangKelasService(this._db);

  Future<List<IsiRuangKelasModel>> getByRuangKelas(int idRuangKelas) async {
    final res = await _db
        .from('isiruangkelas')
        .select(
          'id, id_ruang_kelas, id_data_siswa, id_data_guru, id_user_siswa, id_user_guru',
        )
        .eq('id_ruang_kelas', idRuangKelas)
        .order('id', ascending: true);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(IsiRuangKelasModel.fromJson).toList();
  }

  Future<List<IsiRuangKelasModel>> getIsiRuangKelasByRuang(
    int idRuangKelas,
  ) async {
    final res = await _db
        .from('isiruangkelas')
        .select('''
          id,
          id_ruang_kelas,
          id_data_siswa,
          id_user_siswa,
          id_data_guru,
          id_user_guru,
          siswa:datasiswa(nama_lengkap),
          guru:dataguru(nama_lengkap)
        ''')
        .eq('id_ruang_kelas', idRuangKelas)
        .order('id', ascending: true);

    return (res as List)
        .map((e) => IsiRuangKelasModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tambahSiswa({
    required int idRuangKelas,
    required int idDataSiswa,
  }) async {
    await _db.from('isiruangkelas').insert({
      'id_ruang_kelas': idRuangKelas,
      'id_data_siswa': idDataSiswa,
    });
  }

  Future<void> updateData({
    required int isiruangkelasId,
    required String idUserGuru,
    required int idDataGuru,
  }) async {
    await _db
        .from('isiruangkelas')
        .update({'id_data_guru': idDataGuru})
        .eq('id_ruang_kelas', isiruangkelasId)
        .eq('id_user_guru', idUserGuru);
  }

  Future<void> unlinkSiswa({required int isiruangkelasId}) async {
    await _db
        .from('isiruangkelas')
        .update({'id_user_siswa': null})
        .eq('id', isiruangkelasId);
  }

  Future<void> deleteSiswaRelasi({required int isiruangkelasId}) async {
    await _db.from('isiruangkelas').delete().eq('id', isiruangkelasId);
  }

Future<String?> getIdUser({
  required int isiruangkelasId,
  required int idDataSiswa,
}) async {
  final res = await _db
      .from('isiruangkelas')
      .select('id_user_siswa')
      .eq('id_ruang_kelas', isiruangkelasId)
      .eq('id_data_siswa', idDataSiswa)
      .single();

  return res['id_user_siswa'] as String?;
}
}
