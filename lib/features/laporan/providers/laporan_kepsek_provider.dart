import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/laporan_kepsek_service.dart';
import '../../../core/utils/juz_map.dart';

// ================== Providers ==================
final laporanKepsekServiceProvider = Provider<LaporanKepsekService>((ref) {
  return LaporanKepsekService(Supabase.instance.client);
});

final laporanKepsekProvider =
    NotifierProvider<LaporanKepsekNotifier, LaporanKepsekState>(
  LaporanKepsekNotifier.new,
);

// ================== Parsing ==================
class TasmiPoint {
  final int juz;
  final String surahKey; // normalized
  final int ayat; // ayat max (kalau 1-7 => 7)
  const TasmiPoint({
    required this.juz,
    required this.surahKey,
    required this.ayat,
  });
}

/// ambil angka terbesar dari:
/// "7" => 7
/// "1-7" => 7
int? parseAyatMax(String raw) {
  final s = raw.trim();

  // "7"
  final one = RegExp(r'^\d+$').firstMatch(s);
  if (one != null) return int.tryParse(s);

  // "1-7"
  final m = RegExp(r'^(\d+)\s*-\s*(\d+)$').firstMatch(s);
  if (m != null) {
    final a1 = int.tryParse(m.group(1)!);
    final a2 = int.tryParse(m.group(2)!);
    if (a1 == null || a2 == null) return null;
    return a1 > a2 ? a1 : a2;
  }

  return null;
}

TasmiPoint? parseTasmiPoint(String? tasmi) {
  if (tasmi == null) return null;

  final mJuz =
      RegExp(r'juz\s*:\s*(\d+)', caseSensitive: false).firstMatch(tasmi);
  final mSurah = RegExp(
    r'surah\s*:\s*([^\n\r]+?)(?=\s+ayat\s*:|$)',
    caseSensitive: false,
  ).firstMatch(tasmi);

  // ambil payload ayat boleh "7" atau "1-7"
  final mAyat = RegExp(
    r'ayat\s*:\s*([0-9\-\s]+)',
    caseSensitive: false,
  ).firstMatch(tasmi);

  if (mJuz == null || mSurah == null || mAyat == null) return null;

  final juz = int.tryParse(mJuz.group(1)!);
  if (juz == null) return null;

  final surahRaw = mSurah.group(1)!.trim();
  final surahKey = normSurah(surahRaw);

  final ayatRaw = mAyat.group(1)!.trim();
  final ayat = parseAyatMax(ayatRaw);
  if (ayat == null) return null;

  return TasmiPoint(juz: juz, surahKey: surahKey, ayat: ayat);
}

class JuzPosition {
  final int segIndex;
  final int ayat;
  const JuzPosition(this.segIndex, this.ayat);
}

JuzPosition? toJuzPosition(TasmiPoint p) {
  final segs = juzMap[p.juz];
  if (segs == null) return null;

  for (int i = 0; i < segs.length; i++) {
    final seg = segs[i];
    if (seg.surahKey == p.surahKey) {
      final a = p.ayat.clamp(seg.startAyat, seg.endAyat);
      return JuzPosition(i, a);
    }
  }
  return null;
}

int comparePos(JuzPosition a, JuzPosition b) {
  if (a.segIndex != b.segIndex) return a.segIndex.compareTo(b.segIndex);
  return a.ayat.compareTo(b.ayat);
}

/// juz selesai jika sudah mencapai segmen terakhir dan ayat >= endAyat segmen terakhir
bool isJuzCompleted(int juz, JuzPosition furthest) {
  final segs = juzMap[juz];
  if (segs == null || segs.isEmpty) return false;

  final lastIndex = segs.length - 1;
  final lastSeg = segs[lastIndex];

  return furthest.segIndex == lastIndex && furthest.ayat >= lastSeg.endAyat;
}

// ================== Summary model ==================
class TasmiSummary {
  final int idDataSiswa;
  final List<int> juzSelesai;
  final bool memenuhi;
  final String? nama;

  const TasmiSummary({
    required this.idDataSiswa,
    required this.juzSelesai,
    required this.memenuhi,
    required this.nama,
  });
}

List<TasmiSummary> buildSummaryCompletedJuz({
  required List<Map<String, dynamic>> laporan, // select: id_data_siswa, tasmi
  required String jenisKelas, // reguler/tahfiz
  required Map<int, String> namaById,
}) {
  final wajib = (jenisKelas.toLowerCase() == 'Tahfiz') ? 3 : 2;

  // siswa -> juz -> posisi terjauh
  final Map<int, Map<int, JuzPosition>> furthestBySiswa = {};

  for (final row in laporan) {
    final id = row['id_data_siswa'];
    if (id is! int) continue;

    final p = parseTasmiPoint(row['tasmi'] as String?);
    if (p == null) continue;

    final pos = toJuzPosition(p);
    if (pos == null) continue;

    final juzMapSiswa = (furthestBySiswa[id] ??= {});
    final prev = juzMapSiswa[p.juz];

    if (prev == null || comparePos(prev, pos) < 0) {
      juzMapSiswa[p.juz] = pos;
    }
  }

  final result = <TasmiSummary>[];

  furthestBySiswa.forEach((idSiswa, furthestByJuz) {
    final selesai = <int>[];

    furthestByJuz.forEach((juz, pos) {
      if (isJuzCompleted(juz, pos)) selesai.add(juz);
    });

    selesai.sort();

    result.add(TasmiSummary(
      idDataSiswa: idSiswa,
      juzSelesai: selesai,
      memenuhi: selesai.length >= wajib,
      nama: namaById[idSiswa],
    ));
  });

  // sort: belum memenuhi dulu, lalu nama
  result.sort((a, b) {
    if (a.memenuhi != b.memenuhi) return a.memenuhi ? 1 : -1;

    final an = (a.nama ?? '').toLowerCase();
    final bn = (b.nama ?? '').toLowerCase();
    if (an.isNotEmpty && bn.isNotEmpty) return an.compareTo(bn);

    return a.idDataSiswa.compareTo(b.idDataSiswa);
  });

  return result;
}

// ================== State ==================
class LaporanKepsekState {
  final bool loading;
  final String? error;

  final List<TasmiSummary> summaryReguler;
  final List<TasmiSummary> summaryTahfiz;

  const LaporanKepsekState({
    required this.loading,
    required this.error,
    required this.summaryReguler,
    required this.summaryTahfiz,
  });

  factory LaporanKepsekState.initial() => const LaporanKepsekState(
        loading: false,
        error: null,
        summaryReguler: [],
        summaryTahfiz: [],
      );

  LaporanKepsekState copyWith({
    bool? loading,
    String? error,
    List<TasmiSummary>? summaryReguler,
    List<TasmiSummary>? summaryTahfiz,
  }) {
    return LaporanKepsekState(
      loading: loading ?? this.loading,
      error: error,
      summaryReguler: summaryReguler ?? this.summaryReguler,
      summaryTahfiz: summaryTahfiz ?? this.summaryTahfiz,
    );
  }

  int get memenuhiReguler => summaryReguler.where((e) => e.memenuhi).length;
  int get belumReguler => summaryReguler.where((e) => !e.memenuhi).length;

  int get memenuhiTahfiz => summaryTahfiz.where((e) => e.memenuhi).length;
  int get belumTahfiz => summaryTahfiz.where((e) => !e.memenuhi).length;
}

// ================== Notifier ==================
class LaporanKepsekNotifier extends Notifier<LaporanKepsekState> {
  @override
  LaporanKepsekState build() => LaporanKepsekState.initial();

  void reset() => state = LaporanKepsekState.initial();

  Future<void> fetchSummary({
    required String tahunPelajaran,
    required String semester,
  }) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final service = ref.read(laporanKepsekServiceProvider);

      final laporanReg = await service.fetchLaporanTasmiByJenisKelas(
        tahunPelajaran: tahunPelajaran,
        semester: semester,
        jenisKelas: 'Reguler',
      );

      final laporanTah = await service.fetchLaporanTasmiByJenisKelas(
        tahunPelajaran: tahunPelajaran,
        semester: semester,
        jenisKelas: 'Tahfiz',
      );

      // kumpulkan id siswa unik
      final ids = <int>{};
      for (final r in laporanReg) {
        final id = r['id_data_siswa'];
        if (id is int) ids.add(id);
      }
      for (final r in laporanTah) {
        final id = r['id_data_siswa'];
        if (id is int) ids.add(id);
      }

      // join nama siswa (opsional)
      final namaMap = await service.fetchNamaSiswaMap(ids.toList());

      final summaryReg = buildSummaryCompletedJuz(
        laporan: laporanReg,
        jenisKelas: 'Reguler',
        namaById: namaMap,
      );

      final summaryTah = buildSummaryCompletedJuz(
        laporan: laporanTah,
        jenisKelas: 'Tahfiz',
        namaById: namaMap,
      );

      state = state.copyWith(
        loading: false,
        error: null,
        summaryReguler: summaryReg,
        summaryTahfiz: summaryTah,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }
}
