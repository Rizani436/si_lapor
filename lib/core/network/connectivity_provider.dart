import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetStatus { online, offline }

final netStatusProvider = StreamProvider<NetStatus>((ref) {
  final connectivity = Connectivity();

  return connectivity.onConnectivityChanged.map((result) {
    if (result == ConnectivityResult.none) return NetStatus.offline;
    return NetStatus.online;
  });
});
