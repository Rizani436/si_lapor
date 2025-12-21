import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/guru_service.dart';
import '../models/guru_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final guruServiceProvider = Provider<GuruService>((ref) {
  return GuruService(ref.read(supabaseClientProvider));
});

final guruListProvider =
    AsyncNotifierProvider<GuruListNotifier, List<GuruModel>>(
  GuruListNotifier.new,
);

class GuruListNotifier extends AsyncNotifier<List<GuruModel>> {
  late final GuruService _service = ref.read(guruServiceProvider);

  @override
  Future<List<GuruModel>> build() async {
    return _service.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getAll());
  }

  Future<void> add(GuruModel payload) async {
    final List<GuruModel> current = List<GuruModel>.from(state.value ?? <GuruModel>[]);
    state = AsyncData(current);

    final created = await _service.create(payload);
    state = AsyncData(<GuruModel>[created, ...current]);
  }

  Future<void> edit(int idDataGuru, GuruModel payload) async {
    final List<GuruModel> current = List<GuruModel>.from(state.value ?? <GuruModel>[]);
    final updated = await _service.update(idDataGuru, payload);

    final idx = current.indexWhere((x) => x.idDataGuru == idDataGuru);
    if (idx != -1) {
      current[idx] = updated;
    }

    state = AsyncData(current);
  }

  Future<void> remove(int idDataGuru) async {
    final List<GuruModel> current = List<GuruModel>.from(state.value ?? <GuruModel>[]);

    await _service.delete(idDataGuru);
    current.removeWhere((x) => x.idDataGuru == idDataGuru);

    state = AsyncData(current);
  }

  Future<void> toggleAktif(GuruModel s) async {
    final List<GuruModel> current = List<GuruModel>.from(state.value ?? <GuruModel>[]);

    final updated = await _service.toggleAktif(s);

    final idx = current.indexWhere((x) => x.idDataGuru == s.idDataGuru);
    if (idx != -1) {
      current[idx] = updated;
    }

    state = AsyncData(current);
  }
}
