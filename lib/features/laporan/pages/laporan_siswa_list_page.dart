import 'dart:async';
import 'dart:typed_data';

import 'package:si_lapor/core/UI/ui_helpers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../siswa/models/siswa_model.dart';
import '../../kelas/models/kelas_model.dart';

import '../providers/laporan_siswa_provider.dart';
import '../providers/rapor_provider.dart'; 
import '../pages/laporan_siswa_form_page.dart';
import '../widgets/laporan_siswa_tile.dart';

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

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    siswa = widget.existing;
    kelas = widget.existingKelas;
    selectedDate = DateTime.now();

    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  ({int idRuangKelas, int idDataSiswa, String tanggal})? _providerArgs() {
    final idDataSiswa = siswa?.idDataSiswa;
    final idRuangKelas = kelas?.idRuangKelas;
    final tanggalStr = selectedDate == null ? null : _fmtDate(selectedDate!);

    if (idDataSiswa == null || idRuangKelas == null || tanggalStr == null) {
      return null;
    }

    return (
      idRuangKelas: idRuangKelas,
      idDataSiswa: idDataSiswa,
      tanggal: tanggalStr,
    );
  }

  void _startAutoRefresh() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final args = _providerArgs();
      if (args == null) return;
      ref.invalidate(laporanByTanggalProvider(args));
    });
  }

  void _stopAutoRefresh() {
    _pollTimer?.cancel();
    _pollTimer = null;
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

    _startAutoRefresh();
  }

  Future<void> _uploadRaporGuru() async {
    final idDataSiswa = siswa?.idDataSiswa;
    final idRuangKelas = kelas?.idRuangKelas;

    if (idDataSiswa == null || idRuangKelas == null) {
      toast('Data siswa/kelas belum lengkap');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      withData: true, 
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final Uint8List? bytes = file.bytes;
    final String name = file.name;

    if (bytes == null) {
      toast('Gagal membaca file');
      return;
    }

    try {
      await ref
          .read(raporServiceProvider)
          .uploadRapor(
            idDataSiswa: idDataSiswa,
            idRuangKelas: idRuangKelas,
            bytes: bytes,
            originalFilename: name,
          );

      ref.invalidate(
        raporUrlProvider((
          idDataSiswa: idDataSiswa,
          idRuangKelas: idRuangKelas,
        )),
      );

      toast('Rapor berhasil diupload');
    } catch (e) {
      toast('Upload rapor gagal: $e');
    }
  }

  Future<void> _openRaporUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      toast('URL rapor tidak valid');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) toast('Tidak bisa membuka rapor');
  }

  Future<void> _deleteRaporGuru() async {
    final idDataSiswa = siswa?.idDataSiswa;
    final idRuangKelas = kelas?.idRuangKelas;

    if (idDataSiswa == null || idRuangKelas == null) return;

    final ok = await _confirmDelete(context);
    if (!ok) return;

    try {
      await ref
          .read(raporServiceProvider)
          .removeRapor(idDataSiswa: idDataSiswa, idRuangKelas: idRuangKelas);

      ref.invalidate(
        raporUrlProvider((
          idDataSiswa: idDataSiswa,
          idRuangKelas: idRuangKelas,
        )),
      );

      toast('Rapor dihapus');
    } catch (e) {
      toast('Gagal hapus rapor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _providerArgs();
    final canLoad = args != null;

    final laporanAsync = canLoad
        ? ref.watch(laporanByTanggalProvider(args!))
        : null;

    final idDataSiswa = siswa?.idDataSiswa;
    final idRuangKelas = kelas?.idRuangKelas;

    final raporAsync = (idDataSiswa != null && idRuangKelas != null)
        ? ref.watch(
            raporUrlProvider((
              idDataSiswa: idDataSiswa,
              idRuangKelas: idRuangKelas,
            )),
          )
        : const AsyncValue.data(null);

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
                        'Biodata Siswa',
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
                      const Divider(height: 18),

                      const Text(
                        'Rapor',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      raporAsync.when(
                        loading: () => const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          title: Text('Memuat rapor...'),
                        ),
                        error: (e, _) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.error_outline),
                          title: const Text('Gagal memuat rapor'),
                          subtitle: Text('$e'),
                          trailing: TextButton(
                            onPressed: _uploadRaporGuru,
                            child: const Text('Upload'),
                          ),
                        ),
                        data: (url) {
                          final hasRapor = url != null && url.trim().isNotEmpty;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              hasRapor
                                  ? Icons.picture_as_pdf
                                  : Icons.insert_drive_file_outlined,
                            ),
                            title: const Text('File Rapor'),
                            subtitle: Text(
                              hasRapor ? 'Sudah diupload' : 'Belum ada rapor',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: _uploadRaporGuru,
                                  child: Text(hasRapor ? 'Ganti' : 'Upload'),
                                ),
                                if (hasRapor) ...[
                                  IconButton(
                                    tooltip: 'Buka',
                                    onPressed: () => _openRaporUrl(url!),
                                    icon: const Icon(Icons.open_in_new),
                                  ),
                                  IconButton(
                                    tooltip: 'Hapus',
                                    onPressed: _deleteRaporGuru,
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
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
                                          existingLaporanRow: r,
                                        ),
                                      ),
                                    );

                                    if (changed == true) {
                                      final a = _providerArgs();
                                      if (a != null) {
                                        ref.invalidate(
                                          laporanByTanggalProvider(a),
                                        );
                                      }
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

                                      final a = _providerArgs();
                                      if (a != null) {
                                        ref.invalidate(
                                          laporanByTanggalProvider(a),
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

                                  if (changed == true) {
                                    final a = _providerArgs();
                                    if (a != null) {
                                      ref.invalidate(
                                        laporanByTanggalProvider(a),
                                      );
                                    }
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
