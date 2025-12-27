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

  final List<TasmiSummary> summaryReguler;
  final List<TasmiSummary> summaryTahfiz;

  const LaporanKepsekState({
    required this.loading,
    required this.error,
    required this.summaryReguler,
    required this.summaryTahfiz,
  });

  factory LaporanKepsekState.initial() => const LaporanKepsekState(
        loading: false,
        error: null,
        summaryReguler: [],
        summaryTahfiz: [],
      );

  LaporanKepsekState copyWith({
    bool? loading,
    String? error,
    List<TasmiSummary>? summaryReguler,
    List<TasmiSummary>? summaryTahfiz,
  }) {
    return LaporanKepsekState(
      loading: loading ?? this.loading,
      error: error,
      summaryReguler: summaryReguler ?? this.summaryReguler,
      summaryTahfiz: summaryTahfiz ?? this.summaryTahfiz,
    );
  }

  int get memenuhiReguler => summaryReguler.where((e) => e.memenuhi).length;
  int get belumReguler => summaryReguler.where((e) => !e.memenuhi).length;

  int get memenuhiTahfiz => summaryTahfiz.where((e) => e.memenuhi).length;
  int get belumTahfiz => summaryTahfiz.where((e) => !e.memenuhi).length;
}

class LaporanKepsekNotifier extends Notifier<LaporanKepsekState> {
  @override
  LaporanKepsekState build() => LaporanKepsekState.initial();

  void reset() => state = LaporanKepsekState.initial();

  Future<void> fetchSummary({
    required String tahunPelajaran,
    required String semester,
  }) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final service = ref.read(laporanKepsekServiceProvider);

      final laporanReg = await service.fetchLaporanTasmiByJenisKelas(
        tahunPelajaran: tahunPelajaran,
        semester: semester,
        jenisKelas: 'Reguler',
      );

      final laporanTah = await service.fetchLaporanTasmiByJenisKelas(
        tahunPelajaran: tahunPelajaran,
        semester: semester,
        jenisKelas: 'Tahfiz',
      );

      final ids = <int>{};
      for (final r in laporanReg) {
        final id = r['id_data_siswa'];
        if (id is int) ids.add(id);
      }
      for (final r in laporanTah) {
        final id = r['id_data_siswa'];
        if (id is int) ids.add(id);
      }

      final namaMap = await service.fetchNamaSiswaMap(ids.toList());

      final summaryReg = buildSummaryCompletedJuz(
        laporan: laporanReg,
        jenisKelas: 'Reguler',
        namaById: namaMap,
      );

      final summaryTah = buildSummaryCompletedJuz(
        laporan: laporanTah,
        jenisKelas: 'Tahfiz',
        namaById: namaMap,
      );

      state = state.copyWith(
        loading: false,
        error: null,
        summaryReguler: summaryReg,
        summaryTahfiz: summaryTah,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }
}
