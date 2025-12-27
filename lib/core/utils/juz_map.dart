
class JuzSegment {
  final String surahKey;
  final int startAyat;
  final int endAyat;
  const JuzSegment(this.surahKey, this.startAyat, this.endAyat);
}

String normSurah(String s) {
  return s
      .toLowerCase()
      .replaceAll("'", '')
      .replaceAll('’', '')
      .replaceAll('-', '')
      .replaceAll(' ', '');
}

final Map<int, List<JuzSegment>> juzMap = {
  1: [
    JuzSegment(normSurah('Al-Fatihah'), 1, 7),
    JuzSegment(normSurah('Al-Baqarah'), 1, 141),
  ],
  2: [
    JuzSegment(normSurah('Al-Baqarah'), 141, 252),
  ],
  3: [
    JuzSegment(normSurah('Al-Baqarah'), 253, 286),
    JuzSegment(normSurah('Ali Imran'), 1, 91),
  ],
  4: [
    JuzSegment(normSurah('Ali Imran'), 92, 200),
    JuzSegment(normSurah('An-Nisa'), 1, 23),
  ],
  5: [
    JuzSegment(normSurah('An-Nisa'), 24, 147),
  ],
  6: [
    JuzSegment(normSurah('An-Nisa'), 148, 176),
    JuzSegment(normSurah("Al-Ma'idah"), 1, 82),
  ],
  7: [
    JuzSegment(normSurah("Al-Ma'idah"), 83, 120),
    JuzSegment(normSurah("Al-An'am"), 1, 110),
  ],
  8: [
    JuzSegment(normSurah("Al-An'am"), 111, 165),
    JuzSegment(normSurah("Al-A'raf"), 1, 87),
  ],
  9: [
    JuzSegment(normSurah("Al-A'raf"), 88, 206),
    JuzSegment(normSurah('Al-Anfal'), 1, 40),
  ],
  10: [
    JuzSegment(normSurah('Al-Anfal'), 41, 75),
    JuzSegment(normSurah('At-Taubah'), 1, 93),
  ],
  11: [
    JuzSegment(normSurah('At-Taubah'), 94, 129),
    JuzSegment(normSurah('Yunus'), 1, 109),
    JuzSegment(normSurah('Hud'), 1, 5),
  ],
  12: [
    JuzSegment(normSurah('Hud'), 6, 123),
    JuzSegment(normSurah('Yusuf'), 1, 52),
  ],
  13: [
    JuzSegment(normSurah('Yusuf'), 53, 111),
    JuzSegment(normSurah("Ar-Ra'd"), 1, 43),
    JuzSegment(normSurah('Ibrahim'), 1, 52),
  ],
  14: [
    JuzSegment(normSurah('Al-Hijr'), 1, 99),
    JuzSegment(normSurah('An-Nahl'), 1, 128),
  ],
  15: [
    JuzSegment(normSurah("Al-Isra'"), 1, 111),
    JuzSegment(normSurah('Al-Kahf'), 1, 74),
  ],
  16: [
    JuzSegment(normSurah('Al-Kahf'), 75, 110),
    JuzSegment(normSurah('Maryam'), 1, 98),
    JuzSegment(normSurah('Ta-Ha'), 1, 135),
  ],
  17: [
    JuzSegment(normSurah('Al-Anbiya'), 1, 112),
    JuzSegment(normSurah('Al-Hajj'), 1, 78),
  ],
  18: [
    JuzSegment(normSurah("Al-Mu'minun"), 1, 118),
    JuzSegment(normSurah('An-Nur'), 1, 64),
    JuzSegment(normSurah('Al-Furqan'), 1, 20),
  ],
  19: [
    JuzSegment(normSurah('Al-Furqan'), 21, 77),
    JuzSegment(normSurah("Asy-Syu'ara'"), 1, 227),
    JuzSegment(normSurah('An-Naml'), 1, 55),
  ],
  20: [
    JuzSegment(normSurah('An-Naml'), 56, 93),
    JuzSegment(normSurah('Al-Qasas'), 1, 88),
    JuzSegment(normSurah("Al-'Ankabut"), 1, 45),
  ],
  21: [
    JuzSegment(normSurah("Al-'Ankabut"), 46, 69),
    JuzSegment(normSurah('Ar-Rum'), 1, 60),
    JuzSegment(normSurah('Luqman'), 1, 34),
    JuzSegment(normSurah('As-Sajdah'), 1, 30),
    JuzSegment(normSurah('Al-Ahzab'), 1, 30),
  ],
  22: [
    JuzSegment(normSurah('Al-Ahzab'), 31, 73),
    JuzSegment(normSurah("Saba'"), 1, 54),
    JuzSegment(normSurah('Fatir'), 1, 45),
    JuzSegment(normSurah('Ya-Sin'), 1, 27),
  ],
  23: [
    JuzSegment(normSurah('Ya-Sin'), 28, 83),
    JuzSegment(normSurah('As-Saffat'), 1, 82),
    JuzSegment(normSurah('Sad'), 1, 88),
    JuzSegment(normSurah('Az-Zumar'), 1, 31),
  ],
  24: [
    JuzSegment(normSurah('Az-Zumar'), 32, 75),
    JuzSegment(normSurah('Al-Ghafir'), 1, 85),
    JuzSegment(normSurah('Fussilat'), 1, 46),
  ],
  25: [
    JuzSegment(normSurah('Fussilat'), 47, 54),
    JuzSegment(normSurah('Asy-Syura'), 1, 53),
    JuzSegment(normSurah('Az-Zukhruf'), 1, 89),
    JuzSegment(normSurah('Ad-Dukhan'), 1, 59),
    JuzSegment(normSurah('Al-Jasiyah'), 1, 32),
  ],
  26: [
    JuzSegment(normSurah('Al-Jasiyah'), 33, 37),
    JuzSegment(normSurah('Al-Ahqaf'), 1, 35),
    JuzSegment(normSurah('Muhammad'), 1, 38),
    JuzSegment(normSurah('Al-Fath'), 1, 29),
    JuzSegment(normSurah('Al-Hujurat'), 1, 18),
    JuzSegment(normSurah('Qaf'), 1, 45),
    JuzSegment(normSurah('Az-Zariyat'), 1, 30),
  ],
  27: [
    JuzSegment(normSurah('Az-Zariyat'), 31, 60),
    JuzSegment(normSurah('At-Tur'), 1, 49),
    JuzSegment(normSurah('An-Najm'), 1, 62),
    JuzSegment(normSurah('Al-Qamar'), 1, 55),
    JuzSegment(normSurah('Ar-Rahman'), 1, 78),
    JuzSegment(normSurah("Al-Waqi'ah"), 1, 96),
    JuzSegment(normSurah('Al-Hadid'), 1, 29),
  ],
  28: [
    JuzSegment(normSurah('Al-Mujadilah'), 1, 22),
    JuzSegment(normSurah('Al-Hasyr'), 1, 24),
    JuzSegment(normSurah('Al-Mumtahanah'), 1, 13),
    JuzSegment(normSurah('As-Saff'), 1, 14),
    JuzSegment(normSurah("Al-Jumu'ah"), 1, 11),
    JuzSegment(normSurah('Al-Munafiqun'), 1, 11),
    JuzSegment(normSurah('At-Taghabun'), 1, 18),
    JuzSegment(normSurah('At-Talaq'), 1, 12),
    JuzSegment(normSurah('At-Tahrim'), 1, 12),
  ],
  29: [
    JuzSegment(normSurah('Al-Mulk'), 1, 30),
    JuzSegment(normSurah('Al-Qalam'), 1, 52),
    JuzSegment(normSurah('Al-Haqqah'), 1, 52),
    JuzSegment(normSurah("Al-Ma'arij"), 1, 44),
    JuzSegment(normSurah('Nuh'), 1, 28),
    JuzSegment(normSurah('Al-Jinn'), 1, 28),
    JuzSegment(normSurah('Al-Muzzammil'), 1, 20),
    JuzSegment(normSurah('Al-Muddassir'), 1, 56),
    JuzSegment(normSurah('Al-Qiyamah'), 1, 40),
    JuzSegment(normSurah('Al-Insan'), 1, 31),
    JuzSegment(normSurah('Al-Mursalat'), 1, 50),
  ],
  30: [
    JuzSegment(normSurah("An-Naba'"), 1, 40),
    JuzSegment(normSurah("An-Nazi'at"), 1, 46),
    JuzSegment(normSurah("'Abasa"), 1, 42),
    JuzSegment(normSurah('At-Takwir'), 1, 29),
    JuzSegment(normSurah('Al-Infitar'), 1, 19),
    JuzSegment(normSurah('Al-Muthaffifin'), 1, 36),
    JuzSegment(normSurah('Al-Insyiqaq'), 1, 25),
    JuzSegment(normSurah('Al-Buruj'), 1, 22),
    JuzSegment(normSurah('At-Tariq'), 1, 17),
    JuzSegment(normSurah("Al-A'la"), 1, 19),
    JuzSegment(normSurah('Al-Ghasyiyah'), 1, 26),
    JuzSegment(normSurah('Al-Fajr'), 1, 30),
    JuzSegment(normSurah('Al-Balad'), 1, 20),
    JuzSegment(normSurah('Asy-Syams'), 1, 15),
    JuzSegment(normSurah('Al-Lail'), 1, 21),
    JuzSegment(normSurah('Ad-Duha'), 1, 11),
    JuzSegment(normSurah('Al-Insyirah'), 1, 8),
    JuzSegment(normSurah('At-Tin'), 1, 8),
    JuzSegment(normSurah("Al-'Alaq"), 1, 19),
    JuzSegment(normSurah('Al-Qadr'), 1, 5),
    JuzSegment(normSurah('Al-Bayyinah'), 1, 8),
    JuzSegment(normSurah('Az-Zalzalah'), 1, 8),
    JuzSegment(normSurah("Al-'Adiyat"), 1, 11),
    JuzSegment(normSurah("Al-Qari'ah"), 1, 11),
    JuzSegment(normSurah('At-Takasur'), 1, 8),
    JuzSegment(normSurah("Al-'Asr"), 1, 3),
    JuzSegment(normSurah('Al-Humazah'), 1, 9),
    JuzSegment(normSurah('Al-Fil'), 1, 5),
    JuzSegment(normSurah('Quraisy'), 1, 4),
    JuzSegment(normSurah("Al-Ma'un"), 1, 7),
    JuzSegment(normSurah('Al-Kausar'), 1, 3),
    JuzSegment(normSurah('Al-Kafirun'), 1, 6),
    JuzSegment(normSurah('An-Nasr'), 1, 3),
    JuzSegment(normSurah('Al-Lahab'), 1, 5),
    JuzSegment(normSurah('Al-Ikhlas'), 1, 4),
    JuzSegment(normSurah('Al-Falaq'), 1, 5),
    JuzSegment(normSurah('An-Nas'), 1, 6),
  ],
};
