import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/laporan_service.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final laporanServiceProvider = Provider<LaporanService>((ref) {
  return LaporanService(ref.read(supabaseProvider));
});

final laporanByTanggalProvider = FutureProvider.family<
    List<Map<String, dynamic>>,
    ({int idRuangKelas, int idDataSiswa, String tanggal})>((ref, q) async {
  final service = ref.read(laporanServiceProvider);
  return service.getByTanggal(
    idRuangKelas: q.idRuangKelas,
    idDataSiswa: q.idDataSiswa,
    tanggal: q.tanggal,
  );
});

final laporanActionProvider =
    AsyncNotifierProvider<LaporanActionNotifier, void>(
  LaporanActionNotifier.new,
);

class LaporanActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createLaporan(Map<String, dynamic> payload) async {
    state = const AsyncLoading();
    try {
      await ref.read(laporanServiceProvider).create(payload);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateLaporan(int idLaporan, Map<String, dynamic> payload) async {
    state = const AsyncLoading();
    try {
      await ref.read(laporanServiceProvider).update(idLaporan, payload);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteLaporan(int idLaporan) async {
    state = const AsyncLoading();
    try {
      await ref.read(laporanServiceProvider).delete(idLaporan);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
