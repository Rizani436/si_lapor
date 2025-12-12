import 'package:flutter/material.dart';
import 'routes.dart';
import 'route_guards.dart';

import '../features/dashboard/role_gate_page.dart';
import '../features/dashboard/admin_dashboard.dart';
import '../features/dashboard/teacher_dashboard.dart';
import '../features/dashboard/parent_dashboard.dart';
import '../features/dashboard/kepsek_dashboard.dart';
import '../features/notifications/notifications_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';

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
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case Routes.register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      default:
        return MaterialPageRoute(builder: (_) => const RoleGatePage());
    }
  }
}
