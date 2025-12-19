import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../routes.dart';
import '../session_provider.dart';

class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;

  const AppScaffold({super.key, required this.title, required this.body});

  List<_MenuItem> _menuByRole(String role) {
    switch (role) {
      case 'admin':
        return [
          _MenuItem('Dashboard Admin', Routes.admin),
          _MenuItem('Kelola Akun', '/admin/akun'),
          _MenuItem('Kelola Siswa', '/admin/siswa'),
          _MenuItem('Kelola Kelas', '/admin/kelas'),
          _MenuItem('Profile', '/admin/profile'),
        ];
      case 'guru':
        return [
          _MenuItem('Dashboard Guru', Routes.guru),
          _MenuItem('Input Laporan', '/guru/input-laporan'),
          _MenuItem('Profile', '/guru/profile'),
        ];
      case 'kepsek':
        return [
          _MenuItem('Dashboard Kepsek', Routes.kepsek),
          _MenuItem('Monitoring', '/kepsek/monitoring'),
          _MenuItem('Profile', '/kepsek/profile'),
        ];
      case 'parent':
      default:
        return [
          _MenuItem('Dashboard Orang Tua', Routes.parent),
          _MenuItem('Laporan Anak', '/parent/laporan'),
          _MenuItem('Profile', '/parent/profile'),
        ];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final role = (session.role ?? 'parent').toLowerCase();
    final menu = _menuByRole(role);

    final fotoProfile = session.fotoProfile;
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
                        child: (fotoProfile != null && fotoProfile.isNotEmpty)
                            ? Image.network(
                                fotoProfile,
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
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, item.route);
                        },
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
                onTap: () async {
                  Navigator.pop(context); 
                  await ref.read(sessionProvider.notifier).logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routes.login,
                    (_) => false,
                  );
                },
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
            onPressed: () => Navigator.pushNamed(context, Routes.notifications),
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
