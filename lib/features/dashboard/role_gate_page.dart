import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes.dart';
import '../../core/session_provider.dart';
import '../auth/pages/login_page.dart';

class RoleGatePage extends ConsumerStatefulWidget {
  const RoleGatePage({super.key});

  @override
  ConsumerState<RoleGatePage> createState() => _RoleGatePageState();
}

class _RoleGatePageState extends ConsumerState<RoleGatePage> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    // Belum login -> ke Login
    if (!session.isLoggedIn) {
      _navigated = false; // reset kalau user logout lalu balik lagi
      return const LoginPage();
    }

    // Role belum kebaca -> loading
    if (session.role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ Redirect hanya sekali
    if (!_navigated) {
      _navigated = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final role = session.role!;
        final target = switch (role) {
          'admin' => Routes.admin,
          'guru' => Routes.guru,
          'kepsek' => Routes.kepsek,
          _ => Routes.parent,
        };

        Navigator.pushNamedAndRemoveUntil(context, target, (_) => false);
      });
    }

    return const SizedBox.shrink();
  }
}
