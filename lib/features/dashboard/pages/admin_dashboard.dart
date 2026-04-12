import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/app_scaffold.dart';
import '../providers/dashboard_provider.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardCountProvider);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
            return RefreshIndicator(
              onRefresh: () async {
                await ref.refresh(dashboardCountProvider.future);
              },
              child: GridView.count(
                physics: const AlwaysScrollableScrollPhysics(),
                // LOGIKA RESPONSIF: 4 kolom saat landscape, 2 saat portrait
                crossAxisCount: isLandscape ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                // Rasio disesuaikan agar kotak tidak terlalu panjang ke bawah
                childAspectRatio: isLandscape ? 1.1 : 0.8,
                children: [
                  _DashboardCard(
                    title: 'Ruang Kelas',
                    total: data['ruangkelas'] ?? 0,
                    icon: Icons.meeting_room,
                    filterProvider: ruangkelasFilterProvider,
                  ),
                  _DashboardCard(
                    title: 'Data Siswa',
                    total: data['datasiswa'] ?? 0,
                    icon: Icons.people,
                    filterProvider: datasiswaFilterProvider,
                  ),
                  _DashboardCard(
                    title: 'Data Guru',
                    total: data['dataguru'] ?? 0,
                    icon: Icons.person,
                    filterProvider: dataguruFilterProvider,
                  ),
                  _DashboardCard(
                    title: 'Profiles',
                    total: data['profiles'] ?? 0,
                    icon: Icons.account_circle,
                    filterProvider: profilesFilterProvider,
                  ),
                ],
              ),
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
    // Gunakan watch agar widget rebuild saat filter berubah
    final selectedStatus = ref.watch(filterProvider);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF27AE60).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bagian Atas: Judul & Dropdown
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              // Dropdown Styling
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                    0.9,
                  ), // Sedikit transparan lebih modern
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Colors.black87,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                      DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                      DropdownMenuItem(
                        value: 'Tidak Aktif',
                        child: Text('Nonaktif'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(filterProvider.notifier).setStatus(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          // Bagian Bawah: Icon & Angka
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 4),
              FittedBox(
                // Mencegah text overflow jika angka terlalu panjang
                child: Text(
                  total.toString(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Text(
                'Total Data',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white70, // Menggunakan putih yang lebih soft
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
