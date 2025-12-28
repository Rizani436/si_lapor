import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';


import '../../siswa/models/siswa_model.dart';
import '../../kelas/models/kelas_model.dart';
import '../providers/laporan_siswa_provider.dart';
import '../widgets/laporan_tile.dart';
import '../providers/rapor_provider.dart';

class LaporanListPage extends ConsumerStatefulWidget {
  final SiswaModel? existing;
  final KelasModel? existingKelas;
  const LaporanListPage({super.key, this.existing, this.existingKelas});

  @override
  ConsumerState<LaporanListPage> createState() => _LaporanListPageState();
}

class _LaporanListPageState extends ConsumerState<LaporanListPage> {
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
                        ),
                        data: (url) {
                          if (url == null || url.trim().isEmpty) {
                            return const ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.insert_drive_file_outlined),
                              title: Text('Rapor'),
                              subtitle: Text('Belum ada rapor diupload'),
                            );
                          }

                          final viewUrl = url.trim(); 

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.picture_as_pdf),
                            title: const Text('Rapor'),
                            subtitle: const Text('Klik untuk melihat rapor'),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () async {
                              final uri = Uri.tryParse(viewUrl);
                              if (uri == null) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('URL rapor tidak valid'),
                                  ),
                                );
                                return;
                              }

                              final ok = await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );

                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tidak bisa membuka rapor'),
                                  ),
                                );
                              }
                            },
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
                                return LaporanTile(laporan: r);
                              },
                            );
                          },
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
