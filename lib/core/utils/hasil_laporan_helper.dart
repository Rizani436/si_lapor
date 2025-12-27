import '../utils/juz_map.dart';
class TasmiPoint {
  final int juz;
  final String surahKey; 
  final int ayat; 
  const TasmiPoint({
    required this.juz,
    required this.surahKey,
    required this.ayat,
  });
}

int? parseAyatMax(String raw) {
  final s = raw.trim();

  final one = RegExp(r'^\d+$').firstMatch(s);
  if (one != null) return int.tryParse(s);

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

bool isJuzCompleted(int juz, JuzPosition furthest) {
  final segs = juzMap[juz];
  if (segs == null || segs.isEmpty) return false;

  final lastIndex = segs.length - 1;
  final lastSeg = segs[lastIndex];

  return furthest.segIndex == lastIndex && furthest.ayat >= lastSeg.endAyat;
}

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
  required List<Map<String, dynamic>> laporan,
  required String jenisKelas, 
  required Map<int, String> namaById,
}) {
  final wajib = (jenisKelas.toLowerCase() == 'Tahfiz') ? 3 : 2;

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

  result.sort((a, b) {
    if (a.memenuhi != b.memenuhi) return a.memenuhi ? 1 : -1;

    final an = (a.nama ?? '').toLowerCase();
    final bn = (b.nama ?? '').toLowerCase();
    if (an.isNotEmpty && bn.isNotEmpty) return an.compareTo(bn);

    return a.idDataSiswa.compareTo(b.idDataSiswa);
  });

  return result;
}