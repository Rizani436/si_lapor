import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/isi_ruang_kelas_model.dart';
import '../../../core/network/net_guard.dart';

class IsiRuangKelasService {
  final SupabaseClient _db;
  IsiRuangKelasService(this._db);
  Future<List<IsiRuangKelasModel>> getIsiRuangKelasByRuang(
    int idRuangKelas,
  ) async {
    return networkGuard(() async {
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
    }, 'Gagal mengambil daftar siswa');
  }

  Future<void> tambahSiswa({
    required int idRuangKelas,
    required int idDataSiswa,
  }) async {
    return networkGuard(() async {
      await _db.from('isiruangkelas').insert({
        'id_ruang_kelas': idRuangKelas,
        'id_data_siswa': idDataSiswa,
      });
    }, 'Gagal mengambil daftar siswa');
  }

  Future<void> tambahGuru({
    required int idRuangKelas,
    required int idDataGuru,
  }) async {
    return networkGuard(() async {
      await _db.from('isiruangkelas').insert({
        'id_ruang_kelas': idRuangKelas,
        'id_data_guru': idDataGuru,
      });
    }, 'Gagal mengambil daftar siswa');
  }

  Future<void> updateDataByAdmin({
    required int isiruangkelasId,
    required int idDataGuru,
  }) async {
    return networkGuard(() async {
      await _db
          .from('isiruangkelas')
          .update({'id_data_guru': idDataGuru})
          .eq('id', isiruangkelasId);
    }, 'Gagal mengambil daftar siswa');
  }

  Future<void> updateData({
    required int isiruangkelasId,
    required String idUserGuru,
    required int idDataGuru,
  }) async {
    return networkGuard(() async {
      await _db
          .from('isiruangkelas')
          .update({'id_data_guru': idDataGuru})
          .eq('id_ruang_kelas', isiruangkelasId)
          .eq('id_user_guru', idUserGuru);
    }, 'Gagal mengambil daftar siswa');
  }

  Future<void> unlinkGuru({required int isiruangkelasId}) async {
    return networkGuard(() async {
      await _db
          .from('isiruangkelas')
          .update({'id_user_guru': null})
          .eq('id', isiruangkelasId);
    }, 'Gagal mengambil daftar siswa');
  }

  Future<void> unlinkSiswa({required int isiruangkelasId}) async {
    return networkGuard(() async {
      await _db
          .from('isiruangkelas')
          .update({'id_user_siswa': null})
          .eq('id', isiruangkelasId);
    }, 'Gagal mengambil daftar siswa');
  }

  Future<void> deleteSiswaRelasi({required int isiruangkelasId}) async {
    return networkGuard(() async {
      await _db.from('isiruangkelas').delete().eq('id', isiruangkelasId);
    }, 'Gagal mengambil daftar siswa');
  }

  Future<String?> getIdUser({
    required int isiruangkelasId,
    required int idDataSiswa,
  }) async {
    return networkGuard(() async {
      final res = await _db
          .from('isiruangkelas')
          .select('id_user_siswa')
          .eq('id_ruang_kelas', isiruangkelasId)
          .eq('id_data_siswa', idDataSiswa)
          .single();

      return res['id_user_siswa'] as String?;
    }, 'Gagal mengambil daftar siswa');
  }

  Future<String?> getIdUserGuru({required int idRuangKelas}) async {
    return networkGuard(() async {
      final res = await _db
          .from('isiruangkelas')
          .select('id_user_guru')
          .eq('id_ruang_kelas', idRuangKelas)
          .not('id_user_guru', 'is', null)
          .maybeSingle();

      return res?['id_user_guru'] as String?;
    }, 'Gagal mengambil id user guru');
  }

  Future<bool> cekIdDataSiswa({
    required int idRuangKelas,
    required int idDataSiswa,
  }) async {
    return networkGuard(() async {
      final res = await _db
          .from('isiruangkelas')
          .select('id')
          .eq('id_ruang_kelas', idRuangKelas)
          .eq('id_data_siswa', idDataSiswa)
          .maybeSingle();

      return res != null;
    }, 'Gagal mengambil daftar siswa');
  }
}
