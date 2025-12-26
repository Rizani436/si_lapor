import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/siswa_pick.dart';
import '../data/gabung_kelas_service.dart';

final gabungKelasServiceProvider = Provider<GabungKelasService>((ref) {
  final sb = Supabase.instance.client;
  return GabungKelasService(sb);
});

final gabungKelasProvider =
    NotifierProvider<GabungKelasNotifier, GabungKelasState>(
  GabungKelasNotifier.new,
);

class GabungKelasState {
  final bool loading;
  final String? error;

  final bool checked;
  final bool notFound;

  final int? idRuangKelas;
  final String? kodeKelas;

  final List<SiswaPick> siswaList;
  final int? selectedIdDataSiswa;

  const GabungKelasState({
    this.loading = false,
    this.error,
    this.checked = false,
    this.notFound = false,
    this.idRuangKelas,
    this.kodeKelas,
    this.siswaList = const [],
    this.selectedIdDataSiswa,
  });

  GabungKelasState copyWith({
    bool? loading,
    String? error,
    bool? checked,
    bool? notFound,
    int? idRuangKelas,
    String? kodeKelas,
    List<SiswaPick>? siswaList,
    int? selectedIdDataSiswa,
  }) {
    return GabungKelasState(
      loading: loading ?? this.loading,
      error: error,
      checked: checked ?? this.checked,
      notFound: notFound ?? this.notFound,
      idRuangKelas: idRuangKelas ?? this.idRuangKelas,
      kodeKelas: kodeKelas ?? this.kodeKelas,
      siswaList: siswaList ?? this.siswaList,
      selectedIdDataSiswa: selectedIdDataSiswa ?? this.selectedIdDataSiswa,
    );
  }
}

class GabungKelasNotifier extends Notifier<GabungKelasState> {
  SupabaseClient get _sb => Supabase.instance.client;

  @override
  GabungKelasState build() => const GabungKelasState();

  GabungKelasService get _service => ref.read(gabungKelasServiceProvider);

  Future<void> cekKodeKelas(String kode) async {
    final clean = kode.trim().toUpperCase();
    if (clean.isEmpty) return;

    state = state.copyWith(
      loading: true,
      error: null,
      checked: true,
      notFound: false,
      idRuangKelas: null,
      kodeKelas: clean,
      siswaList: const [],
      selectedIdDataSiswa: null,
    );

    try {
      final ruang = await _service.getRuangByKode(clean);

      if (ruang == null) {
        state = state.copyWith(loading: false, notFound: true);
        return;
      }

      final idRuangKelas = (ruang['id_ruang_kelas'] as num).toInt();
      final list = await _service.getSiswaKosongByRuang(idRuangKelas);

      state = state.copyWith(
        loading: false,
        notFound: false,
        idRuangKelas: idRuangKelas,
        siswaList: list,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void pilihSiswa(int idDataSiswa) {
    state = state.copyWith(selectedIdDataSiswa: idDataSiswa);
  }

  Future<void> konfirmasiGabung() async {
    final idRuangKelas = state.idRuangKelas;
    final idDataSiswa = state.selectedIdDataSiswa;
    final userId = _sb.auth.currentUser?.id;

    if (idRuangKelas == null) {
      state = state.copyWith(error: 'Kode kelas belum valid.');
      return;
    }
    if (idDataSiswa == null) {
      state = state.copyWith(error: 'Pilih salah satu data siswa dulu.');
      return;
    }
    if (userId == null) {
      state = state.copyWith(error: 'Kamu belum login.');
      return;
    }

    state = state.copyWith(loading: true, error: null);

    try {
      await _service.gabungKelas(
        idRuangKelas: idRuangKelas,
        idDataSiswa: idDataSiswa,
        userId: userId,
      );
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void reset() => state = const GabungKelasState();
}
