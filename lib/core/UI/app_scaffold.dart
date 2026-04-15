import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/routes.dart';
import '../session/session_provider.dart';
import '../navigation/navigator_key.dart';
import '../network/net_status_provider.dart';
import '../../features/notifications/providers/notif_polling_provider.dart';
import '../../features/device/fcm_service.dart';

import '../../features/notifications/providers/notifikasi_provider.dart';

class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;

  const AppScaffold({super.key, required this.title, required this.body});

  List<_MenuItem> _menuByRole(String role) {
    switch (role) {
      case 'admin':
        return [
          _MenuItem('Kelola Akun', '/admin/akun', Icons.manage_accounts),
          _MenuItem('Kelola Siswa', '/admin/siswa', Icons.people),
          _MenuItem('Kelola Guru', '/admin/guru', Icons.school),
          _MenuItem('Kelola Kelas', '/admin/kelas', Icons.class_rounded),
          _MenuItem('Profile', '/profile', Icons.account_circle),
        ];
      case 'guru':
        return [
          _MenuItem('Kelas Al-Qur\'an', '/guru/kelas', Icons.class_rounded),
          _MenuItem('Profile', '/profile', Icons.account_circle),
        ];
      case 'kepsek':
        return [
          _MenuItem('Rekap Laporan', '/kepsek/laporan', Icons.assignment),
          _MenuItem('Profile', '/profile', Icons.account_circle),
        ];
      case 'parent':
      default:
        return [
          _MenuItem('Kelas Al-Qur\'an', '/parent/kelas', Icons.class_rounded),
          _MenuItem('Profile', '/profile', Icons.account_circle),
        ];
    }
  }

  void _navTo(String route) {
    navigatorKey.currentState?.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamed(route);
    });
  }

  Future<void> _logout(WidgetRef ref) async {
    navigatorKey.currentState?.pop();
    await FcmService().hapusToken();
    await ref.read(sessionProvider.notifier).logout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.login,
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final role = (session.role ?? 'parent').toLowerCase();
    final menu = _menuByRole(role);

    final fotoProfile = session.fotoProfile;
    final v = session.avatarVersion;

    final fotoProfileUrl = (fotoProfile != null && fotoProfile.isNotEmpty)
        ? '$fotoProfile?v=$v'
        : null;

    final namaLengkap = session.namaLengkap;
    final userId = session.userId ?? '';

    final netAsync = ref.watch(netStatusProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width:
                  double.infinity,
              color: const Color(0xFF27AE60),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top,
                  16,
                  16,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: ClipOval(
                        child: (fotoProfileUrl != null)
                            ? Image.network(
                                fotoProfileUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (namaLengkap != null && namaLengkap.isNotEmpty)
                                ? namaLengkap
                                : 'Nama belum diatur',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Menu (${role.toUpperCase()})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          if (userId.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              userId,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
          
                color: const Color(0xFFF5F8EC),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets
                            .zero, 
                        children: [
                          for (final item in menu)
                            ListTile(
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onTap: () => _navTo(item.route),
                            ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () => _logout(ref),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(title),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unreadAsync = ref.watch(notifUnreadPollingProvider);

              return unreadAsync.when(
                data: (count) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications),
                        onPressed: () {
                          ref.invalidate(notifikasiListProvider);
                          ref.invalidate(notifikasiUnreadCountProvider);

                          navigatorKey.currentState?.pushNamed(
                            Routes.notifications,
                          );
                        },
                      ),

                      if (count > 0)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => navigatorKey.currentState?.pushNamed(
                    Routes.notifications,
                  ),
                ),
                error: (_, __) => IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => navigatorKey.currentState?.pushNamed(
                    Routes.notifications,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
          netAsync.when(
            data: (net) {
              if (net == NetStatus.online) return const SizedBox.shrink();

              return MaterialBanner(
                leading: const Icon(Icons.wifi_off_rounded),
                content: const Text(
                  'Internet terputus. Beberapa fitur mungkin tidak berjalan.',
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final ctrl = ref.read(sessionProvider.notifier);
                      if (ctrl is dynamic) {
                        try {
                          await ctrl.bootstrap();
                        } catch (_) {}
                      }
                    },
                    child: const Text('Coba lagi'),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(netStatusProvider);
                    },
                    child: const Text('Tutup'),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String route;
  final IconData icon;
  _MenuItem(this.title, this.route, this.icon);
}
