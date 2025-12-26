import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final isiRuangKelasActionProvider = Provider((ref) {
  return IsiRuangKelasActionService(ref.read(supabaseProvider));
});

class IsiRuangKelasActionService {
  final SupabaseClient sb;
  IsiRuangKelasActionService(this.sb);

  Future<void> tambahSiswa({
    required int idRuangKelas,
    required int idDataSiswa,
  }) async {
    await sb.from('isiruangkelas').insert({
      'id_ruang_kelas': idRuangKelas,
      'id_data_siswa': idDataSiswa,

    });
  }

  Future<void> updateData({
    required int isiruangkelasId,
    required String idUserGuru,
    required int idDataGuru,
  }) async {
    await sb
        .from('isiruangkelas')
        .update({'id_data_guru': idDataGuru})
        .eq('id_ruang_kelas', isiruangkelasId)
        .eq('id_user_guru', idUserGuru);
  }

  Future<void> unlinkSiswa({required int isiruangkelasId}) async {
    await sb
        .from('isiruangkelas')
        .update({'id_user_siswa': null})
        .eq('id', isiruangkelasId);
  }

  Future<void> deleteSiswaRelasi({required int isiruangkelasId}) async {
    await sb.from('isiruangkelas').delete().eq('id', isiruangkelasId);
  }
}
