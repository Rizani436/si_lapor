import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../providers/auth_provider.dart';
import '../../../core/routes.dart';
import 'package:flutter/gestures.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final namaC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final pass2C = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String? phoneE164;

  @override
  void dispose() {
    namaC.dispose();
    emailC.dispose();
    passC.dispose();
    pass2C.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {

    final r = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return r.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Register berhasil ✅ Silakan login.')),
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.login,
            (_) => false,
          );
        },
        error: (e, _) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        },
      );
    });

    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: namaC,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                hintText: 'Contoh: Rizal Dwi Kurniawan',
              ),
            ),
            const SizedBox(height: 12),

            IntlPhoneField(
              initialCountryCode: 'ID', // tetap default +62
              showCountryFlag: false, // ✅ bendera di field HILANG
              showDropdownIcon: true, // dropdown tetap ada untuk pilih kode
              decoration: const InputDecoration(
                labelText: 'Nomor HP',
                hintText: '81234567890',
              ),
              onChanged: (phone) {
                phoneE164 = phone.completeNumber; 
              },
            ),

            const SizedBox(height: 12),
            TextField(
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'contoh@gmail.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passC,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'minimal 8 karakter',
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: pass2C,
              obscureText: obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureConfirmPassword = !obscureConfirmPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        final nama = namaC.text.trim();
                        final email = emailC.text.trim();
                        final p1 = passC.text;
                        final p2 = pass2C.text;

                        if (nama.isEmpty ||
                            email.isEmpty ||
                            p1.isEmpty ||
                            p2.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Semua field wajib diisi.'),
                            ),
                          );
                          return;
                        }

                        if (!_isValidEmail(email)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Format email tidak valid.'),
                            ),
                          );
                          return;
                        }

                        if (phoneE164 == null || phoneE164!.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nomor HP wajib diisi.'),
                            ),
                          );
                          return;
                        }

                        if (p1 != p2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password tidak sama.'),
                            ),
                          );
                          return;
                        }

                        if (p1.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password minimal 8 karakter.'),
                            ),
                          );
                          return;
                        }

                        ref
                            .read(authControllerProvider.notifier)
                            .register(
                              namaLengkap: nama,
                              noHp: phoneE164!, 
                              email: email,
                              password: p1,
                            );
                      },
                child: Text(isLoading ? 'Loading...' : 'Register'),
              ),
            ),

            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                text: 'Sudah punya akun? ',
                style: const TextStyle(color: Colors.black54),
                children: [
                  TextSpan(
                    text: 'Login',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pushNamed(context, Routes.login);
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
