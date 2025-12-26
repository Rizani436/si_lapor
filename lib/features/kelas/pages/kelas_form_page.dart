import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kelas_model.dart';
import '../providers/kelas_provider.dart';

class KelasFormPage extends ConsumerStatefulWidget {
  final KelasModel? existing;
  const KelasFormPage({super.key, this.existing});

  @override
  ConsumerState<KelasFormPage> createState() => _KelasFormPageState();
}

class _KelasFormPageState extends ConsumerState<KelasFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController namaKelasC;
  late final TextEditingController tahunPelajaranC;
  late final TextEditingController semesterC;

  int idKelas = 0;
  String jk = 'Reguler';
  bool aktif = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;

    namaKelasC = TextEditingController(text: s?.namaKelas ?? '');
    tahunPelajaranC = TextEditingController(text: s?.tahunPelajaran ?? '');
    semesterC = TextEditingController(text: s?.semester.toString() ?? '');

    idKelas = s?.idKelas ?? 0;
    jk = s?.jenisKelas ?? 'Reguler';
    aktif = (s?.ketAktif ?? 1) == 1;
  }

  @override
  void dispose() {
    namaKelasC.dispose();
    tahunPelajaranC.dispose();
    semesterC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Kelas' : 'Tambah Kelas')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: namaKelasC,
                decoration: const InputDecoration(
                  labelText: 'Nama Kelas',
                  hintText: 'Contoh: Kelas VII A',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: tahunPelajaranC,
                decoration: const InputDecoration(
                  labelText: 'Tahun Pelajaran',
                  hintText: 'Contoh: 2022-2023',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: semesterC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  hintText: 'Contoh: 1',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  final n = int.tryParse(v.trim());
                  if (n == null) return 'Semester harus angka';
                  if (n < 1) return 'Semester minimal 1';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: jk,
                decoration: const InputDecoration(
                  labelText: 'Jenis Kelas',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Reguler', child: Text('Reguler')),
                  DropdownMenuItem(value: 'Tahfiz', child: Text('Tahfiz')),
                ],
                onChanged: (v) => setState(() => jk = v ?? 'Reguler'),
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
                          if (!(_formKey.currentState?.validate() ?? false))
                            return;

                          setState(() => saving = true);
                          try {
                            final payload = KelasModel(
                              idRuangKelas: widget.existing?.idRuangKelas ?? 0,
                              idKelas: idKelas,
                              namaKelas: namaKelasC.text.trim(),
                              tahunPelajaran: tahunPelajaranC.text.trim(),
                              semester:
                                  int.tryParse(semesterC.text.trim()) ?? 1,

                              jenisKelas: jk,
                              ketAktif: aktif ? 1 : 0,
                            );
                            final notifier = ref.read(
                              kelasListProvider.notifier,
                            );

                            if (isEdit) {
                              await notifier.edit(
                                widget.existing!.idRuangKelas,
                                payload,
                              );
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
