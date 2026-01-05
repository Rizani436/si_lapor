class GuruPick {
  final int idDataGuru;
  final String namaLengkap;

  const GuruPick({
    required this.idDataGuru,
    required this.namaLengkap,
  });

  factory GuruPick.fromJoinJson(Map<String, dynamic> json) {
    final dataguru = json['dataguru'] as Map<String, dynamic>?;
    return GuruPick(
      idDataGuru: (json['id_data_guru'] as num).toInt(),
      namaLengkap: (dataguru?['nama_lengkap'] ?? '').toString(),
    );
  }
}
