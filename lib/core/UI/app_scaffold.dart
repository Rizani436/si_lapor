import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../routes.dart';
import '../session_provider.dart';

class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  List<_MenuItem> _menuByRole(String role) {
    switch (role) {
      case 'admin':
        return [
          _MenuItem('Dashboard Admin', Icons.dashboard, Routes.admin),
          _MenuItem('Kelola User', Icons.manage_accounts, '/admin/users'),
        ];
      case 'guru':
        return [
          _MenuItem('Dashboard Guru', Icons.dashboard, Routes.guru),
          _MenuItem('Input Laporan', Icons.edit_note, '/guru/input-laporan'),
        ];
      case 'kepsek':
        return [
          _MenuItem('Dashboard Kepsek', Icons.dashboard, Routes.kepsek),
          _MenuItem('Monitoring', Icons.monitor_heart, '/kepsek/monitoring'),
        ];
      case 'parent':
      default:
        return [
          _MenuItem('Dashboard Orang Tua', Icons.dashboard, Routes.parent),
          _MenuItem('Laporan Anak', Icons.description, '/parent/laporan'),
        ];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final role = session.role ?? 'parent';
    final menu = _menuByRole(role);

    return Scaffold(

      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                title: Text(
                  'Menu (${role.toUpperCase()})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(session.userId ?? ''),
              ),
              const Divider(),

              Expanded(
                child: ListView(
                  children: [
                    for (final item in menu)
                      ListTile(
                        leading: Icon(item.icon),
                        title: Text(item.title),
                        onTap: () {
                          Navigator.pop(context); // tutup drawer
                          Navigator.pushNamed(context, item.route);
                        },
                      ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notifikasi'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, Routes.notifications);
                      },
                    ),
                  ],
                ),
              ),

              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await ref.read(sessionProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, Routes.gate, (_) => false);
                  }
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
  final IconData icon;
  final String route;
  _MenuItem(this.title, this.icon, this.route);
}
