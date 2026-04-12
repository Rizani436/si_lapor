import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String safeText(dynamic v) {
  if (v == null) return '-';
  final s = v.toString().trim();
  return s.isEmpty ? '-' : s;
}

String ringkas(String s) {
  if (s == '-') return s;
  return s.length > 80 ? '${s.substring(0, 80)}…' : s;
}

String? visibleText(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return s;
}

String buildJsaText({
  required TextEditingController juz,
  required TextEditingController surah,
  required TextEditingController ayat,
}) {
  final j = juz.text.trim();
  final s = surah.text.trim();
  final a = ayat.text.trim();

  final lines = <String>[];
  if (j.isNotEmpty) lines.add('Juz: $j');
  if (s.isNotEmpty) lines.add('Surah: $s');
  if (a.isNotEmpty) lines.add('Ayat: $a');

  return lines.join('\n');
}

String buildJPText({
  required TextEditingController juz,
  required TextEditingController predikat,
}) {
  final j = juz.text.trim();
  final p = predikat.text.trim();

  final lines = <String>[];
  if (j.isNotEmpty) lines.add('Juz: $j');
  if (p.isNotEmpty) lines.add('Predikat: $p');

  return lines.join('\n');
}

String buildJHMText({
  required TextEditingController jilid,
  required TextEditingController halaman,
  required TextEditingController materi,
}) {
  final j = jilid.text.trim();
  final h = halaman.text.trim();
  final m = materi.text.trim();

  final lines = <String>[];
  if (j.isNotEmpty) lines.add('Jilid: $j');
  if (h.isNotEmpty) lines.add('Halaman: $h');
  if (m.isNotEmpty) lines.add('Materi: $m');

  return lines.join('\n');
}


int getAyatMin(String ayat) {
  final nums = RegExp(
    r'\d+',
  ).allMatches(ayat).map((m) => int.parse(m.group(0)!));
  return nums.isEmpty ? 0 : nums.reduce((a, b) => a < b ? a : b);
}

int getAyatMax(String ayat) {
  final nums = RegExp(
    r'\d+',
  ).allMatches(ayat).map((m) => int.parse(m.group(0)!));
  return nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
}

Map<String, dynamic>? extractData(
  AsyncValue<Map<String, dynamic>?> asyncData,
  String program,
) {
  final laporan = asyncData.asData?.value;
  if (laporan == null) return null;

  final String? programText = laporan['$program'];
  if (programText == null) return null;

  final lines = programText.split('\n');

  String juz = '';
  String surah = '';
  String ayat = '';
  String predikat = '';

  for (var line in lines) {
    if (line.startsWith('Juz:')) {
      juz = line.replaceFirst('Juz:', '').trim();
    } else if (line.startsWith('Surah:')) {
      surah = line.replaceFirst('Surah:', '').trim();
    } else if (line.startsWith('Ayat:')) {
      ayat = line.replaceFirst('Ayat:', '').trim();
    }
    else if (line.startsWith('Predikat:')) {
      predikat = line.replaceFirst('Predikat:', '').trim();
    }
  }



  AsyncValue<Map<String, dynamic>?> asyncDataNew = AsyncValue.data({
    'juz': juz,
    'surah': surah,
    'ayat': ayat,
    'predikat': predikat,
    'tanggal': laporan['tanggal'],
  }); 



  return asyncDataNew.when(
    data: (value) {
      if (value == null) return null;
      return value;
    },
    loading: () => null,
    error: (_, __) => null,
  );
}

Map<String, dynamic>? safeFirst(AsyncValue<List<Map<String, dynamic>>> data) {
  final list = data.asData?.value;
  if (list == null || list.isEmpty) return null;
  return list.first;
}
