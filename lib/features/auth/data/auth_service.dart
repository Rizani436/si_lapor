import '../../../core/config/supabase_client.dart';

class AuthRepository {
  Future<void> register({
    required String namaLengkap,
    required String noHp,
    required String email,
    required String password,
  }) async {
    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'nama_lengkap': namaLengkap, 'no_hp': noHp},
      );

      if (res.user == null) {
        throw Exception('Registrasi gagal.');
      }
    } catch (e) {
      throw Exception('Registrasi gagal: $e');
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session == null || res.user == null) {
        throw Exception('Login gagal. Email atau password salah.');
      }
    } catch (e) {
      throw Exception('Login gagal: $e');
    }
  }
}
