import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifikasi_provider.dart';

final notifUnreadPollingProvider =
    StreamProvider.autoDispose<int>((ref) async* {
  final svc = ref.read(notifikasiServiceProvider);

  yield await svc.countUnread();

  while (true) {
    await Future.delayed(const Duration(seconds: 3));
    yield await svc.countUnread();
  }
});
