import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/siswa_model.dart';

class SiswaService {
  final SupabaseClient _db;
  SiswaService(this._db);

  Future<List<SiswaModel>> getAll() async {
    final res = await _db
        .from('datasiswa')
        .select()
        .order('nama_lengkap', ascending: true);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(SiswaModel.fromJson).toList();
  }

  // Future<List<SiswaModel>> getAllAktif() async {
  //   final res = await _db
  //       .from('datasiswa')
  //       .select()
  //       .eq('ket_aktif', 1)
  //       .order('nama_lengkap', ascending: true);

  //   final list = (res as List).cast<Map<String, dynamic>>();
  //   return list.map(SiswaModel.fromJson).toList();
  // }

  Future<SiswaModel> create(SiswaModel payload) async {
    final res = await _db
        .from('datasiswa')
        .insert(payload.toInsertJson())
        .select()
        .single();

    return SiswaModel.fromJson(res);
  }

  Future<SiswaModel> update(int idDataSiswa, SiswaModel payload) async {
    final res = await _db
        .from('datasiswa')
        .update(payload.toUpdateJson())
        .eq('id_data_siswa', idDataSiswa)
        .select()
        .single();

    return SiswaModel.fromJson(res);
  }

  Future<void> delete(int idDataSiswa) async {
    await _db.from('datasiswa').delete().eq('id_data_siswa', idDataSiswa);
  }

  Future<SiswaModel> toggleAktif(SiswaModel s) async {
    final newVal = s.ketAktif == 1 ? 0 : 1;

    final res = await _db
        .from('datasiswa')
        .update({'ket_aktif': newVal})
        .eq('id_data_siswa', s.idDataSiswa)
        .select()
        .single();

    return SiswaModel.fromJson(res);
  }

  Future<SiswaModel> getSiswa(int idDataSiswa) async {
    final res = await _db
        .from('datasiswa')
        .select()
        .eq('id_data_siswa', idDataSiswa)
        .single();

    return SiswaModel.fromJson(res);
  }
}
