import 'dart:ffi';

import '../utils/juz_map.dart';

class TasmiPoint {
  final int juz;
  final String predikat;
  const TasmiPoint({required this.juz, required this.predikat});
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

  final mJuz = RegExp(
    r'juz\s*:\s*(\d+)',
    caseSensitive: false,
  ).firstMatch(tasmi);
  if (mJuz == null) return null;

  final mPredikat = RegExp(
    r'predikat\s*:\s*([^\n\r]+?)(?=\s+ayat\s*:|$)',
    caseSensitive: false,
  ).firstMatch(tasmi);

  final juz = int.tryParse(mJuz!.group(1)!);
  if (juz == null) return null;
  final predikat = mPredikat != null ? mPredikat.group(1)!.trim() : '';
  return TasmiPoint(juz: juz, predikat: predikat);
}

class TasmiSummary {
  final int idDataSiswa;
  final List<int> juzSelesai;
  final bool memenuhi;
  final String? nama;
  final int jumlahJuz;

  const TasmiSummary({
    required this.idDataSiswa,
    required this.juzSelesai,
    required this.memenuhi,
    required this.nama,
    required this.jumlahJuz,
  });
}

List<TasmiSummary> buildSummaryCompletedJuz({
  required List<Map<String, dynamic>> laporan,
  required Map<int, String> namaById,
}) {
  final Map<int, Map<int, String>> furthestBySiswa = {};

  for (final row in laporan) {
    final id = row['id_data_siswa'];
    if (id is! int) continue;

    final p = parseTasmiPoint(row['tasmi'] as String?);
    if (p == null) continue;

    final juzMapSiswa = (furthestBySiswa[id] ??= {});
    final prev = juzMapSiswa[p.juz];

    furthestBySiswa[id]![p.juz] = p.predikat.isNotEmpty
        ? p.predikat
        : (prev ?? '');
  }

  final result = <TasmiSummary>[];

  furthestBySiswa.forEach((idSiswa, furthestByJuz) {
    final nama = namaById.map((key, value) {
      final parts = value.split('||');
      if (parts.length == 2) {
        return MapEntry(key, parts[0]);
      }
      return MapEntry(key, value);
    });
    final wajib = namaById.map((key, value) {
      final parts = value.split('||');
      if (parts.length == 2) {
        return MapEntry(key, int.tryParse(parts[1]) ?? 0);
      }
      return MapEntry(key, 0);
    });
    final sortedEntries = furthestByJuz.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final dahSelesai = <int>[];
    final dahSelesaiPredikat = <String>[];
    sortedEntries.map((e) => dahSelesai.add(e.key)).toList();
    sortedEntries.map((e) => dahSelesaiPredikat.add(e.value)).toList();
    final selesai = <int>[];
    if (wajib[idSiswa] != null && wajib[idSiswa]! < dahSelesai.length) {
      selesai.addAll(dahSelesai.sublist(0, wajib[idSiswa]!));
    } else {
      selesai.addAll(dahSelesai);
    }
    result.add(
      TasmiSummary(
        idDataSiswa: idSiswa,
        juzSelesai: selesai,
        memenuhi: selesai.length >= wajib[idSiswa]!,
        nama: nama[idSiswa],
        jumlahJuz: wajib[idSiswa]!,
      ),
    );
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
