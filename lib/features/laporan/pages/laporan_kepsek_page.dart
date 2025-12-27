import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/laporan_kepsek_provider.dart';

class LaporanKepSekPage extends ConsumerStatefulWidget {
  const LaporanKepSekPage({super.key});

  @override
  ConsumerState<LaporanKepSekPage> createState() => _LaporanKepSekPageState();
}

class _LaporanKepSekPageState extends ConsumerState<LaporanKepSekPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController tahunPelajaranC;
  late final TextEditingController semesterC;

  @override
  void initState() {
    super.initState();
    tahunPelajaranC = TextEditingController();
    semesterC = TextEditingController();
  }

  @override
  void dispose() {
    ref.read(laporanKepsekProvider.notifier).reset();
    tahunPelajaranC.dispose();
    semesterC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(laporanKepsekProvider);
    final notifier = ref.read(laporanKepsekProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Keseluruhan')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Laporan Keseluruhan Kepala Sekolah',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: tahunPelajaranC,
                decoration: const InputDecoration(
                  labelText: 'Tahun Pelajaran',
                  hintText: '2024-2025',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: semesterC,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  hintText: '1 / 2',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: st.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(st.loading ? 'Memuat...' : 'Cek Laporan'),
                  onPressed: st.loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          await notifier.fetchSummary(
                            tahunPelajaran: tahunPelajaranC.text,
                            semester: semesterC.text,
                          );
                        },
                ),
              ),

              const SizedBox(height: 12),

              if (st.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    st.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              _SummarySectionCard(
                title: 'Reguler',
                minWajib: 2,
                memenuhi: st.memenuhiReguler,
                belum: st.belumReguler,
                items: st.summaryReguler,
              ),
              const SizedBox(height: 12),

              _SummarySectionCard(
                title: 'Tahfiz',
                minWajib: 3,
                memenuhi: st.memenuhiTahfiz,
                belum: st.belumTahfiz,
                items: st.summaryTahfiz,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummarySectionCard extends StatelessWidget {
  final String title;
  final int minWajib;
  final int memenuhi;
  final int belum;
  final List<TasmiSummary> items;

  const _SummarySectionCard({
    required this.title,
    required this.minWajib,
    required this.memenuhi,
    required this.belum,
    required this.items,
  });

  String juzRangeText(List<int> juzSelesai) {
    if (juzSelesai.isEmpty) return 'Belum ada juz selesai';
    final min = juzSelesai.first;
    final max = juzSelesai.last;
    return (min == max) ? 'Juz $min' : 'Juz $min–$max';
  }

  double _pct(int part, int total) => total == 0 ? 0 : (part / total) * 100;

  @override
Widget build(BuildContext context) {
  final total = items.length;
  final pctSelesai = _pct(memenuhi, total);
  final pctBelum = _pct(belum, total);

  return Card(
    child: ExpansionTile(
      tilePadding: const EdgeInsets.all(14),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      title: Text(
        '$title (minimal $minWajib juz selesai)',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total siswa: $total'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : (memenuhi / total),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text('✅ Sudah selesai: $memenuhi (${pctSelesai.toStringAsFixed(1)}%)'),
            Text('⏳ Belum selesai: $belum (${pctBelum.toStringAsFixed(1)}%)'),
          ],
        ),
      ),

      // LIST SISWA baru muncul saat expand
      children: [
        const Divider(height: 20),

        Row(
          children: [
            Expanded(child: _MiniStat(label: 'Memenuhi', value: memenuhi.toString())),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat(label: 'Belum', value: belum.toString())),
          ],
        ),
        const SizedBox(height: 12),

        if (items.isEmpty)
          const Text('Tidak ada data untuk filter ini.')
        else
          ...items.map((s) {
            final nama = (s.nama?.isNotEmpty == true)
                ? s.nama!
                : 'Siswa #${s.idDataSiswa}';

            final range = juzRangeText(s.juzSelesai);
            final status = s.memenuhi ? 'Memenuhi' : 'Belum';


            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(nama),
              subtitle: Text(
                    '$range • Selesai: ${s.juzSelesai.length} juz',
                  ),
              trailing: Text(status),
              // onTap: kalau mau klik siswa -> detail tasmi
              // onTap: () => Navigator.push(... TasmiDetailPage ...),
            );
          }),
      ],
    ),
  );
}
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
