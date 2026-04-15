import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/app_scaffold.dart';
import '../providers/dashboard_provider.dart';

class KepsekDashboard extends ConsumerStatefulWidget {
  const KepsekDashboard({super.key});

  @override
  ConsumerState<KepsekDashboard> createState() => _KepsekDashboardState();
}

class _KepsekDashboardState extends ConsumerState<KepsekDashboard> {
  late final TextEditingController tahunPelajaranC;
  late final TextEditingController semesterC;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    String initialTahun;
    String initialSemester;

    if (month >= 7) {
      initialTahun = "$year-${year + 1}";
      initialSemester = "1";
    } else {
      initialTahun = "${year - 1}-$year";
      initialSemester = "2";
    }

    tahunPelajaranC = TextEditingController(text: initialTahun);
    semesterC = TextEditingController(text: initialSemester);
  }

  @override
  void dispose() {
    tahunPelajaranC.dispose();
    semesterC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int semesterInt = int.tryParse(semesterC.text) ?? 1;
    final dashboardAsync = ref.watch(
      kepsekDashboardProvider((
        tahun: tahunPelajaranC.text,
        semester: semesterInt,
      )),
    );

    return AppScaffold(
      title: 'Dashboard Kepsek',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 45,
                    child: TextField(
                      controller: tahunPelajaranC,
                      onChanged: (val) => setState(() {}),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Tahun',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 45,
                    child: TextField(
                      controller: semesterC,
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setState(() {}),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Smt',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: dashboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                return RefreshIndicator(
                  onRefresh: () async {

                    ref.invalidate(kepsekDashboardProvider);
                  },
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 200),
                            Center(child: Text('Tidak ada laporan ditemukan')),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                                      "Guru: ${item.guru}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Divider(height: 20),

                                    Text(
                                      "Laporan hari ini yang belum: ${item.siswaBelumUpload.length}",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    if (item.siswaBelumUpload.isEmpty)
                                      const Text(
                                        "Semua siswa sudah setor",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 13,
                                        ),
                                      )
                                    else
                                      ...item.siswaBelumUpload.map(
                                        (s) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          child: Text(
                                            "- ${s['datasiswa']?['nama_lengkap'] ?? '-'}",
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
