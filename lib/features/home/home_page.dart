// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../core/session/session_provider.dart';
// import '../../core/navigation/routes.dart';

// class HomePage extends ConsumerWidget {
//   const HomePage({super.key});

//   List<_MenuItem> _menuByRole(String role) {

//     switch (role) {
//       case 'admin':
//         return [
//           _MenuItem('Kelola User', Icons.manage_accounts, Routes.admin),
//           _MenuItem('Data Guru', Icons.badge, '/admin/data-guru'),
//           _MenuItem('Data Siswa', Icons.groups, '/admin/data-siswa'),
//           _MenuItem('Kelas & Ruang', Icons.class_, '/admin/kelas'),
//         ];

//       case 'guru':
//         return [
//           _MenuItem('Input Laporan', Icons.edit_note, '/guru/input-laporan'),
//           _MenuItem('Daftar Siswa', Icons.groups, '/guru/siswa'),
//           _MenuItem('Riwayat Laporan', Icons.history, '/guru/riwayat'),
//         ];

//       case 'kepsek':
//         return [
//           _MenuItem('Monitoring Laporan', Icons.monitor_heart, '/kepsek/monitoring'),
//           _MenuItem('Rekap Laporan', Icons.bar_chart, '/kepsek/rekap'),
//           _MenuItem('Validasi/Approval', Icons.verified, '/kepsek/approval'),
//         ];

//       case 'parent':
//       default:
//         return [
//           _MenuItem('Laporan Anak', Icons.description, '/parent/laporan'),
//           _MenuItem('Profil Anak', Icons.person, '/parent/profil-anak'),
//         ];
//     }
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final session = ref.watch(sessionProvider);
//     final role = session.role ?? 'parent';
//     final menuItems = _menuByRole(role);

//     return Scaffold(

//       endDrawer: Drawer(
//         child: SafeArea(
//           child: Column(
//             children: [
//               ListTile(
//                 title: Text(
//                   'Menu (${role.toUpperCase()})',
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(session.userId ?? ''),
//               ),
//               const Divider(),

//               Expanded(
//                 child: ListView.builder(
//                   itemCount: menuItems.length,
//                   itemBuilder: (context, i) {
//                     final item = menuItems[i];
//                     return ListTile(
//                       leading: Icon(item.icon),
//                       title: Text(item.title),
//                       onTap: () {
//                         Navigator.pop(context); 
//                         Navigator.pushNamed(context, item.route);
//                       },
//                     );
//                   },
//                 ),
//               ),

//               const Divider(),
//               ListTile(
//                 leading: const Icon(Icons.notifications),
//                 title: const Text('Notifikasi'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   Navigator.pushNamed(context, Routes.notifications);
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.logout),
//                 title: const Text('Logout'),
//                 onTap: () async {
//                   await ref.read(sessionProvider.notifier).logout();
//                   if (context.mounted) {
//                     Navigator.pushNamedAndRemoveUntil(context, Routes.gate, (_) => false);
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),

//       appBar: AppBar(
//         centerTitle: true,
//         title: const Text('Si Lapor'),

//         leading: Builder(
//           builder: (context) => IconButton(
//             icon: const Icon(Icons.menu),
//             onPressed: () => Scaffold.of(context).openEndDrawer(),
//           ),
//         ),

//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: () => Navigator.pushNamed(context, Routes.notifications),
//           ),
//         ],
//       ),

//       body: const Center(
//         child: Text('Homepage Si Lapor'),
//       ),
//     );
//   }
// }

// class _MenuItem {
//   final String title;
//   final IconData icon;
//   final String route;
//   _MenuItem(this.title, this.icon, this.route);
// }
