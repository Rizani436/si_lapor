import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_provider.dart';
import '../features/auth/presentation/login_page.dart';

class GuardedPage extends ConsumerWidget {
  final List<String> allowedRoles;
  final Widget child;

  const GuardedPage({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    if (!session.isLoggedIn) return const LoginPage();

    if (session.role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!allowedRoles.contains(session.role)) {
      return const Scaffold(body: Center(child: Text('Akses ditolak (role tidak sesuai)')));
    }

    return child;
  }
}
