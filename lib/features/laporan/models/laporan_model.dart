class LaporanModel {
  final int idLaporan;
  final int idRuangKelas;
  final int idDataSiswa;
  final DateTime tanggal;
  final String ziyadah;
  final String murajaah;
  final String tahsin; 
  final String tasmi;  
  final String pr;    

  LaporanModel({
    required this.idLaporan,
    required this.idRuangKelas,
    required this.idDataSiswa,
    required this.tanggal,
    required this.ziyadah,
    required this.murajaah,
    required this.tahsin,
    required this.tasmi,
    required this.pr
  });

  factory LaporanModel.fromJson(Map<String, dynamic> json) {
    return LaporanModel(
      idLaporan: (json['id_laporan'] as num).toInt(),
      idRuangKelas: (json['id_ruang_kelas'] as num).toInt(),
      idDataSiswa: (json['id_data_siswa'] as num).toInt(),
      tanggal: DateTime.tryParse('${json['tanggal']}') ?? DateTime(2000, 1, 1),
      ziyadah: (json['ziyadah'] ?? '') as String,
      murajaah: (json['murajaah'] ?? '') as String,
      tahsin: (json['tahsin'] ?? '') as String,
      tasmi: (json['tasmi']  ?? '') as String,
      pr: (json['pr']  ?? '') as String,
      
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id_ruang_kelas': idRuangKelas,
      'id_data_siswa': idDataSiswa,
      'tanggal':
          '${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
      'ziyadah': ziyadah,
      'murajaah': murajaah,
      'tahsin': tahsin,
      'tasmi': tasmi,
      'pr': pr,
      
    };
  }

  Map<String, dynamic> toUpdateJson() => toInsertJson();

  LaporanModel copyWith({
    int? idLaporan,
    int? idRuangKelas,
    int? idDataSiswa,
    DateTime? tanggal,
    String? ziyadah,
    String? murajaah,
    String? tahsin,
    String? tasmi,
    String? pr,
  }) {
    return LaporanModel(
      idLaporan: idLaporan ?? this.idLaporan,
      idRuangKelas: idRuangKelas ?? this.idRuangKelas,
      idDataSiswa: idDataSiswa ?? this.idDataSiswa,
      tanggal: tanggal ?? this.tanggal,
      ziyadah: ziyadah ?? this.ziyadah,
      murajaah: murajaah ?? this.murajaah,
      tahsin: tahsin ?? this.tahsin,
      tasmi: tasmi ?? this.tasmi,
      pr: pr ?? this.pr,
    );
  }
}
