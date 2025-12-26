import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import  '../models/isiruangkelasnama_model.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final isiRuangKelasNamaProvider = FutureProvider.family
    .autoDispose<List<IsiRuangKelasNamaModel>, int>((ref, idRuangKelas) async {
  final sb = ref.read(supabaseProvider);

 final res = await sb
    .from('isiruangkelas')
    .select('''
      id,
      id_ruang_kelas,
      id_data_siswa,
      id_user_siswa,
      id_data_guru,
      id_user_guru,
      siswa:datasiswa(nama_lengkap),
      guru:dataguru(nama_lengkap)
    ''')
    .eq('id_ruang_kelas', idRuangKelas)
    .order('id', ascending: true);

  final list = (res as List)
      .map((e) => IsiRuangKelasNamaModel.fromJson(e as Map<String, dynamic>))
      .toList();

  return list;
});
