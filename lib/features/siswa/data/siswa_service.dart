import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/siswa_model.dart';
import '../../../core/network/net_guard.dart';

class SiswaService {
  final SupabaseClient _db;
  SiswaService(this._db);

  Future<List<SiswaModel>> getAll() async {
    return networkGuard(
      () async {
        final res = await _db
            .from('datasiswa')
            .select()
            .order('nama_lengkap', ascending: true);

        final list = (res as List).cast<Map<String, dynamic>>();
        return list.map(SiswaModel.fromJson).toList();
      },
      'Gagal mengambil daftar siswa',
    );
  }

  Future<SiswaModel> create(SiswaModel payload) async {
    return networkGuard(
      () async {
        final res = await _db
            .from('datasiswa')
            .insert(payload.toInsertJson())
            .select()
            .single();
        return SiswaModel.fromJson(res);
      },
      'Gagal menambah siswa',
    );
  }

  Future<SiswaModel> update(int idDataSiswa, SiswaModel payload) async {
    return networkGuard(
      () async {
        final res = await _db
            .from('datasiswa')
            .update(payload.toUpdateJson())
            .eq('id_data_siswa', idDataSiswa)
            .select()
            .single();
        return SiswaModel.fromJson(res);
      },
      'Gagal mengedit siswa',
    );
  }

  Future<void> delete(int idDataSiswa) async {
    return networkGuard(
      () async {
        await _db.from('datasiswa').delete().eq('id_data_siswa', idDataSiswa);
      },
      'Gagal menghapus siswa',
    );
  }

  Future<SiswaModel> toggleAktif(SiswaModel s) async {
    return networkGuard(
      () async {
        final newVal = s.ketAktif == 1 ? 0 : 1;
        final res = await _db
            .from('datasiswa')
            .update({'ket_aktif': newVal})
            .eq('id_data_siswa', s.idDataSiswa)
            .select()
            .single();
        return SiswaModel.fromJson(res);
      },
      'Gagal mengubah status aktif siswa',
    );
  }

  Future<SiswaModel> getSiswa(int idDataSiswa) async {
    return networkGuard(
      () async {
        final res = await _db
            .from('datasiswa')
            .select()
            .eq('id_data_siswa', idDataSiswa)
            .single();
        return SiswaModel.fromJson(res);
      },
      'Gagal mengambil detail siswa',
    );
  }
}
