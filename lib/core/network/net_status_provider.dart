import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetStatus { online, offline }

NetStatus _mapResults(List<ConnectivityResult> results) {
  if (results.isEmpty ||
      results.every((r) => r == ConnectivityResult.none)) {
    return NetStatus.offline;
  }
  return NetStatus.online;
}

final netStatusProvider = StreamProvider<NetStatus>((ref) async* {
  final c = Connectivity();

  final initial = await c.checkConnectivity();
  yield _mapResults(initial);

  await for (final results in c.onConnectivityChanged) {
    yield _mapResults(results);
  }
});
