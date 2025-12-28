import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/rapor_service.dart';

final raporServiceProvider = Provider<RaporService>((ref) {
  return RaporService(Supabase.instance.client);
});

typedef RaporKey = ({int idDataSiswa, int idRuangKelas});

final raporUrlProvider = FutureProvider.family.autoDispose<String?, RaporKey>(
  (ref, key) async {
    final svc = ref.read(raporServiceProvider);
    return svc.getRaporUrl(
      idDataSiswa: key.idDataSiswa,
      idRuangKelas: key.idRuangKelas,
    );
  },
);
