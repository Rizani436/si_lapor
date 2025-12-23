import 'package:flutter/material.dart';
import '../../../core/ui/app_scaffold.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Si Lapor',
      body: Center(child: Text('Dashboard Guru')),
    );
  }
}
