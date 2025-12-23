import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';
import '../session/session_provider.dart';

class GuardedPage extends ConsumerStatefulWidget {
  final List<String> allowedRoles;
  final Widget child;

  const GuardedPage({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  @override
  ConsumerState<GuardedPage> createState() => _GuardedPageState();
}

class _GuardedPageState extends ConsumerState<GuardedPage> {
  bool _redirected = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    // Belum login -> arahkan ke login (sekali)
    if (!session.isLoggedIn) {
      _scheduleRedirect(context, Routes.login);
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = (session.role ?? 'parent').toLowerCase();

    // Role tidak sesuai -> arahkan ke dashboard role masing-masing (sekali)
    if (!widget.allowedRoles.map((e) => e.toLowerCase()).contains(role)) {
      final target = _dashboardRouteByRole(role);
      _scheduleRedirect(context, target);
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Role sesuai -> tampilkan halaman
    _redirected = false; // reset jika sudah aman
    return widget.child;
  }

  void _scheduleRedirect(BuildContext context, String route) {
    if (_redirected) return;
    _redirected = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Pakai pushNamedAndRemoveUntil agar tidak numpuk halaman
      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    });
  }

  String _dashboardRouteByRole(String role) {
    switch (role) {
      case 'admin':
        return Routes.admin;
      case 'guru':
        return Routes.guru;
      case 'kepsek':
        return Routes.kepsek;
      case 'parent':
      default:
        return Routes.parent;
    }
  }
}
