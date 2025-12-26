import 'package:flutter/material.dart';
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
