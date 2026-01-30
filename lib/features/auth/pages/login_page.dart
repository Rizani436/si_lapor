import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/gestures.dart';

import '../providers/auth_provider.dart';
import 'change_password_page.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/navigation/routes.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool obscurePassword = true;

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authLoginControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passC,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                ),
              ),
            ),
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: RichText(
            //     text: TextSpan(
            //       text: 'Lupa Password',
            //       style: const TextStyle(
            //         color: Colors.blue,
            //         fontWeight: FontWeight.bold,
            //         decoration: TextDecoration.underline,
            //       ),
            //       recognizer: TapGestureRecognizer()
            //         ..onTap = () {
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (_) => const ChangePasswordPage(),
            //             ),
            //           );
            //         },
            //     ),
            //   ),
            // ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        FocusScope.of(context).unfocus();

                        final email = emailC.text.trim();
                        final pass = passC.text;

                        if (email.isEmpty || pass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email dan password wajib diisi.'),
                            ),
                          );
                          return;
                        }
                        if (pass.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password minimal 8 karakter.'),
                            ),
                          );
                          return;
                        }

                        try {
                          await ref
                              .read(authLoginControllerProvider.notifier)
                              .login(email, pass);
                          try {
                            await ref
                                .read(sessionProvider.notifier)
                                .refreshProfile();
                          } catch (_) {}

                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            Routes.gate,
                            (_) => false,
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                child: Text(isLoading ? 'Loading...' : 'Login'),
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                text: 'Belum punya akun? ',
                style: const TextStyle(color: Colors.black54),
                children: [
                  TextSpan(
                    text: 'Register',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pushNamed(context, Routes.register);
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
