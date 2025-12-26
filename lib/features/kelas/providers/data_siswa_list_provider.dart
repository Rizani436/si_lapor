// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../siswa/models/siswa_model.dart';

// final supabaseProvider = Provider<SupabaseClient>((ref) {
//   return Supabase.instance.client;
// });

// final datasiswaListProvider =
//     FutureProvider.autoDispose<List<SiswaModel>>((ref) async {
//   final sb = ref.read(supabaseProvider);

//   final res = await sb
//       .from('datasiswa')
//       .select('''
//         id_data_siswa,
//         nama_lengkap,
//         nis,
//         alamat,
//         jenis_kelamin,
//         tahun_masuk,
//         tanggal_lahir,
//         ket_aktif
//       ''')
//       // kalau mau cuma yang aktif:
//       .eq('ket_aktif', 1)
//       .order('nama_lengkap', ascending: true);

//   return (res as List)
//       .map((e) => SiswaModel.fromJson(e as Map<String, dynamic>))
//       .toList();
// });
