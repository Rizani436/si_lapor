/// Model gabungan:
/// - ruangkelas
/// - kelasalquran (JOIN)
class KelasModel {
  // ===== ruangkelas =====
  final int idRuangKelas;
  final int? idKelas;
  final String? kodeKelas;
  final int ketAktif;

  // ===== kelasalquran =====
  final String namaKelas;
  final String tahunPelajaran;
  final int semester;
  final String jenisKelas;

  KelasModel({
    required this.idRuangKelas,
    this.idKelas,
    this.kodeKelas,
    required this.ketAktif,
    required this.namaKelas,
    required this.tahunPelajaran,
    required this.semester,
    required this.jenisKelas,
  });

  bool get isAktif => ketAktif == 1;

  // =====================================================
  // FROM JSON (JOIN ruangkelas + kelasalquran)
  // =====================================================
  factory KelasModel.fromJson(Map<String, dynamic> json) {
    final kelas = json['kelasalquran'] as Map<String, dynamic>?;

    return KelasModel(
      // ruangkelas
      idRuangKelas: (json['id_ruang_kelas'] as num?)?.toInt() ?? 0,
      idKelas: (json['id_kelas'] as num?)?.toInt(),
      kodeKelas: json['kode_kelas'] as String?,
      ketAktif: (json['ket_aktif'] as num?)?.toInt() ?? 1,

      // kelasalquran (JOIN)
      namaKelas: (kelas?['nama_kelas'] as String?) ?? '',
      tahunPelajaran: (kelas?['tahun_pelajaran'] as String?) ?? '',
      semester: (kelas?['semester'] as num?)?.toInt() ?? 1,
      jenisKelas: (kelas?['jenis_kelas'] as String?) ?? '',
    );
  }

  // =====================================================
  // JSON UNTUK INSERT / UPDATE kelasalquran
  // =====================================================
  Map<String, dynamic> toKelasInsertJson() => {
        'nama_kelas': namaKelas,
        'tahun_pelajaran': tahunPelajaran,
        'semester': semester,
        'jenis_kelas': jenisKelas,
      };

  // =====================================================
  // JSON UNTUK INSERT / UPDATE ruangkelas
  // =====================================================
  Map<String, dynamic> toRuangInsertJson({
    required int idKelas,
    required String kodeKelas,
  }) =>
      {
        'id_kelas': idKelas,
        'kode_kelas': kodeKelas,
        'ket_aktif': ketAktif,
      };

  // =====================================================
  // COPY WITH
  // =====================================================
  KelasModel copyWith({
    int? idRuangKelas,
    int? idKelas,
    String? kodeKelas,
    int? ketAktif,
    String? namaKelas,
    String? tahunPelajaran,
    int? semester,
    String? jenisKelas,
  }) {
    return KelasModel(
      idRuangKelas: idRuangKelas ?? this.idRuangKelas,
      idKelas: idKelas ?? this.idKelas,
      kodeKelas: kodeKelas ?? this.kodeKelas,
      ketAktif: ketAktif ?? this.ketAktif,
      namaKelas: namaKelas ?? this.namaKelas,
      tahunPelajaran: tahunPelajaran ?? this.tahunPelajaran,
      semester: semester ?? this.semester,
      jenisKelas: jenisKelas ?? this.jenisKelas,
    );
  }
}
