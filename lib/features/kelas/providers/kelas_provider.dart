import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/kelas_service.dart';
import '../models/kelas_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final kelasServiceProvider = Provider<KelasService>((ref) {
  return KelasService(ref.read(supabaseClientProvider));
});

final kelasListProvider =
    AsyncNotifierProvider<KelasListNotifier, List<KelasModel>>(
  KelasListNotifier.new,
);

class KelasListNotifier extends AsyncNotifier<List<KelasModel>> {
  late final KelasService _service = ref.read(kelasServiceProvider);

  @override
  Future<List<KelasModel>> build() async {
    return _service.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getAll());
  }

  Future<void> add(KelasModel payload) async {
    final List<KelasModel> current = List<KelasModel>.from(state.value ?? <KelasModel>[]);
    state = AsyncData(current);

    final created = await _service.create(payload);
    state = AsyncData(<KelasModel>[created, ...current]);
  }

  Future<void> edit(int idRuangKelas, KelasModel payload) async {
    final List<KelasModel> current = List<KelasModel>.from(state.value ?? <KelasModel>[]);
    final updated = await _service.update(idRuangKelas, payload);

    final idx = current.indexWhere((x) => x.idRuangKelas == idRuangKelas);
    if (idx != -1) {
      current[idx] = updated;
    }

    state = AsyncData(current);
  }

  Future<void> remove(int idRuangKelas) async {
    final List<KelasModel> current = List<KelasModel>.from(state.value ?? <KelasModel>[]);

    await _service.delete(idRuangKelas);
    current.removeWhere((x) => x.idRuangKelas == idRuangKelas);

    state = AsyncData(current);
  }

  Future<void> toggleAktif(KelasModel s) async {
    final List<KelasModel> current = List<KelasModel>.from(state.value ?? <KelasModel>[]);

    final updated = await _service.toggleAktif(s);

    final idx = current.indexWhere((x) => x.idRuangKelas == s.idRuangKelas);
    if (idx != -1) {
      current[idx] = updated;
    }

    state = AsyncData(current);
  }
}
