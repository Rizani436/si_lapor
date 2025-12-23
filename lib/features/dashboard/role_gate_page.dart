import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes.dart';
import '../../core/session_provider.dart';

class RoleGatePage extends ConsumerStatefulWidget {
  const RoleGatePage({super.key});

  @override
  ConsumerState<RoleGatePage> createState() => _RoleGatePageState();
}

class _RoleGatePageState extends ConsumerState<RoleGatePage> {
  bool _redirected = false;
  late final ProviderSubscription _sub;
  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual(sessionProvider, (prev, next) {
      _scheduleRedirect(next);
    });

    // juga cek awal setelah build pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleRedirect(ref.read(sessionProvider));
    });
  }

  @override
  void dispose() {
    _sub.close(); // ✅
    super.dispose();
  }

  void _scheduleRedirect(SessionState s) {
    if (_redirected) return;

    final target = _targetRoute(s);
    if (target == null) return;

    _redirected = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(target, (_) => false);
    });
  }

  String? _targetRoute(SessionState s) {
    if (!s.isLoggedIn) return Routes.login;

    final role = (s.role ?? 'parent').toLowerCase();
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

  @override
  Widget build(BuildContext context) {
    // Jangan ada Navigator / SnackBar / Dialog di build
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
