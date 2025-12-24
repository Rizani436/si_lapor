import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/code_generate.dart';
import '../models/kelas_model.dart';

class KelasService {
  final SupabaseClient _db;
  KelasService(this._db);

  Future<List<KelasModel>> getAll() async {
    final res = await _db
        .from('ruangkelas')
        .select('''
      id_ruang_kelas,
      id_kelas,
      kode_kelas,
      ket_aktif,
      kelasalquran (
        nama_kelas,
        tahun_pelajaran,
        semester,
        jenis_kelas
      )
    ''')
        .order('kode_kelas', ascending: true);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(KelasModel.fromJson).toList();
  }

  Future<KelasModel> create(KelasModel payload) async {
    final resKelas = await _db
        .from('kelasalquran')
        .insert({
          'nama_kelas': payload.namaKelas,
          'tahun_pelajaran': payload.tahunPelajaran,
          'semester': payload.semester,
          'jenis_kelas': payload.jenisKelas,
        })
        .select()
        .single();
    final idKelas = resKelas['id_kelas'];
    final kodeKelas = 'RK-${generateKodeKelas()}';

    final res = await _db
        .from('ruangkelas')
        .insert({
          'id_kelas': idKelas,
          'kode_kelas': kodeKelas,
          'ket_aktif': payload.ketAktif,
        })
        .select('''
        id_ruang_kelas,
        id_kelas,
        kode_kelas,
        ket_aktif,
        kelasalquran (
          nama_kelas,
          tahun_pelajaran,
          semester,
          jenis_kelas
        )
      ''')
        .single();

    return KelasModel.fromJson(res);
  }

  Future<KelasModel> update(int idRuangKelas, KelasModel payload) async {
    await _db
        .from('kelasalquran')
        .update({
          'nama_kelas': payload.namaKelas,
          'tahun_pelajaran': payload.tahunPelajaran,
          'semester': payload.semester,
          'jenis_kelas': payload.jenisKelas,
        })
        .eq('id_kelas', payload.idKelas ?? '')
        .select()
        .single();

    final res = await _db
        .from('ruangkelas')
        .update({'id_kelas': payload.idKelas, 'ket_aktif': payload.ketAktif})
        .eq('id_ruang_kelas', idRuangKelas)
        .select('''
        id_ruang_kelas,
        id_kelas,
        kode_kelas,
        ket_aktif,
        kelasalquran (
          nama_kelas,
          tahun_pelajaran,
          semester,
          jenis_kelas
        )
      ''')
        .single();

    return KelasModel.fromJson(res);
  }

  Future<KelasModel> toggleAktif(KelasModel s) async {
    final newVal = s.ketAktif == 1 ? 0 : 1;

    final res = await _db
        .from('ruangkelas')
        .update({'ket_aktif': newVal})
        .eq('id_ruang_kelas', s.idRuangKelas)
        .select('''
        id_ruang_kelas,
        id_kelas,
        kode_kelas,
        ket_aktif,
        kelasalquran (
          nama_kelas,
          tahun_pelajaran,
          semester,
          jenis_kelas
        )
      ''')
        .single();

    return KelasModel.fromJson(res);
  }

  Future<void> delete(int idRuangKelas) async {
    final row = await _db
        .from('ruangkelas')
        .select('id_kelas')
        .eq('id_ruang_kelas', idRuangKelas)
        .single();

    final int idKelas = (row['id_kelas'] as num).toInt();

    await _db.from('ruangkelas').delete().eq('id_ruang_kelas', idRuangKelas);

    await _db.from('kelasalquran').delete().eq('id_kelas', idKelas);
  }

}
