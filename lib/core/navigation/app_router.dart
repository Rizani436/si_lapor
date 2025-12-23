import 'package:flutter/material.dart';
import 'package:si_lapor/features/siswa/pages/siswa_list_page.dart';
import 'routes.dart';
import 'route_guards.dart';

import '../../features/dashboard/role_gate_page.dart';
import '../../features/dashboard/pages/admin_dashboard.dart';
import '../../features/dashboard/pages/teacher_dashboard.dart';
import '../../features/dashboard/pages/parent_dashboard.dart';
import '../../features/dashboard/pages/kepsek_dashboard.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/akun/pages/akun_list_page.dart';
import '../../features/guru/pages/guru_list_page.dart';
import '../../features/kelas/pages/kelas_list_page.dart';
import '../../features/profile/pages/profile_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.gate:
        return MaterialPageRoute(builder: (_) => const RoleGatePage());

      case Routes.admin:
        return MaterialPageRoute(
          builder: (_) => const GuardedPage(
            allowedRoles: ['admin'],
            child: AdminDashboard(),
          ),
        );

      case Routes.adminAkun:
        return MaterialPageRoute(
          builder: (_) =>
              const GuardedPage(allowedRoles: ['admin'], child: AkunListPage()),
        );
      case Routes.adminSiswa:
        return MaterialPageRoute(
          builder: (_) => const GuardedPage(
            allowedRoles: ['admin'],
            child: SiswaListPage(),
          ),
        );
      case Routes.adminGuru:
        return MaterialPageRoute(
          builder: (_) =>
              const GuardedPage(allowedRoles: ['admin'], child: GuruListPage()),
        );
      case Routes.adminKelas:
        return MaterialPageRoute(
          builder: (_) => const GuardedPage(
            allowedRoles: ['admin'],
            child: KelasListPage(),
          ),
        );
      case Routes.guru:
        return MaterialPageRoute(
          builder: (_) => const GuardedPage(
            allowedRoles: ['guru'],
            child: TeacherDashboard(),
          ),
        );

      case Routes.kepsek:
        return MaterialPageRoute(
          builder: (_) => const GuardedPage(
            allowedRoles: ['kepsek'],
            child: KepsekDashboard(),
          ),
        );

      case Routes.parent:
        return MaterialPageRoute(
          builder: (_) => const GuardedPage(
            allowedRoles: ['parent'],
            child: ParentDashboard(),
          ),
        );

      case Routes.notifications:
        return MaterialPageRoute(
          builder: (_) => const GuardedPage(
            allowedRoles: ['admin', 'guru', 'parent', 'kepsek'],
            child: NotificationsPage(),
          ),
        );
      case Routes.profile:
        return MaterialPageRoute(
          builder: (_) => const GuardedPage(
            allowedRoles: ['admin', 'guru', 'parent', 'kepsek'],
            child: ProfilePage(),
          ),
        );
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case Routes.register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      default:
        return MaterialPageRoute(builder: (_) => const RoleGatePage());
    }
  }
}
