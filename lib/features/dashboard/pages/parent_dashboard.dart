import 'package:flutter/material.dart';
import '../../../core/ui/app_scaffold.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Si Lapor',
      body: Center(child: Text('Dashboard Orang Tua/Siswa')),
    );
  }
}
