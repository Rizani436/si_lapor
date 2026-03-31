import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/net_guard.dart';

class LaporanKepsekService {
  final SupabaseClient sb;
  LaporanKepsekService(this.sb);

  Future<List<Map<String, dynamic>>> fetchLaporanTasmiByJenisKelas({
    required String tahunPelajaran,
    String? semester,
  }) async {
    return networkGuard(() async {
      List<String> parts = tahunPelajaran.split('-');

      int tahunAwal = int.parse(parts[0]);
      int tahunAkhir = int.parse(parts[1]);

      int selisih = tahunAkhir - tahunAwal;

      List<String> validTahunPelajaran = [];
      for (int i = 0; i < selisih; i++) {
        validTahunPelajaran.add('${tahunAwal + i}-${tahunAwal + i + 1}');
      }

      List kelasList;

      if (semester == null) {
        kelasList = await sb
            .from('kelasalquran')
            .select('id_kelas')
            .inFilter('tahun_pelajaran', validTahunPelajaran);
      } else {
        final tahunTerakhir = validTahunPelajaran.last;

        if (selisih <= 1) {
          kelasList = await sb
              .from('kelasalquran')
              .select('id_kelas')
              .eq('semester', semester)
              .inFilter('tahun_pelajaran', validTahunPelajaran);
        } else {
          final temp1 = validTahunPelajaran.last;
         validTahunPelajaran.removeLast();

          kelasList = await sb
              .from('kelasalquran')
              .select('id_kelas')
              .inFilter('tahun_pelajaran', validTahunPelajaran);
          
          kelasList.addAll(
            await sb
                .from('kelasalquran')
                .select('id_kelas')
                .eq('semester', semester)
                .eq('tahun_pelajaran', temp1),
          );
        }
      }
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
    }, 'Gagal mengambil daftar laporan');
  }

  Future<Map<int, String>> fetchNamaSiswaMap(List<int> ids) async {
    return networkGuard(() async {
      if (ids.isEmpty) return {};

      final res = await sb
          .from('datasiswa')
          .select('id_data_siswa, nama_lengkap, jumlah_juz')
          .inFilter('id_data_siswa', ids);

      final map = <int, String>{};
      for (final row in (res as List)) {
        final id = row['id_data_siswa'];
        final nama = row['nama_lengkap'];
        final targetJuz = row['jumlah_juz'];
        if (id is int && nama is String && nama.trim().isNotEmpty) {
          map[id] = [nama, targetJuz].join('||');
        }
        
      }
      return map;
    }, 'Gagal mengambil daftar siswa');
  }
}
