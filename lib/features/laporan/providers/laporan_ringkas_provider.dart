import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'laporan_siswa_provider.dart';
import '../../../core/utils/ringkas_item.dart';
import '../../../core/utils/laporan_ringkas_helper.dart';

final laporanRingkasDetailProvider = FutureProvider.family<
    Map<String, List<RingkasItem>>,
    ({int idSiswa, int idKelas, DateTime start, DateTime end})>(
  (ref, q) async {
    final service = ref.read(laporanServiceProvider);

    final laporan = await service.getLaporanRange(
      idSiswa: q.idSiswa,
      idKelas: q.idKelas,
      start: q.start,
      end: q.end,
    );

    return buildRingkasanDetail(laporan);
  },
);

final laporan10HariTerakhir = FutureProvider.family<
    Map<String, List<RingkasItem>>,
    ({int idSiswa, int idKelas, String program})>(
  (ref, q) async {
    final service = ref.read(laporanServiceProvider);

    final laporan = await service.getLaporan10(
      idSiswa: q.idSiswa,
      idKelas: q.idKelas,
      program: q.program,
      
    );

    return buildRingkasanDetail(laporan);
  },
);


