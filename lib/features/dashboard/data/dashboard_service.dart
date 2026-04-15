import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teacher_dashboard_model.dart';
import '../models/parent_dashboard_model.dart';
import '../models/kepsek_dashboard_model.dart';
import '../../kelas/models/kelas_model.dart';
import '../../kelas/data/kelas_service.dart';
import '../../kelas/models/isi_ruang_kelas_model.dart';
import '../../laporan/models/laporan_model.dart';

class DashboardService {
  final SupabaseClient _db;

  DashboardService(this._db);

  Future<int> getCount(String table, String status) async {
    var query = _db.from(table).select();

    if (status != 'Semua') {
      if (table == 'profiles') {
        query = query.eq('is_active', status == 'Aktif');
      } else {
        query = query.eq('ket_aktif', status == 'Aktif' ? 1 : 0);
      }
    }

    final res = await query;

    final list = (res as List);
    return list.length;
  }

  Future<List<TeacherDashboardItem>> getDashboardGuru(String uuidGuru) async {
    KelasService kelasService = KelasService(_db);
    final today = DateTime.now();
    final todayString =
        "${today.year.toString().padLeft(4, '0')}-"
        "${today.month.toString().padLeft(2, '0')}-"
        "${today.day.toString().padLeft(2, '0')}";

    final ruangRes = await kelasService.getAllMy(uuidGuru);

    final ruangAktif = ruangRes.where((e) => e.ketAktif == 1).toList();

    if (ruangAktif.isEmpty) return [];

    final ruangIds = ruangAktif.map((e) => e.idRuangKelas).toList();

    final isiRes = await _db
        .from('isiruangkelas')
        .select('id_ruang_kelas, id_data_siswa, datasiswa(nama_lengkap)')
        .inFilter('id_ruang_kelas', ruangIds)
        .filter('id_data_guru', 'is', null);

    final siswaList = isiRes.where((e) => e['id_data_siswa'] != null).toList();

    if (siswaList.isEmpty) return [];

    final siswaIds = siswaList.map((e) => e['id_data_siswa']).toSet().toList();

    final laporanRes = await _db
        .from('laporan')
        .select()
        .eq('tanggal', todayString)
        .eq('pelapor', 'Guru')
        .inFilter('id_ruang_kelas', ruangIds)
        .inFilter('id_data_siswa', siswaIds);

    final laporanList = (laporanRes as List)
        .map((e) => LaporanModel.fromJson(e))
        .toList();

    final siswaSudahUpload = laporanList
        .map(
          (e) => {'idDataSiswa': e.idDataSiswa, 'idRuangKelas': e.idRuangKelas},
        )
        .toList();

    List<TeacherDashboardItem> result = [];

    for (var kelas in ruangAktif) {
      final siswaKelas = siswaList
          .where((s) => s['id_ruang_kelas'] == kelas.idRuangKelas)
          .toList();

      final belumUpload = siswaKelas
          .where(
            (s) => !siswaSudahUpload.any(
              (e) =>
                  e['idDataSiswa'] == s['id_data_siswa'] &&
                  e['idRuangKelas'] == s['id_ruang_kelas'],
            ),
          )
          .toList();

      result.add(
        TeacherDashboardItem(kelas: kelas, siswaBelumUpload: belumUpload),
      );
    }

    return result;
  }

  Future<List<KepsekDashboardItem>> getDashboardKepsek(String tahunPelajaran, int semester) async {
    KelasService kelasService = KelasService(_db);
    final today = DateTime.now();
    final todayString =
        "${today.year.toString().padLeft(4, '0')}-"
        "${today.month.toString().padLeft(2, '0')}-"
        "${today.day.toString().padLeft(2, '0')}";

    final ruangRes = await kelasService.getAllTPdS(tahunPelajaran, semester);

    final ruangAktif = ruangRes.where((e) => e.ketAktif == 1).toList();

    if (ruangAktif.isEmpty) return [];

    final ruangIds = ruangAktif.map((e) => e.idRuangKelas).toList();

    final isiRes = await _db
        .from('isiruangkelas')
        .select('id_ruang_kelas, id_data_siswa, datasiswa(nama_lengkap)')
        .inFilter('id_ruang_kelas', ruangIds)
        .filter('id_data_guru', 'is', null);

    final isiResGuru = await _db
        .from('isiruangkelas')
        .select('id_ruang_kelas, id_data_guru, dataguru(nama_lengkap)')
        .inFilter('id_ruang_kelas', ruangIds)
        .filter('id_data_siswa', 'is', null);
    final siswaList = isiRes.where((e) => e['id_data_siswa'] != null).toList();
    final guruList = isiResGuru.where((e) => e['id_data_guru'] != null).toList();

    if (siswaList.isEmpty) return [];
    if (guruList.isEmpty) return [];

    final siswaIds = siswaList.map((e) => e['id_data_siswa']).toSet().toList();

    final laporanRes = await _db
        .from('laporan')
        .select()
        .eq('tanggal', todayString)
        .eq('pelapor', 'Guru')
        .inFilter('id_ruang_kelas', ruangIds)
        .inFilter('id_data_siswa', siswaIds);

    final laporanList = (laporanRes as List)
        .map((e) => LaporanModel.fromJson(e))
        .toList();

    final siswaSudahUpload = laporanList
        .map(
          (e) => {'idDataSiswa': e.idDataSiswa, 'idRuangKelas': e.idRuangKelas},
        )
        .toList();

    List<KepsekDashboardItem> result = [];

    for (var kelas in ruangAktif) {
      final siswaKelas = siswaList
          .where((s) => s['id_ruang_kelas'] == kelas.idRuangKelas)
          .toList();

      final belumUpload = siswaKelas
          .where(
            (s) => !siswaSudahUpload.any(
              (e) =>
                  e['idDataSiswa'] == s['id_data_siswa'] &&
                  e['idRuangKelas'] == s['id_ruang_kelas'],
            ),
          )
          .toList();

      result.add(
        KepsekDashboardItem(kelas: kelas, guru: guruList.first['dataguru']['nama_lengkap'], siswaBelumUpload: belumUpload),
      );
    }

    return result;
  }

  Future<List<ParentDashboardItem>> getDashboardSiswa(String uuidSiswa) async {
    KelasService kelasService = KelasService(_db);
    final today = DateTime.now();
    final todayString =
        "${today.year.toString().padLeft(4, '0')}-"
        "${today.month.toString().padLeft(2, '0')}-"
        "${today.day.toString().padLeft(2, '0')}";

    final ruangRes = await kelasService.getAllMySiswa(uuidSiswa);

    final ruangAktif = ruangRes.where((e) => e.ketAktif == 1).toList();

    if (ruangAktif.isEmpty) return [];

    final ruangIds = ruangAktif.map((e) => e.idRuangKelas).toList();

    final isiRes = await _db
        .from('isiruangkelas')
        .select('id_ruang_kelas, id_data_siswa, datasiswa(nama_lengkap)')
        .inFilter('id_ruang_kelas', ruangIds)
        .eq('id_user_siswa', uuidSiswa);

    final siswaList = isiRes.where((e) => e['id_data_siswa'] != null).toList();

    if (siswaList.isEmpty) return [];

    final siswaIds = siswaList
        .map(
          (e) => {
            'idDataSiswa': e['id_data_siswa'],
            'idRuangKelas': e['id_ruang_kelas'],
          },
        )
        .toSet()
        .toList();
    List<Map<String, dynamic>> laporanRes = [];
    for (var s in siswaIds) {
      final laporan = await _db
          .from('laporan')
          .select()
          .eq('tanggal', todayString)
          .eq('pelapor', 'Guru')
          .eq('id_ruang_kelas', s['idRuangKelas'])
          .eq('id_data_siswa', s['idDataSiswa']);
      laporanRes.addAll(laporan);
    }

    final laporanList = (laporanRes as List)
        .map((e) => LaporanModel.fromJson(e))
        .toList();

    final siswaSudahUpload = laporanList
        .map(
          (e) => {'idDataSiswa': e.idDataSiswa, 'idRuangKelas': e.idRuangKelas},
        )
        .toList();

    List<ParentDashboardItem> result = [];

    for (var kelas in ruangAktif) {
      final siswaKelas = siswaList
          .where((s) => s['id_ruang_kelas'] == kelas.idRuangKelas)
          .toList();

      final belumUpload = siswaKelas
          .where(
            (s) => !siswaSudahUpload.any(
              (e) =>
                  e['idDataSiswa'] == s['id_data_siswa'] &&
                  e['idRuangKelas'] == s['id_ruang_kelas'],
            ),
          )
          .toList();
      final laporanHariIni = laporanList
          .where((l) => l.idRuangKelas == kelas.idRuangKelas)
          .toList();
      result.add(
        ParentDashboardItem(
          kelas: kelas,
          siswaBelumUpload: belumUpload,
          laporanHariIni: laporanHariIni,
        ),
      );
    }

    return result;
  }
}
