import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/login_page.dart';
import 'routes.dart';
import 'session_provider.dart';

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
  bool _redirecting = false;

  void _redirectToGateOnce() {
    if (_redirecting) return;
    _redirecting = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.gate, (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    if (!session.isLoggedIn) return const LoginPage();

    if (session.role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!widget.allowedRoles.contains(session.role)) {
      _redirectToGateOnce();
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _redirecting = false;
    return widget.child;
  }
}
