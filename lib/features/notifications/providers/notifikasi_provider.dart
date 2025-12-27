import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notifikasi_model.dart';
import '../data/notifikasi_service.dart';

final notifikasiServiceProvider = Provider<NotifikasiService>((ref) {
  return NotifikasiService(Supabase.instance.client);
});

// ✅ FETCH DB (bukan realtime stream)
final notifikasiListProvider =
    FutureProvider.autoDispose<List<NotifikasiModel>>((ref) async {
  final svc = ref.read(notifikasiServiceProvider);
  return svc.getMine();
});

final notifikasiUnreadCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final svc = ref.read(notifikasiServiceProvider);
  return svc.countUnread();
});
