class IsiRuangKelasModel {
  final int id;
  final int idRuangKelas;

  final int? idDataSiswa;
  final String? idUserSiswa;
  final String? namaSiswa;

  final int? idDataGuru;
  final String? idUserGuru;
  final String? namaGuru;

  IsiRuangKelasModel({
    required this.id,
    required this.idRuangKelas,
    this.idDataSiswa,
    this.idUserSiswa,
    this.namaSiswa,
    this.idDataGuru,
    this.idUserGuru,
    this.namaGuru,
  });

  factory IsiRuangKelasModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'] as Map<String, dynamic>?;
    final guru = json['guru'] as Map<String, dynamic>?;

    return IsiRuangKelasModel(
      id: json['id'] as int,
      idRuangKelas: json['id_ruang_kelas'] as int,

      idDataSiswa: json['id_data_siswa'] as int?,
      idUserSiswa: json['id_user_siswa'] as String?,
      namaSiswa: siswa?['nama_lengkap'] as String?,

      idDataGuru: json['id_data_guru'] as int?,
      idUserGuru: json['id_user_guru'] as String?,
      namaGuru: guru?['nama_lengkap'] as String?,
    );
  }
}
