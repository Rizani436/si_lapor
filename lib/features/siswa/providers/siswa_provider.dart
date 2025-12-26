import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/siswa_service.dart';
import '../models/siswa_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final siswaServiceProvider = Provider<SiswaService>((ref) {
  return SiswaService(ref.read(supabaseClientProvider));
});

final siswaListProvider =
    AsyncNotifierProvider<SiswaListNotifier, List<SiswaModel>>(
  SiswaListNotifier.new,
);

class SiswaListNotifier extends AsyncNotifier<List<SiswaModel>> {
  late final SiswaService _service = ref.read(siswaServiceProvider);

  @override
  Future<List<SiswaModel>> build() async {
    return _service.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getAll());
  }

  Future<void> add(SiswaModel payload) async {
    final List<SiswaModel> current = List<SiswaModel>.from(state.value ?? <SiswaModel>[]);
    state = AsyncData(current);

    final created = await _service.create(payload);
    state = AsyncData(<SiswaModel>[created, ...current]);
  }

  Future<void> edit(int idDataSiswa, SiswaModel payload) async {
    final List<SiswaModel> current = List<SiswaModel>.from(state.value ?? <SiswaModel>[]);

    final updated = await _service.update(idDataSiswa, payload);

    final idx = current.indexWhere((x) => x.idDataSiswa == idDataSiswa);
    if (idx != -1) {
      current[idx] = updated;
    }

    state = AsyncData(current);
  }

  Future<void> remove(int idDataSiswa) async {
    final List<SiswaModel> current = List<SiswaModel>.from(state.value ?? <SiswaModel>[]);

    await _service.delete(idDataSiswa);
    current.removeWhere((x) => x.idDataSiswa == idDataSiswa);

    state = AsyncData(current);
  }

  Future<void> toggleAktif(SiswaModel s) async {
    final List<SiswaModel> current = List<SiswaModel>.from(state.value ?? <SiswaModel>[]);

    final updated = await _service.toggleAktif(s);

    final idx = current.indexWhere((x) => x.idDataSiswa == s.idDataSiswa);
    if (idx != -1) {
      current[idx] = updated;
    }

    state = AsyncData(current);
  }

  Future<SiswaModel> getSiswa(int idDataSiswa) async{
    return await _service.getSiswa(idDataSiswa);
  }
}
