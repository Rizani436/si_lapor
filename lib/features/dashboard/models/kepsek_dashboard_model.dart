import 'package:si_lapor/features/guru/models/guru_model.dart';

import '../../kelas/models/kelas_model.dart';
import '../../laporan/models/laporan_model.dart';
import '../../kelas/models/isi_ruang_kelas_model.dart';
class KepsekDashboardItem {
  final KelasModel kelas;
  final String guru;
  final List<dynamic> siswaBelumUpload;
  final List<LaporanModel>? laporanHariIni;

  KepsekDashboardItem({
    required this.kelas,
    required this.guru,
    required this.siswaBelumUpload,
    this.laporanHariIni,
  });
}