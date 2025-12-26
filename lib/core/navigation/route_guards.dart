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

    if (!session.isLoggedIn) {
      _scheduleRedirect(context, Routes.login);
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = (session.role ?? '').toLowerCase();

    if (!widget.allowedRoles.map((e) => e.toLowerCase()).contains(role)) {
      final target = _dashboardRouteByRole(role);
      _scheduleRedirect(context, target);
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _redirected = false;
    return widget.child;
  }

  void _scheduleRedirect(BuildContext context, String route) {
    if (_redirected) return;
    _redirected = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
        return Routes.parent;
      default:
        return Routes.login;
    }
  }
}
