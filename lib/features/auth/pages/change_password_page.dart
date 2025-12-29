import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/change_password_provider.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final emailC = TextEditingController();
  final codeC = TextEditingController();
  final pass1C = TextEditingController();
  final pass2C = TextEditingController();

  bool codeSent = false;
  bool obscure1 = true;
  bool obscure2 = true;

  static const int otpTtlSeconds = 10 * 60; 
  Timer? _otpTimer;
  int _otpRemaining = 0;

  static const int resendCooldownSeconds = 60; 
  Timer? _resendTimer;
  int _resendRemaining = 0;

  bool get otpExpired => codeSent && _otpRemaining <= 0;
  bool get canResend => _resendRemaining <= 0;

  @override
  void dispose() {
    _otpTimer?.cancel();
    _resendTimer?.cancel();
    emailC.dispose();
    codeC.dispose();
    pass1C.dispose();
    pass2C.dispose();
    super.dispose();
  }

  void snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() => _otpRemaining = otpTtlSeconds);

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_otpRemaining <= 1) {
        t.cancel();
        setState(() => _otpRemaining = 0);
      } else {
        setState(() => _otpRemaining--);
      }
    });
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendRemaining = resendCooldownSeconds);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendRemaining <= 1) {
        t.cancel();
        setState(() => _resendRemaining = 0);
      } else {
        setState(() => _resendRemaining--);
      }
    });
  }

  void _resetOtpFlow({bool clearEmail = false}) {
    _otpTimer?.cancel();
    _resendTimer?.cancel();

    codeC.clear();
    pass1C.clear();
    pass2C.clear();

    if (clearEmail) emailC.clear();

    setState(() {
      codeSent = false;
      _otpRemaining = 0;
      _resendRemaining = 0;
    });
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString();
    if (msg.toLowerCase().contains('email rate limit exceeded')) {
      return 'Terlalu sering kirim email. Tunggu sebentar lalu coba lagi.';
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordControllerProvider);
    final loading = state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Masukkan email akun kamu, lalu kami kirim kode verifikasi.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
              enabled: !codeSent,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'contoh@email.com',
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (loading || !canResend)
                    ? null
                    : () async {
                        FocusScope.of(context).unfocus();
                        try {
                          await ref
                              .read(changePasswordControllerProvider.notifier)
                              .sendOtp(email: emailC.text);

                          setState(() => codeSent = true);
                          _startOtpTimer();
                          _startResendCooldown();

                          snack('Kode dikirim. Cek inbox/spam.');
                        } catch (e) {
                          snack(_friendlyError(e));
                        }
                      },
                child: Text(
                  loading
                      ? 'Loading...'
                      : canResend
                          ? 'Kirim Kode'
                          : 'Kirim ulang dalam ${_formatTime(_resendRemaining)}',
                ),
              ),
            ),

            if (codeSent) ...[
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Kode berlaku selama:',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  Text(
                    otpExpired ? 'EXPIRED' : _formatTime(_otpRemaining),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: otpExpired ? Colors.red : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (otpExpired)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: const Text(
                    'Kode sudah kedaluwarsa. Silakan kirim ulang kode.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 12),

              TextField(
                controller: codeC,
                keyboardType: TextInputType.number,
                enabled: !otpExpired,
                decoration: const InputDecoration(
                  labelText: 'Kode (OTP)',
                  hintText: 'Masukkan kode dari email',
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: pass1C,
                enabled: !otpExpired,
                obscureText: obscure1,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  suffixIcon: IconButton(
                    icon: Icon(obscure1 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => obscure1 = !obscure1),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: pass2C,
                enabled: !otpExpired,
                obscureText: obscure2,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  suffixIcon: IconButton(
                    icon: Icon(obscure2 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => obscure2 = !obscure2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (loading || otpExpired)
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();
                          try {
                            await ref
                                .read(changePasswordControllerProvider.notifier)
                                .verifyAndChange(
                                  email: emailC.text,
                                  code: codeC.text,
                                  newPassword: pass1C.text,
                                  confirmPassword: pass2C.text,
                                );

                            snack('Password berhasil diubah.');
                            if (!mounted) return;

                            _resetOtpFlow(clearEmail: true);
                            Navigator.pop(context);
                          } catch (e) {
                            snack(_friendlyError(e));
                          }
                        },
                  child: Text(loading ? 'Loading...' : 'Ubah Password'),
                ),
              ),

              const SizedBox(height: 8),
              TextButton(
                onPressed: loading ? null : () => _resetOtpFlow(clearEmail: false),
                child: const Text('Ganti email / kirim ulang kode'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
