class IsiRuangKelasModel {
  final int id;
  final int idRuangKelas;

  final int? idDataSiswa;
  final String? idUserSiswa;
  final String? namaSiswa;
  final String? emailUser;

  final int? idDataGuru;
  final String? idUserGuru;
  final String? namaGuru;
  final String? emailGuru;

  IsiRuangKelasModel({
    required this.id,
    required this.idRuangKelas,
    this.idDataSiswa,
    this.idUserSiswa,
    this.namaSiswa,
    this.emailUser,
    this.idDataGuru,
    this.idUserGuru,
    this.namaGuru,
    this.emailGuru,
  });

  factory IsiRuangKelasModel.fromJson(Map<String, dynamic> json) {

    final namaSiswaMap = json['nama_siswa'] as Map<String, dynamic>?;
    final namaGuruMap  = json['nama_guru'] as Map<String, dynamic>?;

    final emailSiswaMap = json['email_siswa'] as Map<String, dynamic>?;
    final emailGuruMap  = json['email_guru'] as Map<String, dynamic>?;

    return IsiRuangKelasModel(
      id: json['id'] as int,
      idRuangKelas: json['id_ruang_kelas'] as int,

      idDataSiswa: json['id_data_siswa'] as int?,
      idUserSiswa: json['id_user_siswa'] as String?,
      namaSiswa: namaSiswaMap?['nama_lengkap'] as String?,
      emailUser: emailSiswaMap?['email'] as String?,

      idDataGuru: json['id_data_guru'] as int?,
      idUserGuru: json['id_user_guru'] as String?,
      namaGuru: namaGuruMap?['nama_lengkap'] as String?,
      emailGuru: emailGuruMap?['email'] as String?,
    );
  }
}
