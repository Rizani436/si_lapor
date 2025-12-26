class SiswaPick {
  final int idDataSiswa;
  final String namaLengkap;

  const SiswaPick({
    required this.idDataSiswa,
    required this.namaLengkap,
  });

  factory SiswaPick.fromJoinJson(Map<String, dynamic> json) {
    final datasiswa = json['datasiswa'] as Map<String, dynamic>?;
    return SiswaPick(
      idDataSiswa: (json['id_data_siswa'] as num).toInt(),
      namaLengkap: (datasiswa?['nama_lengkap'] ?? '').toString(),
    );
  }
}
