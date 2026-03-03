import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/app_scaffold.dart';
import '../providers/dashboard_provider.dart';
import '../../laporan/widgets/laporan_dashboard_tile.dart';

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(siswaDashboardProvider);

    return AppScaffold(
      title: 'Dashboard Orang Tua',
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Tidak ada kelas aktif'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.kelas.namaKelas,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${item.kelas.tahunPelajaran} - Semester ${item.kelas.semester}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (item.laporanHariIni == null ||
                          item.laporanHariIni!.isEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          "Belum ada laporan hari ini",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        const Text(
                          "Laporan hari ini:",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...item.laporanHariIni!.map(
                          (laporan) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: LaporanDashboardTile(laporan: laporan),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
