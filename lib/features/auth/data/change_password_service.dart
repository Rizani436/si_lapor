import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordService {
  final SupabaseClient sb;
  ChangePasswordService(this.sb);

  String _normEmail(String email) => email.trim().toLowerCase();

  Future<void> sendOtpToEmail(String email) async {
    final e = _normEmail(email);
    if (e.isEmpty) throw Exception('Email wajib diisi.');
    await sb.auth.resetPasswordForEmail(e);
  }

  Future<void> verifyOtpAndChangePassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final e = _normEmail(email);
    final otp = code.trim();
    final p1 = newPassword.trim();
    final p2 = confirmPassword.trim();

    if (e.isEmpty) throw Exception('Email wajib diisi.');
    if (otp.isEmpty) throw Exception('Kode (OTP) wajib diisi.');
    if (p1.isEmpty || p2.isEmpty) throw Exception('Password wajib diisi.');
    if (p1 != p2) throw Exception('Konfirmasi password tidak sama.');
    if (p1.length < 6) throw Exception('Password minimal 6 karakter.');

    await sb.auth.verifyOTP(
      email: e,
      token: otp,
      type: OtpType.recovery,
    );

    await sb.auth.updateUser(
      UserAttributes(password: p1),
    );
  }
}
