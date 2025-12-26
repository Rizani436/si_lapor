import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/siswa_pick.dart';

class GabungKelasService {
  final SupabaseClient sb;

  GabungKelasService(this.sb);

  Future<Map<String, dynamic>?> getRuangByKode(String kodeKelas) async {
    return sb
        .from('ruangkelas')
        .select('id_ruang_kelas,kode_kelas')
        .eq('kode_kelas', kodeKelas)
        .maybeSingle();
  }

  Future<List<SiswaPick>> getSiswaKosongByRuang(int idRuangKelas) async {
    final res = await sb
        .from('isiruangkelas')
        .select('id_data_siswa, datasiswa(nama_lengkap)')
        .eq('id_ruang_kelas', idRuangKelas)
        .filter('id_user_siswa', 'is', null);

    final list = (res as List)
        .map((e) => e as Map<String, dynamic>)
        .where((m) => m['id_data_siswa'] != null)
        .map(SiswaPick.fromJoinJson)
        .toList();

    return list;
  }

  Future<void> gabungKelas({
    required int idRuangKelas,
    required int idDataSiswa,
    required String userId,
  }) async {
    await sb
        .from('isiruangkelas')
        .update({'id_user_siswa': userId})
        .eq('id_ruang_kelas', idRuangKelas)
        .eq('id_data_siswa', idDataSiswa)
        .filter('id_user_siswa', 'is', null);
  }
}
