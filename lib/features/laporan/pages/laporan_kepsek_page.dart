import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/laporan_kepsek_provider.dart';
import '../widgets/widgets_laporan_helper.dart'; 

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

              SummarySectionCard(
                title: 'Reguler',
                minWajib: 2,
                memenuhi: st.memenuhiReguler,
                belum: st.belumReguler,
                items: st.summaryReguler,
              ),
              const SizedBox(height: 12),

              SummarySectionCard(
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
