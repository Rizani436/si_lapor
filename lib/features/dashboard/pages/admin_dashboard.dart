import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/app_scaffold.dart';
import '../providers/dashboard_provider.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardCountProvider);

    return AppScaffold(
      title: 'Dashboard Admin',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Terjadi kesalahan:\n$e', textAlign: TextAlign.center),
          ),
          data: (data) {
            return GridView.count(
              
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: [
                _DashboardCard(
                  title: 'Ruang Kelas',
                  total: data['ruangkelas']!,
                  icon: Icons.meeting_room,
                  filterProvider: ruangkelasFilterProvider,
                ),
                _DashboardCard(
                  title: 'Data Siswa',
                  total: data['datasiswa']!,
                  icon: Icons.people,
                  filterProvider: datasiswaFilterProvider,
                ),
                _DashboardCard(
                  title: 'Data Guru',
                  total: data['dataguru']!,
                  icon: Icons.person,
                  filterProvider: dataguruFilterProvider,
                ),
                _DashboardCard(
                  title: 'Profiles',
                  total: data['profiles']!,
                  icon: Icons.account_circle,
                  filterProvider: profilesFilterProvider,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardCard extends ConsumerWidget {
  final String title;
  final int total;
  final IconData icon;
  final NotifierProvider<StatusFilterNotifier, String> filterProvider;

  const _DashboardCard({
    required this.title,
    required this.total,
    required this.icon,
    required this.filterProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(filterProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: 120,
                height: 34,
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      isDense: true,
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                      items: const [
                        DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                        DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                        DropdownMenuItem(
                          value: 'Tidak Aktif',
                          child: Text('Nonaktif'),
                        ),
                      ],
                      onChanged: (value) {
                        ref.read(filterProvider.notifier).setStatus(value!);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          Column(
            children: [
              Icon(icon, size: 40, color: Colors.white),

              const SizedBox(height: 8),

              Text(
                total.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Total Data',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
