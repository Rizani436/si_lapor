import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes.dart';
import '../../core/session_provider.dart';
import '../auth/presentation/login_page.dart';

class RoleGatePage extends ConsumerStatefulWidget {
  const RoleGatePage({super.key});

  @override
  ConsumerState<RoleGatePage> createState() => _RoleGatePageState();
}

class _RoleGatePageState extends ConsumerState<RoleGatePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final session = ref.read(sessionProvider);
      if (session.isLoggedIn) {
        try {
          await ref.read(sessionProvider.notifier).refreshProfile();
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    if (!session.isLoggedIn) return const LoginPage();
    if (session.role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = session.role!;
      final target = switch (role) {
        'admin' => Routes.admin,
        'guru' => Routes.guru,
        'kepsek' => Routes.kepsek,
        _ => Routes.parent,
      };

      Navigator.pushNamedAndRemoveUntil(context, target, (_) => false);
    });

    return const SizedBox.shrink();
  }
}
