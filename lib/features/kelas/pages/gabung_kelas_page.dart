import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gabung_kelas_provider.dart';
import '../pages/kelas_list_siswa_page.dart';
import '../providers/kelas_siswa_provider.dart';

class GabungKelasPage extends ConsumerStatefulWidget {
  const GabungKelasPage({super.key});

  @override
  ConsumerState<GabungKelasPage> createState() => _GabungKelasPageState();
}

class _GabungKelasPageState extends ConsumerState<GabungKelasPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController kodeKelasC;

  @override
  void initState() {
    super.initState();
    kodeKelasC = TextEditingController(text: '');
  }

  @override
  void dispose() {
    ref.read(gabungKelasProvider.notifier).reset();
    kodeKelasC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(gabungKelasProvider);
    final notifier = ref.read(gabungKelasProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Gabung Kelas')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Kode Kelas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: kodeKelasC,
                decoration: const InputDecoration(
                  hintText: 'RK-004H',
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
                  label: Text(st.loading ? 'Mengecek...' : 'Gabung Kelas'),
                  onPressed: st.loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          await notifier.cekKodeKelas(kodeKelasC.text);
                        },
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _ResultCard(st: st, notifier: notifier),
                ),
              ),

              const SizedBox(height: 12),

              if (st.idRuangKelas != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: st.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      st.loading ? 'Menyimpan...' : 'Konfirmasi Gabung',
                    ),
                    onPressed: st.loading
                        ? null
                        : () async {
                            await notifier.konfirmasiGabung();
                            final latest = ref.read(gabungKelasProvider);

                            if (!context.mounted) return;

                            if (latest.error == null) {
                              kodeKelasC.clear();
                              notifier.reset();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Berhasil gabung kelas!'),
                                ),
                              );
                              await ref.read(kelasSiswaListProvider.notifier).refresh();


                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const KelasListSiswaPage(),
                                ),
                              );
                            }
                          },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final GabungKelasState st;
  final GabungKelasNotifier notifier;

  const _ResultCard({required this.st, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (st.error != null) {
      return Text(
        'Error:\n${st.error}',
        style: const TextStyle(color: Colors.red),
      );
    }

    if (!st.checked) {
      return const Text('Masukkan kode kelas lalu tekan "Gabung Kelas".');
    }

    if (st.notFound) {
      return const Text(
        'Kelas tidak ada.',
        style: TextStyle(fontWeight: FontWeight.w600),
      );
    }

    if (st.idRuangKelas == null) {
      return const Text('Belum ada hasil.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kelas ditemukan ✅ (id_ruang_kelas: ${st.idRuangKelas})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pilih salah satu data siswa:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (st.siswaList.isEmpty)
          const Text('Tidak ada data siswa untuk dipilih.')
        else
          ...st.siswaList.map((s) {
            return RadioListTile<int>(
              value: s.idDataSiswa,
              groupValue: st.selectedIdDataSiswa,
              title: Text(
                s.namaLengkap.isNotEmpty ? s.namaLengkap : '(Tanpa nama)',
              ),
              onChanged: (v) {
                if (v != null) notifier.pilihSiswa(v);
              },
            );
          }),
      ],
    );
  }
}
