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

  Future<List<KelasModel>> getAllMy(String id_user_guru) async {
    final cekRes = await _db
        .from('isiruangkelas')
        .select('id_ruang_kelas')
        .eq('id_user_guru', id_user_guru);

    final cek = (cekRes as List).cast<Map<String, dynamic>>();
    if (cek.isEmpty) return [];

    final ids = cek
        .map((e) => e['id_ruang_kelas'])
        .where((v) => v != null)
        .toList();

    if (ids.isEmpty) return [];

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
        .filter('id_ruang_kelas', 'in', '(${ids.join(',')})')
        .order('kode_kelas', ascending: true);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(KelasModel.fromJson).toList();
  }

  Future<List<KelasModel>> getAllMySiswa(String id_user_siswa) async {
    final cekRes = await _db
        .from('isiruangkelas')
        .select('id_ruang_kelas')
        .eq('id_user_siswa', id_user_siswa);

    final cek = (cekRes as List).cast<Map<String, dynamic>>();
    if (cek.isEmpty) return [];

    final ids = cek
        .map((e) => e['id_ruang_kelas'])
        .where((v) => v != null)
        .toList();

    if (ids.isEmpty) return [];

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
        .filter('id_ruang_kelas', 'in', '(${ids.join(',')})')
        .order('kode_kelas', ascending: true);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(KelasModel.fromJson).toList();
  }

  Future<KelasModel> createByGuru(KelasModel payload, String? id) async {
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

    KelasModel temp = KelasModel.fromJson(res);
    await _db
        .from('isiruangkelas')
        .insert({'id_ruang_kelas': temp.idRuangKelas, 'id_user_guru': id})
        .select()
        .single();

    return temp;
  }

  Future<int?> getMy(String id_user_siswa, int idKelas) async {
    final res = await _db
        .from('isiruangkelas')
        .select('id_data_siswa')
        .eq('id_user_siswa', id_user_siswa)
        .eq('id_ruang_kelas', idKelas)
        .maybeSingle();

    if (res == null) return null;

    return res['id_data_siswa'] as int?;
  }
}
