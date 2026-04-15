import '../../kelas/models/kelas_model.dart';
import '../../laporan/models/laporan_model.dart';
import '../../kelas/models/isi_ruang_kelas_model.dart';
class ParentDashboardItem {
  final KelasModel kelas;
  final List<dynamic> siswaBelumUpload;
  final List<LaporanModel>? laporanHariIni;

  ParentDashboardItem({
    required this.kelas,
    required this.siswaBelumUpload,
    this.laporanHariIni,
  });
}