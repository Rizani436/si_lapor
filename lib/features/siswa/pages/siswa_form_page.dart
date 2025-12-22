import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/siswa_model.dart';
import '../providers/siswa_provider.dart';

class SiswaFormPage extends ConsumerStatefulWidget {
  final SiswaModel? existing;
  const SiswaFormPage({super.key, this.existing});

  @override
  ConsumerState<SiswaFormPage> createState() => _SiswaFormPageState();
}

class _SiswaFormPageState extends ConsumerState<SiswaFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController namaC;
  late final TextEditingController nisC;
  late final TextEditingController alamatC;
  late final TextEditingController tahunMasukC;

  String jk = 'L';
  DateTime tglLahir = DateTime(2010, 1, 1);
  bool aktif = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;

    namaC = TextEditingController(text: s?.namaLengkap ?? '');
    nisC = TextEditingController(text: s?.nis ?? '');
    alamatC = TextEditingController(text: s?.alamat ?? '');
    tahunMasukC = TextEditingController(text: s?.tahunMasuk ?? '');

    jk = s?.jenisKelamin ?? 'L';
    tglLahir = s?.tanggalLahir ?? DateTime(2010, 1, 1);
    aktif = (s?.ketAktif ?? 1) == 1;
  }

  @override
  void dispose() {
    namaC.dispose();
    nisC.dispose();
    alamatC.dispose();
    tahunMasukC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: tglLahir,
      firstDate: DateTime(1990, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => tglLahir = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Siswa' : 'Tambah Siswa')),
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
                controller: nisC,
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
                  labelText: 'Jenis Kelamin',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'L', child: Text('Laki-laki (L)')),
                  DropdownMenuItem(value: 'P', child: Text('Perempuan (P)')),
                ],
                onChanged: (v) => setState(() => jk = v ?? 'L'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: tahunMasukC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tahun Masuk',
                  hintText: 'Contoh: 2022',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Wajib diisi';
                  final n = int.tryParse(t);
                  if (n == null) return 'Harus angka';
                  if (n < 1990 || n > 2100) return 'Tahun tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal Lahir'),
                subtitle: Text(
                  '${tglLahir.year}-${tglLahir.month.toString().padLeft(2, '0')}-${tglLahir.day.toString().padLeft(2, '0')}',
                ),
                trailing: OutlinedButton(
                  onPressed: _pickDate,
                  child: const Text('Pilih'),
                ),
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
                            final payload = SiswaModel(
                              idDataSiswa: widget.existing?.idDataSiswa ?? 0,
                              namaLengkap: namaC.text.trim(),
                              nis: nisC.text.trim(),
                              alamat: alamatC.text.trim(),
                              jenisKelamin: jk,
                              tahunMasuk: tahunMasukC.text.trim(),
                              tanggalLahir: tglLahir,
                              ketAktif: aktif ? 1 : 0,
                            );

                            final notifier = ref.read(siswaListProvider.notifier);

                            if (isEdit) {
                              await notifier.edit(widget.existing!.idDataSiswa, payload);
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
