import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';

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
      _maybeRedirect(next);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRedirect(ref.read(sessionProvider));
    });
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }

  void _maybeRedirect(SessionState s) {
    if (_redirected) return;

    if (s.isBootstrapping) return;
    if (s.isOffline) return;

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

    final role = (s.role ?? '').toLowerCase();
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);

    if (s.isBootstrapping) {
      return const BootLoadingPage();
    }

    if (s.isOffline) {
      return NoInternetPage(
        message: s.offlineMessage,
        onRetry: () async {
          _redirected = false; 
          await ref.read(sessionProvider.notifier).bootstrap();
          if (!mounted) return;
          _maybeRedirect(ref.read(sessionProvider));
        },
      );
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class BootLoadingPage extends StatelessWidget {
  const BootLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Menyiapkan aplikasi...'),
          ],
        ),
      ),
    );
  }
}

class NoInternetPage extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const NoInternetPage({super.key, required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.error.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 72,
                  color: theme.colorScheme.error,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Koneksi Terputus',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                message ??
                    'Kami tidak dapat terhubung ke internet.\nPeriksa koneksi Anda lalu coba lagi.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
