import '../../../core/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  Future<void> register({
    required String namaLengkap,
    required String noHp, 
    required String email,
    required String password,
  }) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'nama_lengkap': namaLengkap,
        'no_hp': noHp,
      },
    );

    if (res.user == null) {
      throw Exception('Registrasi gagal.');
    }

  }

  Future<void> login({required String email, required String password}) async {
    final res = await supabase.auth.signInWithPassword(email: email, password: password);
    if (res.user == null) throw Exception('Login gagal.');
  }
}
