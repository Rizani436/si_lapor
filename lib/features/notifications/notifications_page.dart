import 'package:flutter/material.dart';
import '../../core/ui/app_scaffold.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Si Lapor',
      body: Center(child: Text('Halaman Notifikasi')),
    );
  }
}
