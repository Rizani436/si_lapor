class GuruModel {
  final int idDataGuru;
  final String namaLengkap;
  final String nip;
  final String alamat;
  final String jenisKelamin;
  final int ketAktif;      

  GuruModel({
    required this.idDataGuru,
    required this.namaLengkap,
    required this.nip,
    required this.alamat,
    required this.jenisKelamin,
    required this.ketAktif,
  });

  bool get isAktif => ketAktif == 1;

  factory GuruModel.fromJson(Map<String, dynamic> json) {
    return GuruModel(
      idDataGuru: (json['id_data_guru'] as num).toInt(),
      namaLengkap: (json['nama_lengkap'] ?? '') as String,
      nip: (json['nip'] ?? '') as String,
      alamat: (json['alamat'] ?? '') as String,
      jenisKelamin: (json['jenis_kelamin'] ?? '') as String,
      ketAktif: (json['ket_aktif'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'nama_lengkap': namaLengkap,
      'nip': nip,
      'alamat': alamat,
      'jenis_kelamin': jenisKelamin,
      'ket_aktif': ketAktif,
    };
  }

  Map<String, dynamic> toUpdateJson() => toInsertJson();

  GuruModel copyWith({
    int? idDataGuru,
    String? namaLengkap,
    String? nip,
    String? alamat,
    String? jenisKelamin,
    int? ketAktif,
  }) {
    return GuruModel(
      idDataGuru: idDataGuru ?? this.idDataGuru,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      nip: nip ?? this.nip,
      alamat: alamat ?? this.alamat,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      ketAktif: ketAktif ?? this.ketAktif,
    );
  }
}
