import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guru_model.dart';
import '../../../core/network/net_guard.dart';

class GuruService {
  final SupabaseClient _db;
  GuruService(this._db);

  Future<List<GuruModel>> getAll() async {
    return networkGuard(
      () async {
    final res = await _db
        .from('dataguru')
        .select()
        .order('nama_lengkap', ascending: true);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(GuruModel.fromJson).toList();},
      'Gagal mengambil daftar siswa',
    );
  }

  Future<GuruModel> create(GuruModel payload) async {
    return networkGuard(
      () async {
    final res = await _db
        .from('dataguru')
        .insert(payload.toInsertJson())
        .select()
        .single();

    return GuruModel.fromJson(res);},
      'Gagal mengambil daftar siswa',
    );
  }

  Future<GuruModel> update(int idDataGuru, GuruModel payload) async {
    return networkGuard(
      () async {
    final res = await _db
        .from('dataguru')
        .update(payload.toUpdateJson())
        .eq('id_data_guru', idDataGuru)
        .select()
        .single();

    return GuruModel.fromJson(res);},
      'Gagal mengambil daftar siswa',
    );
  }

  Future<void> delete(int idDataGuru) async {
    return networkGuard(
      () async {
    await _db.from('dataguru').delete().eq('id_data_guru', idDataGuru);},
      'Gagal mengambil daftar siswa',
    );
  }

  Future<GuruModel> toggleAktif(GuruModel s) async {
    return networkGuard(
      () async {
    final newVal = s.ketAktif == 1 ? 0 : 1;

    final res = await _db
        .from('dataguru')
        .update({'ket_aktif': newVal})
        .eq('id_data_guru', s.idDataGuru)
        .select()
        .single();

    return GuruModel.fromJson(res);},
      'Gagal mengambil daftar siswa',
    );
  }
}
