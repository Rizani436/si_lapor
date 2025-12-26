// class DataSiswaModel {
//   final int idDataSiswa;
//   final String namaLengkap;
//   final String? nis;
//   final String? alamat;
//   final String? jenisKelamin;
//   final String? tahunMasuk;
//   final DateTime? tanggalLahir;
//   final int? ketAktif;

//   DataSiswaModel({
//     required this.idDataSiswa,
//     required this.namaLengkap,
//     this.nis,
//     this.alamat,
//     this.jenisKelamin,
//     this.tahunMasuk,
//     this.tanggalLahir,
//     this.ketAktif,
//   });

//   factory DataSiswaModel.fromJson(Map<String, dynamic> json) {
//     return DataSiswaModel(
//       idDataSiswa: json['id_data_siswa'] as int,
//       namaLengkap: (json['nama_lengkap'] as String?) ?? '',
//       nis: json['nis']?.toString(),
//       alamat: json['alamat'] as String?,
//       jenisKelamin: json['jenis_kelamin'] as String?,
//       tahunMasuk: json['tahun_masuk'] as String?,
//       tanggalLahir: json['tanggal_lahir'] != null
//           ? DateTime.tryParse(json['tanggal_lahir'].toString())
//           : null,
//       ketAktif: (json['ket_aktif'] as num?)?.toInt(),
//     );
//   }
// }
