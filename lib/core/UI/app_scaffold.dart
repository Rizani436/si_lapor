import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../navigation/routes.dart';
import '../session/session_provider.dart';
import '../navigation/navigator_key.dart'; 

class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;

  const AppScaffold({super.key, required this.title, required this.body});

  List<_MenuItem> _menuByRole(String role) {
    switch (role) {
      case 'admin':
        return [
          _MenuItem('Kelola Akun', '/admin/akun'),
          _MenuItem('Kelola Siswa', '/admin/siswa'),
          _MenuItem('Kelola Guru', '/admin/guru'),
          _MenuItem('Kelola Kelas', '/admin/kelas'),
          _MenuItem('Profile', '/profile'),
        ];
      case 'guru':
        return [
          _MenuItem('Input Laporan', '/guru/input-laporan'),
          _MenuItem('Profile', '/profile'),
        ];
      case 'kepsek':
        return [
          _MenuItem('Monitoring', '/kepsek/monitoring'),
          _MenuItem('Profile', '/profile'),
        ];
      case 'parent':
      default:
        return [
          _MenuItem('Laporan Anak', '/parent/laporan'),
          _MenuItem('Profile', '/profile'),
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
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade300,
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
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Menu (${role.toUpperCase()})',
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (userId.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              userId,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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
              const Divider(),

              Expanded(
                child: ListView(
                  children: [
                    for (final item in menu)
                      ListTile(
                        title: Text(item.title),
                        trailing: const Text(
                          '>',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        onTap: () => _navTo(item.route),
                      ),
                  ],
                ),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                trailing: const Text(
                  '>',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                onTap: () => _logout(ref),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () =>
                navigatorKey.currentState?.pushNamed(Routes.notifications),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _MenuItem {
  final String title;
  final String route;
  _MenuItem(this.title, this.route);
}
