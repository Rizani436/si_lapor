import 'package:collection/collection.dart'; // optional (kalau kamu tidak pakai, bisa hapus)
import 'juz_map.dart'; // arahkan ke path juz_map.dart kamu

String displaySurahFromKey(String key) {
  // key = normalized (tanpa spasi/tanda baca)
  // supaya tampil rapi, kita cari nama asli dari mapping (pakai label map)
  return _surahLabelByKey[key] ?? key;
}

final Map<String, String> _surahLabelByKey = {
  // label yang sering muncul (optional), biar tampil bagus
  normSurah('Al-Fatihah'): 'Al-Fatihah',
  normSurah('Al-Baqarah'): 'Al-Baqarah',
  normSurah('Ali Imran'): 'Ali Imran',
  normSurah('An-Nisa'): 'An-Nisa',
  normSurah("Al-Ma'idah"): "Al-Ma'idah",
  normSurah("Al-An'am"): "Al-An'am",
  normSurah("Al-A'raf"): "Al-A'raf",
  normSurah('Al-Anfal'): 'Al-Anfal',
  normSurah('At-Taubah'): 'At-Taubah',
  normSurah('Yunus'): 'Yunus',
  normSurah('Hud'): 'Hud',
  normSurah('Yusuf'): 'Yusuf',
  normSurah("Ar-Ra'd"): "Ar-Ra'd",
  normSurah('Ibrahim'): 'Ibrahim',
  normSurah('Al-Hijr'): 'Al-Hijr',
  normSurah('An-Nahl'): 'An-Nahl',
  normSurah("Al-Isra'"): "Al-Isra'",
  normSurah('Al-Kahfi'): 'Al-Kahfi',
  normSurah('Maryam'): 'Maryam',
  normSurah('Ta Ha'): 'Ta Ha',
  normSurah('Al-Anbiya'): 'Al-Anbiya',
  normSurah('Al-Hajj'): 'Al-Hajj',
  normSurah("Al-Mu'minun"): "Al-Mu'minun",
  normSurah('An-Nur'): 'An-Nur',
  normSurah('Al-Furqan'): 'Al-Furqan',
  normSurah("Asy-Syu'ara'"): "Asy-Syu'ara'",
  normSurah('An-Naml'): 'An-Naml',
  normSurah('Al-Qasas'): 'Al-Qasas',
  normSurah("Al-'Ankabut"): "Al-'Ankabut",
  normSurah('Ar-Rum'): 'Ar-Rum',
  normSurah('Luqman'): 'Luqman',
  normSurah('As-Sajdah'): 'As-Sajdah',
  normSurah('Al-Ahzab'): 'Al-Ahzab',
  normSurah("Saba'"): "Saba'",
  normSurah('Fatir'): 'Fatir',
  normSurah('Ya Sin'): 'Ya Sin',
  normSurah('As-Saffat'): 'As-Saffat',
  normSurah('Sad'): 'Sad',
  normSurah('Az-Zumar'): 'Az-Zumar',
  normSurah('Al-Ghafir'): 'Al-Ghafir',
  normSurah('Al-Fussilat'): 'Al-Fussilat',
  normSurah('Asy-Syura'): 'Asy-Syura',
  normSurah('Az-Zukhruf'): 'Az-Zukhruf',
  normSurah('Ad-Dukhan'): 'Ad-Dukhan',
  normSurah('Al-Jatsiyah'): 'Al-Jatsiyah',
  normSurah('Al-Ahqaf'): 'Al-Ahqaf',
  normSurah('Muhammad'): 'Muhammad',
  normSurah('Al-Fath'): 'Al-Fath',
  normSurah('Al-Hujurat'): 'Al-Hujurat',
  normSurah('Qaf'): 'Qaf',
  normSurah('Az-Zariyat'): 'Az-Zariyat',
  normSurah('At-Tur'): 'At-Tur',
  normSurah('An-Najm'): 'An-Najm',
  normSurah('Al-Qamar'): 'Al-Qamar',
  normSurah('Ar-Rahman'): 'Ar-Rahman',
  normSurah("Al-Waqi'ah"): "Al-Waqi'ah",
  normSurah('Al-Hadid'): 'Al-Hadid',
  normSurah('Al-Mujadilah'): 'Al-Mujadilah',
  normSurah('Al-Hasyr'): 'Al-Hasyr',
  normSurah('Al-Mumtahanah'): 'Al-Mumtahanah',
  normSurah('As-Saff'): 'As-Saff',
  normSurah("Al-Jumu'ah"): "Al-Jumu'ah",
  normSurah('Al-Munafiqun'): 'Al-Munafiqun',
  normSurah('At-Tagabun'): 'At-Tagabun',
  normSurah('At-Talaq'): 'At-Talaq',
  normSurah('At-Tahrim'): 'At-Tahrim',
  normSurah('Al-Mulk'): 'Al-Mulk',
  normSurah('Al-Qalam'): 'Al-Qalam',
  normSurah('Al-Haqqah'): 'Al-Haqqah',
  normSurah("Al-Ma'arij"): "Al-Ma'arij",
  normSurah('Nuh'): 'Nuh',
  normSurah('Al-Jinn'): 'Al-Jinn',
  normSurah('Al-Muzzammil'): 'Al-Muzzammil',
  normSurah('Al-Muddassir'): 'Al-Muddassir',
  normSurah('Al-Qiyamah'): 'Al-Qiyamah',
  normSurah('Al-Insan'): 'Al-Insan',
  normSurah('Al-Mursalat'): 'Al-Mursalat',
  normSurah("An-Naba'"): "An-Naba'",
  normSurah("An-Nazi'at"): "An-Nazi'at",
  normSurah("'Abasa"): "'Abasa",
  normSurah('At-Takwir'): 'At-Takwir',
  normSurah('Al-Infitar'): 'Al-Infitar',
  normSurah('Al-Muthaffifin'): 'Al-Muthaffifin',
  normSurah('Al-Insyiqaq'): 'Al-Insyiqaq',
  normSurah('Al-Buruj'): 'Al-Buruj',
  normSurah('At-Tariq'): 'At-Tariq',
  normSurah("Al-A'la"): "Al-A'la",
  normSurah('Al-Gasyiyah'): 'Al-Gasyiyah',
  normSurah('Al-Fajr'): 'Al-Fajr',
  normSurah('Al-Balad'): 'Al-Balad',
  normSurah('Asy-Syams'): 'Asy-Syams',
  normSurah('Al-Lail'): 'Al-Lail',
  normSurah('Ad-Duha'): 'Ad-Duha',
  normSurah('Al-Insyirah'): 'Al-Insyirah',
  normSurah('At-Tin'): 'At-Tin',
  normSurah("Al-'Alaq"): "Al-'Alaq",
  normSurah('Al-Qadr'): 'Al-Qadr',
  normSurah('Al-Bayyinah'): 'Al-Bayyinah',
  normSurah('Az-Zalzalah'): 'Az-Zalzalah',
  normSurah("Al-'Adiyat"): "Al-'Adiyat",
  normSurah("Al-Qari'ah"): "Al-Qari'ah",
  normSurah('At-Takasur'): 'At-Takasur',
  normSurah("Al-'Asr"): "Al-'Asr",
  normSurah('Al-Humazah'): 'Al-Humazah',
  normSurah('Al-Fil'): 'Al-Fil',
  normSurah('Quraisy'): 'Quraisy',
  normSurah("Al-Ma'un"): "Al-Ma'un",
  normSurah('Al-Kausar'): 'Al-Kausar',
  normSurah('Al-Kafirun'): 'Al-Kafirun',
  normSurah('An-Nasr'): 'An-Nasr',
  normSurah('Al-Lahab'): 'Al-Lahab',
  normSurah('Al-Ikhlas'): 'Al-Ikhlas',
  normSurah('Al-Falaq'): 'Al-Falaq',
  normSurah('An-Nas'): 'An-Nas',
};

List<int> allJuz() => List.generate(30, (i) => i + 1);

List<String> surahKeysForJuz(int juz) {
  final segs = juzMap[juz] ?? const [];
  // unik + urutan sesuai segs
  final keys = <String>[];
  for (final s in segs) {
    if (!keys.contains(s.surahKey)) keys.add(s.surahKey);
  }
  return keys;
}

({int start, int end}) ayatRangeFor(int juz, String surahKey) {
  final segs = juzMap[juz] ?? const [];
  for (final seg in segs) {
    if (seg.surahKey == surahKey) {
      return (start: seg.startAyat, end: seg.endAyat);
    }
  }
  // fallback
  return (start: 1, end: 1);
}

List<int> ayatOptions(int juz, String surahKey) {
  final r = ayatRangeFor(juz, surahKey);
  // kalau range besar, ini bisa panjang. Boleh diubah jadi input number.
  return List.generate((r.end - r.start) + 1, (i) => r.start + i);
}
