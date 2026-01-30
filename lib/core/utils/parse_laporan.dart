import 'ringkas_item.dart';
RingkasItem? parseLaporan(String? raw, String? tanggal, String? pelapor) {
  if (raw == null || raw.trim().isEmpty) return null;

  final juzMatch =
      RegExp(r'juz\s*:\s*(\d+)', caseSensitive: false).firstMatch(raw);

  final surahMatch =
      RegExp(r'surah\s*:\s*([^\n,]+)', caseSensitive: false).firstMatch(raw);

  final ayatMatch =
      RegExp(r'ayat\s*:\s*([0-9\-]+)', caseSensitive: false).firstMatch(raw);

  if (juzMatch == null || surahMatch == null || ayatMatch == null) {
    return null;
  }

  return RingkasItem(
    juz: int.parse(juzMatch.group(1)!),
    surah: surahMatch.group(1)!.trim(),
    ayat: ayatMatch.group(1)!.trim(),
    tanggal: tanggal ?? '',
    pelapor: pelapor ?? '',
  );
}
