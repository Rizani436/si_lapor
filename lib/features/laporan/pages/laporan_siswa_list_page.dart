import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:si_lapor/core/UI/ui_helpers.dart';
import 'package:si_lapor/features/laporan/widgets/laporan_tile.dart';
import '../../siswa/models/siswa_model.dart';
import '../../kelas/models/kelas_model.dart';
import '../providers/laporan_siswa_provider.dart';
import '../widgets/laporan_siswa_tile.dart';
import '../../../core/utils/text_helper.dart';
import 'laporan_siswa_form_page.dart';

class LaporanSiswaListPage extends ConsumerStatefulWidget {
  final SiswaModel? existing;
  final KelasModel? existingKelas;
  const LaporanSiswaListPage({super.key, this.existing, this.existingKelas});

  @override
  ConsumerState<LaporanSiswaListPage> createState() =>
      _LaporanSiswaListPageState();
}

class _LaporanSiswaListPageState extends ConsumerState<LaporanSiswaListPage> {
  final _formKey = GlobalKey<FormState>();

  SiswaModel? siswa;
  KelasModel? kelas;

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    siswa = widget.existing;
    kelas = widget.existingKelas;

    selectedDate = DateTime.now();
  }

  String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus laporan?'),
        content: const Text('Data laporan akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final idDataSiswa = siswa?.idDataSiswa;
    final idRuangKelas = kelas?.idRuangKelas;
    final tanggalStr = selectedDate == null ? null : _fmtDate(selectedDate!);

    final canLoad =
        idDataSiswa != null && idRuangKelas != null && tanggalStr != null;

    final laporanAsync = canLoad
        ? ref.watch(
            laporanByTanggalProvider((
              idRuangKelas: idRuangKelas!,
              idDataSiswa: idDataSiswa!,
              tanggal: tanggalStr!,
            )),
          )
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Siswa')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Laporan Siswa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.badge),
                        title: const Text('Nama Siswa'),
                        subtitle: Text(siswa?.namaLengkap ?? '-'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.date_range),
                        title: const Text('NIS'),
                        subtitle: Text(siswa?.nis ?? '-'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daftar Laporan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: const Text('Tanggal'),
                        subtitle: Text(
                          selectedDate == null ? '-' : _fmtDate(selectedDate!),
                        ),
                        trailing: TextButton(
                          onPressed: _pickDate,
                          child: const Text('Pilih'),
                        ),
                      ),

                      const Divider(height: 24),

                      if (!canLoad)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('Data siswa/kelas belum lengkap.'),
                        )
                      else
                        laporanAsync!.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('Gagal memuat laporan: $e'),
                          ),
                          data: (list) {
                            if (list.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Tidak ada laporan pada tanggal ini.',
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: list.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, i) {
                                final r = list[i];

                                return LaporanSiswaTile(
                                  laporan: r,
                                  onEdit: () async {
                                    final changed = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LaporanSiswaFormPage(
                                          existing: siswa!,
                                          existingKelas: kelas!,
                                          existingIdLaporan:
                                              r['id_laporan'] as int,
                                          existingLaporanRow:
                                              r,
                                        ),
                                      ),
                                    );

                                    if (changed == true && tanggalStr != null) {
                                      ref.invalidate(
                                        laporanByTanggalProvider((
                                          idRuangKelas: kelas!.idRuangKelas!,
                                          idDataSiswa: siswa!.idDataSiswa!,
                                          tanggal: tanggalStr!,
                                        )),
                                      );
                                    }
                                  },
                                  onDelete: () async {
                                    final id = r['id_laporan'] as int?;
                                    if (id == null) return;

                                    final ok = await _confirmDelete(context);
                                    if (!ok) return;

                                    try {
                                      await ref
                                          .read(laporanActionProvider.notifier)
                                          .deleteLaporan(id);

                                      if (tanggalStr != null) {
                                        ref.invalidate(
                                          laporanByTanggalProvider((
                                            idRuangKelas: kelas!.idRuangKelas!,
                                            idDataSiswa: siswa!.idDataSiswa!,
                                            tanggal: tanggalStr!,
                                          )),
                                        );
                                      }

                                      toast('Laporan dihapus');
                                    } catch (e) {
                                      toast('Gagal menghapus: $e');
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),

                      const SizedBox(height: 12),


                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Buat Laporan'),
                          onPressed:
                              (siswa == null ||
                                  kelas == null ||
                                  selectedDate == null)
                              ? null
                              : () async {
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LaporanSiswaFormPage(
                                        existing: siswa!,
                                        existingKelas: kelas!,
                                       
                                      ),
                                    ),
                                  );

                                  if (changed == true && tanggalStr != null) {
                                    ref.invalidate(
                                      laporanByTanggalProvider((
                                        idRuangKelas: kelas!.idRuangKelas!,
                                        idDataSiswa: siswa!.idDataSiswa!,
                                        tanggal: tanggalStr!,
                                      )),
                                    );
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
