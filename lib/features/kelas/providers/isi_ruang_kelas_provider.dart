import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/isi_ruang_kelas_model.dart';
import '../data/isi_ruang_kelas_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final isiRuangKelasProvider = Provider<IsiRuangKelasService>((ref) {
  final sb = ref.read(supabaseClientProvider);
  return IsiRuangKelasService(sb);
});

final isiRuangKelasNamaProvider =
    FutureProvider.family.autoDispose<List<IsiRuangKelasModel>, int>(
  (ref, idRuangKelas) async {
    final service = ref.read(isiRuangKelasProvider);
    return await service.getIsiRuangKelasByRuang(idRuangKelas);
  },
);
