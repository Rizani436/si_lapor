import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'register_page.dart';
import '../../../core/session_provider.dart';
import '../../dashboard/role_gate_page.dart';
import '../../../core/routes.dart';
import 'package:flutter/gestures.dart';

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
    final state = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.gate, 
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
      appBar: AppBar(title: const Text('Login'), centerTitle: true),

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
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
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

                        ref
                            .read(authControllerProvider.notifier)
                            .login(email, pass);
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
