import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/net_guard.dart';

class LaporanKepsekService {
  final SupabaseClient sb;
  LaporanKepsekService(this.sb);

  Future<List<Map<String, dynamic>>> fetchLaporanTasmiByJenisKelas({
    required String tahunPelajaran,
    required String semester,
    required String jenisKelas,
  }) async {
    return networkGuard(
      () async {
    final kelasList = await sb
        .from('kelasalquran')
        .select('id_kelas')
        .eq('tahun_pelajaran', tahunPelajaran.trim())
        .eq('semester', semester.trim())
        .eq('jenis_kelas', jenisKelas);

    final idKelasList = (kelasList as List)
        .map((e) => e['id_kelas'] as int)
        .toList();
    if (idKelasList.isEmpty) return [];

    final ruangList = await sb
        .from('ruangkelas')
        .select('id_ruang_kelas')
        .inFilter('id_kelas', idKelasList);

    final idRuangList = (ruangList as List)
        .map((e) => e['id_ruang_kelas'] as int)
        .toList();
    if (idRuangList.isEmpty) return [];

    final laporan = await sb
        .from('laporan')
        .select('id_data_siswa, tasmi')
        .eq('pelapor', "Guru")
        .inFilter('id_ruang_kelas', idRuangList);

    return (laporan as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
        },
      'Gagal mengambil daftar siswa',
    );
  }

  Future<Map<int, String>> fetchNamaSiswaMap(List<int> ids) async {
    return networkGuard(
      () async {
    if (ids.isEmpty) return {};

    final res = await sb
        .from('datasiswa')
        .select('id_data_siswa, nama_lengkap')
        .inFilter('id_data_siswa', ids);

    final map = <int, String>{};
    for (final row in (res as List)) {
      final id = row['id_data_siswa'];
      final nama = row['nama_lengkap'];
      if (id is int && nama is String && nama.trim().isNotEmpty) {
        map[id] = nama.trim();
      }
    }
    return map;
    },
      'Gagal mengambil daftar siswa',
    );
  }
}
