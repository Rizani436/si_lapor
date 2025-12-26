import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/kelas_service.dart';
import '../models/kelas_model.dart';
import '../../../core/session/session_provider.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final detailKelasGuruServiceProvider = Provider<KelasService>((ref) {
  return KelasService(ref.read(supabaseClientProvider));
});

final kelasGuruListProvider =
    AsyncNotifierProvider<KelasGuruListNotifier, List<KelasModel>>(
      KelasGuruListNotifier.new,
    );

class KelasGuruListNotifier extends AsyncNotifier<List<KelasModel>> {
  late final KelasService _service = ref.read(detailKelasGuruServiceProvider);

  @override
  Future<List<KelasModel>> build() async {
    final session = ref.read(sessionProvider);
    final uid = session.userId;

    if (uid == null) return [];
    return _service.getAllMy(uid);
  }

  Future<void> refresh() async {
    final session = ref.read(sessionProvider);
    final uid = session.userId;
    if (uid == null) return;
    
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getAllMy(uid));
  }

  Future<void> add(KelasModel payload) async {
    final List<KelasModel> current = List<KelasModel>.from(
      state.value ?? <KelasModel>[],
    );
    state = AsyncData(current);

    final created = await _service.create(payload);
    state = AsyncData(<KelasModel>[created, ...current]);
  }

  Future<void> edit(int idRuangKelas, KelasModel payload) async {
    final List<KelasModel> current = List<KelasModel>.from(
      state.value ?? <KelasModel>[],
    );
    final updated = await _service.update(idRuangKelas, payload);

    final idx = current.indexWhere((x) => x.idRuangKelas == idRuangKelas);
    if (idx != -1) {
      current[idx] = updated;
    }

    state = AsyncData(current);
  }

  Future<void> remove(int idRuangKelas) async {
    final List<KelasModel> current = List<KelasModel>.from(
      state.value ?? <KelasModel>[],
    );

    await _service.delete(idRuangKelas);
    current.removeWhere((x) => x.idRuangKelas == idRuangKelas);

    state = AsyncData(current);
  }

  Future<void> toggleAktif(KelasModel s) async {
    final List<KelasModel> current = List<KelasModel>.from(
      state.value ?? <KelasModel>[],
    );

    final updated = await _service.toggleAktif(s);

    final idx = current.indexWhere((x) => x.idRuangKelas == s.idRuangKelas);
    if (idx != -1) {
      current[idx] = updated;
    }

    state = AsyncData(current);
  }
}
