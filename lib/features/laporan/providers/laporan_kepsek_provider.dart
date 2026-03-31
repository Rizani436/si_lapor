import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/laporan_kepsek_service.dart';
import '../../../core/utils/hasil_laporan_helper.dart';

final laporanKepsekServiceProvider = Provider<LaporanKepsekService>((ref) {
  return LaporanKepsekService(Supabase.instance.client);
});

final laporanKepsekProvider =
    NotifierProvider<LaporanKepsekNotifier, LaporanKepsekState>(
      LaporanKepsekNotifier.new,
    );

class LaporanKepsekState {
  final bool loading;
  final String? error;

  final List<TasmiSummary> summaryAll;

  const LaporanKepsekState({
    required this.loading,
    required this.error,
    required this.summaryAll,
  });

  factory LaporanKepsekState.initial() =>
      const LaporanKepsekState(loading: false, error: null, summaryAll: []);

  LaporanKepsekState copyWith({
    bool? loading,
    String? error,
    List<TasmiSummary>? summaryAll,
  }) {
    return LaporanKepsekState(
      loading: loading ?? this.loading,
      error: error,
      summaryAll: summaryAll ?? this.summaryAll,
    );
  }

  int get memenuhiReguler => summaryAll.where((e) => e.memenuhi && e.jumlahJuz <= 2).length;
  int get belumReguler => summaryAll.where((e) => !e.memenuhi && e.jumlahJuz <= 2).length;

  int get memenuhiTahfiz => summaryAll.where((e) => e.memenuhi && e.jumlahJuz > 2).length;
  int get belumTahfiz => summaryAll.where((e) => !e.memenuhi && e.jumlahJuz > 2).length;

  List<TasmiSummary> get summaryReguler => summaryAll.where((e) => e.jumlahJuz <= 2).toList();
  List<TasmiSummary> get summaryTahfiz => summaryAll.where((e) => e.jumlahJuz > 2).toList();
}

class LaporanKepsekNotifier extends Notifier<LaporanKepsekState> {
  @override
  LaporanKepsekState build() => LaporanKepsekState.initial();

  void reset() => state = LaporanKepsekState.initial();

  Future<void> fetchSummary({
    required String tahunPelajaran,
    String? semester,
  }) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final service = ref.read(laporanKepsekServiceProvider);

      final laporan = await service.fetchLaporanTasmiByJenisKelas(
        tahunPelajaran: tahunPelajaran,
        semester: semester,
      );

      final ids = <int>{};
      for (final r in laporan) {
        final id = r['id_data_siswa'];
        if (id is int) ids.add(id);
      }

      final namaMap = await service.fetchNamaSiswaMap(ids.toList());

      final summaryAll = buildSummaryCompletedJuz(
        laporan: laporan,
        namaById: namaMap,
      );

      state = state.copyWith(
        loading: false,
        error: null,
        summaryAll: summaryAll,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }
}
