import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gabung_kelas_provider(guru).dart';
import 'kelas_list_guru_page(guru).dart';
import '../providers/kelas_siswa_provider.dart';
import '../widgets/result_card_guru.dart';

class GabungKelasPageGuru extends ConsumerStatefulWidget {
  const GabungKelasPageGuru({super.key});

  @override
  ConsumerState<GabungKelasPageGuru> createState() => _GabungKelasPageGuruState();
}

class _GabungKelasPageGuruState extends ConsumerState<GabungKelasPageGuru> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController kodeKelasC;

  @override
  void initState() {
    super.initState();
    kodeKelasC = TextEditingController(text: '');
  }

  @override
  void dispose() {
    ref.read(gabungKelasProviderGuru.notifier).reset();
    kodeKelasC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(gabungKelasProviderGuru);
    final notifier = ref.read(gabungKelasProviderGuru.notifier);

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
                  child: ResultCardGuru(st: st, notifier: notifier),
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
                            final latest = ref.read(gabungKelasProviderGuru);

                            if (!context.mounted) return;

                            if (latest.error == null) {
                              kodeKelasC.clear();
                              notifier.reset();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Berhasil gabung kelas!'),
                                ),
                              );
                              
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const KelasListGuruPage(),
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
