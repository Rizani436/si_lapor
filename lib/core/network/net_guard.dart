import 'dart:io';

Future<T> networkGuard<T>(Future<T> Function() fn, String errorMessage) async {
  try {
    return await fn();
  } on SocketException {
    throw Exception('Tidak ada koneksi internet');
  } catch (e) {
    throw Exception('$errorMessage: $e');
  }
}
