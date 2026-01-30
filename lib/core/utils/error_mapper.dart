import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'failure.dart';

class ErrorMapper {
  static Failure fromGeneric(Object error) {
    if (error is SocketException) {
      return const Failure('Tidak ada koneksi internet. Cek jaringan Anda.');
    }

    if (error is http.ClientException) {
      return const Failure('Gagal terhubung ke server. Periksa internet Anda.');
    }

    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return const Failure('Email atau password salah.');
      }
      if (msg.contains('already registered')) {
        return const Failure('Email sudah terdaftar.');
      }
      return Failure(error.message);
    }

    if (error is PostgrestException) {
      return Failure('Kesalahan database: ${error.message}');
    }

    return const Failure('Terjadi kesalahan tidak diketahui.');
  }
  static Failure from(Object e) {
    if (e is SocketException) {
      return const Failure('Tidak ada koneksi internet.');
    }

    if (e is http.ClientException) {
      return const Failure('Server tidak dapat dihubungi. Cek jaringan Anda.');
    }

    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return const Failure('Email atau password salah.');
      }
      if (msg.contains('already registered')) {
        return const Failure('Email sudah terdaftar.');
      }
      return Failure(e.message);
    }

    if (e is PostgrestException) {
      return Failure(e.message);
    }

    return const Failure('Terjadi kesalahan tidak diketahui.');
  }
}
