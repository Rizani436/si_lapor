import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guru_model.dart';
import '../providers/guru_provider.dart';

class GuruFormPage extends ConsumerStatefulWidget {
  final GuruModel? existing;
  const GuruFormPage({super.key, this.existing});

  @override
  ConsumerState<GuruFormPage> createState() => _GuruFormPageState();
}

class _GuruFormPageState extends ConsumerState<GuruFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController namaC;
  late final TextEditingController nipC;
  late final TextEditingController alamatC;

  String jk = 'L';
  bool aktif = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;

    namaC = TextEditingController(text: s?.namaLengkap ?? '');
    nipC = TextEditingController(text: s?.nip ?? '');
    alamatC = TextEditingController(text: s?.alamat ?? '');

    jk = s?.jenisKelamin ?? 'L';
    aktif = (s?.ketAktif ?? 1) == 1;
  }

  @override
  void dispose() {
    namaC.dispose();
    nipC.dispose();
    alamatC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Guru' : 'Tambah Guru')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: namaC,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: nipC,
                decoration: const InputDecoration(
                  labelText: 'NIS',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: alamatC,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: jk,
                decoration: const InputDecoration(
                  labelText: 'Jenip Kelamin',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'L', child: Text('Laki-laki (L)')),
                  DropdownMenuItem(value: 'P', child: Text('Perempuan (P)')),
                ],
                onChanged: (v) => setState(() => jk = v ?? 'L'),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: aktif,
                onChanged: (v) => setState(() => aktif = v),
                title: const Text('Status Aktif'),
                subtitle: Text(aktif ? 'Aktif' : 'Nonaktif'),
              ),

              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!(_formKey.currentState?.validate() ?? false)) return;

                          setState(() => saving = true);
                          try {
                            final payload = GuruModel(
                              idDataGuru: widget.existing?.idDataGuru ?? 0,
                              namaLengkap: namaC.text.trim(),
                              nip: nipC.text.trim(),
                              alamat: alamatC.text.trim(),
                              jenisKelamin: jk,
                              ketAktif: aktif ? 1 : 0,
                            );

                            final notifier = ref.read(guruListProvider.notifier);

                            if (isEdit) {
                              await notifier.edit(widget.existing!.idDataGuru, payload);
                            } else {
                              await notifier.add(payload);
                            }

                            if (mounted) Navigator.pop(context, true);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal: $e')),
                            );
                          } finally {
                            if (mounted) setState(() => saving = false);
                          }
                        },
                  child: Text(saving ? 'Menyimpan...' : 'Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
