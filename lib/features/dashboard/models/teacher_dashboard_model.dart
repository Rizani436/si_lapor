import '../../kelas/models/kelas_model.dart';
import '../../laporan/models/laporan_model.dart';
import '../../kelas/models/isi_ruang_kelas_model.dart';
class TeacherDashboardItem {
  final KelasModel kelas;
  final List<dynamic> siswaBelumUpload;

  TeacherDashboardItem({
    required this.kelas,
    required this.siswaBelumUpload,
  });
}