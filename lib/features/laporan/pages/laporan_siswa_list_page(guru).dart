import 'dart:async';
import 'dart:typed_data';

import 'package:si_lapor/core/UI/ui_helpers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../siswa/models/siswa_model.dart';
import '../../kelas/models/kelas_model.dart';
import '../../../core/utils/ringkas_item.dart';
import '../../../core/utils/text_helper.dart';

import '../providers/laporan_siswa_provider.dart';
import '../providers/rapor_provider.dart';
import '../providers/laporan_ringkas_provider.dart';
import 'laporan_siswa_form_page(guru).dart';
import '../widgets/laporan_siswa_tile.dart';

enum LaporanViewMode { harian, ringkas }

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

  LaporanViewMode _viewMode = LaporanViewMode.harian;
  final Map<String, bool> _showDetail = {
    'Ziyadah': false,
    'Murajaah': false,
    'Tasmi': false,
  };

  SiswaModel? siswa;
  KelasModel? kelas;
  DateTime? startDate;
  DateTime? endDate;

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

  Future<void> _pickRangeDate() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: (startDate != null && endDate != null)
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
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

  Widget _buildLaporanHarian({
    required bool canLoad,
    required AsyncValue<List<Map<String, dynamic>>>? laporanAsync,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar Laporan Harian',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event),
          title: const Text('Tanggal'),
          subtitle: Text(selectedDate == null ? '-' : _fmtDate(selectedDate!)),
          trailing: TextButton(
            onPressed: _pickDate,
            child: const Text('Pilih'),
          ),
        ),

        const Divider(height: 24),

        if (!canLoad)
          const Text('Data siswa/kelas belum lengkap.')
        else
          laporanAsync!.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Gagal memuat laporan: $e'),
            data: (list) {
              if (list.isEmpty) {
                return const Text('Tidak ada laporan pada tanggal ini.');
              }

              return ListView.builder(
                itemCount: list.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, r) {
                  return LaporanSiswaTile(
                    laporan: list[r],
                    onEdit: list[r]['pelapor'] == 'Guru'
                        ? () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LaporanSiswaFormPage(
                                  existing: siswa!,
                                  existingKelas: kelas!,
                                  existingIdLaporan:
                                      list[r]['id_laporan'] as int,
                                  existingLaporanRow: list[r],
                                ),
                              ),
                            );

                            if (changed == true) {
                              final a = _providerArgs();
                              if (a != null) {
                                ref.invalidate(laporanByTanggalProvider(a));
                              }
                            }
                          }
                        : null,

                    onDelete: list[r]['pelapor'] == 'Guru'
                        ? () async {
                            final id = list[r]['id_laporan'] as int?;
                            if (id == null) return;

                            final ok = await _confirmDelete(context);
                            if (!ok) return;

                            try {
                              await ref
                                  .read(laporanActionProvider.notifier)
                                  .deleteLaporan(id);

                              final a = _providerArgs();
                              if (a != null) {
                                ref.invalidate(laporanByTanggalProvider(a));
                              }

                              toast('Laporan dihapus');
                            } catch (e) {
                              toast('Gagal menghapus: $e');
                            }
                          }
                        : null,
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
                (widget.existing == null ||
                    widget.existingKelas == null ||
                    selectedDate == null)
                ? null
                : () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LaporanSiswaFormPage(
                          existing: widget.existing!,
                          existingKelas: widget.existingKelas!,
                        ),
                      ),
                    );

                    if (changed == true) {
                      final args = _providerArgs();
                      if (args != null) {
                        ref.invalidate(laporanByTanggalProvider(args));
                      }
                    }
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildRingkasSection(String title, List<RingkasItem> items) {
    final isOpen = _showDetail[title] ?? false;
    if (items.isEmpty) {
      return Text('$title: -');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRingkas(title, items),

        const SizedBox(height: 6),

        GestureDetector(
          onTap: () {
            setState(() {
              _showDetail[title] = !isOpen;
            });
          },
          child: Text(
            isOpen ? 'Sembunyikan detail' : 'Lihat detail',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        if (isOpen) ...[
          const SizedBox(height: 8),
          _buildRingkasDetail(title, items),
        ],
      ],
    );
  }

  Widget _buildLaporanRingkas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan Ringkas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.date_range),
          title: const Text('Rentang Tanggal'),
          subtitle: Text(
            startDate == null || endDate == null
                ? '-'
                : '${_fmtDate(startDate!)} s/d ${_fmtDate(endDate!)}',
          ),
          trailing: TextButton(
            onPressed: _pickRangeDate,
            child: const Text('Pilih'),
          ),
        ),

        const Divider(height: 24),

        if (siswa == null ||
            kelas == null ||
            startDate == null ||
            endDate == null)
          const Text('Pilih siswa, kelas, dan rentang tanggal')
        else
          _buildRingkasContent(),
      ],
    );
  }

  Widget _buildRingkasContent() {
    if (siswa == null ||
        kelas == null ||
        startDate == null ||
        endDate == null) {
      return const Text('Data belum lengkap');
    }

    final ringkasAsync = ref.watch(
      laporanRingkasDetailProvider((
        idSiswa: siswa!.idDataSiswa!,
        idKelas: kelas!.idKelas!,
        start: startDate!,
        end: endDate!,
      )),
    );

    return ringkasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Gagal memuat ringkasan: $e'),
      data: (data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRingkasSection('Ziyadah', data['ziyadah']!),
            const SizedBox(height: 16),
            _buildRingkasSection('Murajaah', data['murajaah']!),
            const SizedBox(height: 16),
            _buildRingkasSection('Tasmi', data['tasmi']!),
          ],
        );
      },
    );
  }

  Widget _buildRingkas(String title, List<RingkasItem> items) {
    if (items.isEmpty) {
      return Text('$title: -');
    }

    final Map<int, Map<String, List<RingkasItem>>> grouped = {};

    for (final item in items) {
      grouped
          .putIfAbsent(item.juz, () => {})
          .putIfAbsent(item.surah, () => [])
          .add(item);
    }

    final lines = <Widget>[];

    grouped.forEach((juz, surahMap) {
      lines.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Juz $juz',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );

      surahMap.forEach((surah, list) {
        final minAyat = list
            .map((e) => getAyatMin(e.ayat))
            .reduce((a, b) => a < b ? a : b);

        final maxAyat = list
            .map((e) => getAyatMax(e.ayat))
            .reduce((a, b) => a > b ? a : b);

        final ayatText = minAyat == maxAyat ? '$minAyat' : '$minAyat-$maxAyat';

        lines.add(
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text('• $surah ayat $ayatText'),
          ),
        );
      });
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...lines,
      ],
    );
  }

  Widget _buildRingkasDetail(String title, List<RingkasItem> items) {
    if (items.isEmpty) {
      return Text('$title: -');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...items.map(
          (e) => Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Text(
              '• Juz ${e.juz} — ${e.surah} ayat ${e.ayat} (${e.tanggal} | ${e.pelapor})',
            ),
          ),
        ),
      ],
    );
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
              SegmentedButton<LaporanViewMode>(
                segments: const [
                  ButtonSegment(
                    value: LaporanViewMode.harian,
                    label: Text('Harian'),
                    icon: Icon(Icons.list),
                  ),
                  ButtonSegment(
                    value: LaporanViewMode.ringkas,
                    label: Text('Ringkas'),
                    icon: Icon(Icons.dashboard),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (value) {
                  setState(() => _viewMode = value.first);
                },
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _viewMode == LaporanViewMode.harian
                      ? _buildLaporanHarian(
                          canLoad: canLoad,
                          laporanAsync: laporanAsync,
                        )
                      : _buildLaporanRingkas(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
