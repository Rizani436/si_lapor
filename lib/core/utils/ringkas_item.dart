class RingkasItem {
  final int juz;
  final String? surah;
  final String? ayat;
  final String tanggal;
  final String pelapor;
  final String? predikat;

  const RingkasItem({
    required this.juz,
    this.surah,
    this.ayat,
    required this.tanggal,
    required this.pelapor,
    this.predikat,
  });
}
