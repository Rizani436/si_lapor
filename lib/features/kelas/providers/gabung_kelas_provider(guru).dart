import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/session/session_provider.dart';

import '../models/guru_pick.dart';
import '../data/gabung_kelas_service.dart';

final gabungKelasServiceProviderGuru = Provider<GabungKelasService>((ref) {
  final sb = Supabase.instance.client;
  return GabungKelasService(sb);
});

final gabungKelasProviderGuru =
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

  final List<GuruPick> guruList;
  final int? selectedIdDataGuru;

  const GabungKelasState({
    this.loading = false,
    this.error,
    this.checked = false,
    this.notFound = false,
    this.idRuangKelas,
    this.kodeKelas,
    this.guruList = const [],
    this.selectedIdDataGuru,
  });

  GabungKelasState copyWith({
    bool? loading,
    String? error,
    bool? checked,
    bool? notFound,
    int? idRuangKelas,
    String? kodeKelas,
    List<GuruPick>? guruList,
    int? selectedIdDataGuru,
  }) {
    return GabungKelasState(
      loading: loading ?? this.loading,
      error: error,
      checked: checked ?? this.checked,
      notFound: notFound ?? this.notFound,
      idRuangKelas: idRuangKelas ?? this.idRuangKelas,
      kodeKelas: kodeKelas ?? this.kodeKelas,
      guruList: guruList ?? this.guruList,
      selectedIdDataGuru: selectedIdDataGuru ?? this.selectedIdDataGuru,
    );
  }
}

class GabungKelasNotifier extends Notifier<GabungKelasState> {
  SupabaseClient get _sb => Supabase.instance.client;

  @override
  GabungKelasState build() => const GabungKelasState();

  GabungKelasService get _service => ref.read(gabungKelasServiceProviderGuru);

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
      guruList: const [],
      selectedIdDataGuru: null,
    );

    final session = ref.read(sessionProvider);
    final uid = session.userId;
    if (uid == null) throw Exception('Session tidak valid. Silakan login ulang.');



    try {
      final ruang = await _service.getRuangByKode(clean);

      if (ruang == null) {
        state = state.copyWith(loading: false, notFound: true);
        return;
      }

      final idRuangKelas = (ruang['id_ruang_kelas'] as num).toInt();
      final cek = await _service.cekGabungGuru(idRuangKelas, uid);

      if(cek != null){
        state = state.copyWith(loading: false, error: "Kamu sudah masuk ke kelas ini", notFound: true); 
        return;
      }


      final list = await _service.getGuruKosongByRuangGuru(idRuangKelas);

      state = state.copyWith(
        loading: false,
        notFound: false,
        idRuangKelas: idRuangKelas,
        guruList: list,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void pilihGuru(int idDataGuru) {
    state = state.copyWith(selectedIdDataGuru: idDataGuru);
  }

  Future<void> konfirmasiGabung() async {
    final idRuangKelas = state.idRuangKelas;
    final idDataGuru = state.selectedIdDataGuru;
    final userId = _sb.auth.currentUser?.id;

    if (idRuangKelas == null) {
      state = state.copyWith(error: 'Kode kelas belum valid.');
      return;
    }
    if (idDataGuru == null) {
      state = state.copyWith(error: 'Pilih salah satu data guru dulu.');
      return;
    }
    if (userId == null) {
      state = state.copyWith(error: 'Kamu belum login.');
      return;
    }

    state = state.copyWith(loading: true, error: null);

    try {
      await _service.gabungKelasGuru(
        idRuangKelas: idRuangKelas,
        idDataGuru: idDataGuru,
        userId: userId,
      );
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void reset() => state = const GabungKelasState();
}
