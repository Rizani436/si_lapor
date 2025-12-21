import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/akun_service.dart';
import '../models/akun_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final akunServiceProvider = Provider<AkunService>((ref) {
  return AkunService(ref.read(supabaseClientProvider));
});

final akunListProvider =
    AsyncNotifierProvider<AkunListNotifier, List<AkunModel>>(
      AkunListNotifier.new,
    );

class AkunListNotifier extends AsyncNotifier<List<AkunModel>> {
  late final AkunService _service = ref.read(akunServiceProvider);

  @override
  Future<List<AkunModel>> build() async {
    return _service.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getAll());
  }

  Future<void> add(AkunModel payload, String password) async {
    final current = List<AkunModel>.from(state.value ?? const <AkunModel>[]);
    state = AsyncData(current);

    final created = await _service.create(
      payload: payload,
      password: password,
    );

    state = AsyncData(<AkunModel>[created, ...current]);
  }

  Future<void> edit(String id, AkunModel payload) async {
    final current = List<AkunModel>.from(state.value ?? const <AkunModel>[]);

    final updated = await _service.update(id, payload);

    final idx = current.indexWhere((x) => x.id == id);
    if (idx != -1) current[idx] = updated;

    state = AsyncData(current);
  }

  Future<void> remove(String id) async {
    final current = List<AkunModel>.from(state.value ?? const <AkunModel>[]);

    await _service.delete(id);
    current.removeWhere((x) => x.id == id);

    state = AsyncData(current);
  }

  Future<void> toggleAktif(AkunModel a) async {
    final current = List<AkunModel>.from(state.value ?? const <AkunModel>[]);

    final updated = await _service.toggleAktif(a);

    final idx = current.indexWhere((x) => x.id == a.id);
    if (idx != -1) current[idx] = updated;

    state = AsyncData(current);
  }
}
