import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/net_guard.dart';

class LaporanService {
  final SupabaseClient sb;
  LaporanService(this.sb);

  Future<List<Map<String, dynamic>>> getByTanggal({
    required int idRuangKelas,
    required int idDataSiswa,
    required String tanggal,
  }) async {
    return networkGuard(() async {
      final res = await sb
          .from('laporan')
          .select()
          .eq('id_ruang_kelas', idRuangKelas)
          .eq('id_data_siswa', idDataSiswa)
          .eq('tanggal', tanggal)
          .order('id_laporan', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    }, 'Gagal mengambil daftar laporan');
  }

  Future<void> create(Map<String, dynamic> payload) async {
    return networkGuard(() async {
      await sb.from('laporan').insert(payload);
    }, 'Gagal membuat laporan');
  }

  Future<void> update(int idLaporan, Map<String, dynamic> payload) async {
    return networkGuard(() async {
      await sb.from('laporan').update(payload).eq('id_laporan', idLaporan);
    }, 'Gagal mengubah laporan');
  }

  Future<void> delete(int idLaporan) async {
    return networkGuard(() async {
      await sb.from('laporan').delete().eq('id_laporan', idLaporan);
    }, 'Gagal menghapus laporan');
  }

  Future<List<Map<String, dynamic>>> getLaporanRange({
    required int idSiswa,
    required int idRuangKelas,
    required DateTime start,
    required DateTime end,
  }) async {
    return networkGuard(() async {

      final res = await sb
          .from('laporan')
          .select()
          .eq('id_data_siswa', idSiswa)
          .eq('id_ruang_kelas', idRuangKelas)
          .gte('tanggal', start.toIso8601String())
          .lte('tanggal', end.toIso8601String())
          .order('tanggal');

      return List<Map<String, dynamic>>.from(res);
    }, 'Gagal mengambil daftar laporan');
  }

  Future<List<Map<String, dynamic>>> getLaporan10({
    required int idSiswa,
    required int idRuangKelas,
    String program = '',
  }) async {
    return networkGuard(() async {
      
      // if (program == 'Tahsin') {
      //   final res = await sb
      //     .from('laporan')
      //     .select()
      //     .eq('id_data_siswa', idSiswa)
      //     .eq('id_ruang_kelas', idRuangKelas)
      //     .not(program, 'is', null)
      //     .order('tanggal', ascending: false)
      //     .limit(10);

      //   return List<Map<String, dynamic>>.from(res);
      // }
      // else if
      final res = await sb
          .from('laporan')
          .select()
          .eq('id_data_siswa', idSiswa)
          .eq('id_ruang_kelas', idRuangKelas)
          .eq('pelapor', 'Guru')
          .not(program, 'is', null)
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(res);
    }, 'Gagal mengambil daftar laporan');
  }

  Future<Map<String, dynamic>?> getLastLaporan({
    required int idSiswa,
    required int idRuangKelas,
    required String program,
    required String pelapor,
  }) async {
    return networkGuard(() async {
      final res = await sb
          .from('laporan')
          .select()
          .eq('id_data_siswa', idSiswa)
          .eq('id_ruang_kelas', idRuangKelas)
          .eq('pelapor', pelapor)
          .not(program, 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return res;
    }, 'Gagal mengambil laporan terakhir');
  }
}
