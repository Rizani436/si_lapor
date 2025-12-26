import 'package:supabase_flutter/supabase_flutter.dart';

class LaporanService {
  final SupabaseClient sb;
  LaporanService(this.sb);

  Future<List<Map<String, dynamic>>> getByTanggal({
    required int idRuangKelas,
    required int idDataSiswa,
    required String tanggal,
  }) async {
    final res = await sb
        .from('laporan')
        .select()
        .eq('id_ruang_kelas', idRuangKelas)
        .eq('id_data_siswa', idDataSiswa)
        .eq('tanggal', tanggal)
        .order('id_laporan', ascending: false);

    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await sb.from('laporan').insert(payload);
  }

  Future<void> update(int idLaporan, Map<String, dynamic> payload) async {
    await sb.from('laporan').update(payload).eq('id_laporan', idLaporan);
  }

  Future<void> delete(int idLaporan) async {
    await sb.from('laporan').delete().eq('id_laporan', idLaporan);
  }
}
