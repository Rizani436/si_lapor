class SiswaModel {
  final int idDataSiswa;
  final String namaLengkap;
  final String nis;
  final String alamat;
  final String jenisKelamin;
  final String tahunMasuk; 
  final DateTime tanggalLahir;
  final int ketAktif;      

  SiswaModel({
    required this.idDataSiswa,
    required this.namaLengkap,
    required this.nis,
    required this.alamat,
    required this.jenisKelamin,
    required this.tahunMasuk,
    required this.tanggalLahir,
    required this.ketAktif,
  });

  bool get isAktif => ketAktif == 1;

  factory SiswaModel.fromJson(Map<String, dynamic> json) {
    return SiswaModel(
      idDataSiswa: (json['id_data_siswa'] as num).toInt(),
      namaLengkap: (json['nama_lengkap'] ?? '') as String,
      nis: (json['nis'] ?? '') as String,
      alamat: (json['alamat'] ?? '') as String,
      jenisKelamin: (json['jenis_kelamin'] ?? '') as String,
      tahunMasuk: (json['tahun_masuk'] ?? '').toString(),
      tanggalLahir: DateTime.tryParse('${json['tanggal_lahir']}') ?? DateTime(2000, 1, 1),
      ketAktif: (json['ket_aktif'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'nama_lengkap': namaLengkap,
      'nis': nis,
      'alamat': alamat,
      'jenis_kelamin': jenisKelamin,
      'tahun_masuk': tahunMasuk,
      'tanggal_lahir':
          '${tanggalLahir.year.toString().padLeft(4, '0')}-${tanggalLahir.month.toString().padLeft(2, '0')}-${tanggalLahir.day.toString().padLeft(2, '0')}',
      'ket_aktif': ketAktif,
    };
  }

  Map<String, dynamic> toUpdateJson() => toInsertJson();

  SiswaModel copyWith({
    int? idDataSiswa,
    String? namaLengkap,
    String? nis,
    String? alamat,
    String? jenisKelamin,
    String? tahunMasuk,
    DateTime? tanggalLahir,
    int? ketAktif,
  }) {
    return SiswaModel(
      idDataSiswa: idDataSiswa ?? this.idDataSiswa,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      nis: nis ?? this.nis,
      alamat: alamat ?? this.alamat,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      tahunMasuk: tahunMasuk ?? this.tahunMasuk,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      ketAktif: ketAktif ?? this.ketAktif,
    );
  }
}
