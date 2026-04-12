import 'dart:async';
import 'dart:typed_data';

import 'package:si_lapor/core/UI/ui_helpers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    'Ziyadah Guru': false,
    'Murajaah Guru': false,
    'Tasmi Guru': false,
    'Ziyadah Orang Tua': false,
    'Murajaah Orang Tua': false,
  };

  final TextEditingController _jumlahJuzController = TextEditingController();
  bool _isEditingJuz = false;
  bool _isSavingJuz = false;

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
    _jumlahJuzController.text = siswa?.jumlahJuz?.toString() ?? '';

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

  Future<void> _updateJumlahJuz() async {
    final newValue = int.tryParse(_jumlahJuzController.text);
    if (newValue == null || siswa?.idDataSiswa == null) return;

    setState(() => _isSavingJuz = true);

    try {
      await Supabase.instance.client
          .from('datasiswa')
          .update({'jumlah_juz': newValue})
          .eq('id_data_siswa', siswa!.idDataSiswa);

      setState(() {
        siswa = siswa!.copyWith(jumlahJuz: newValue);
        _isEditingJuz = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target Juz berhasil diperbarui')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal update: $e')));
    }

    setState(() => _isSavingJuz = false);
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

  Widget _buildRingkasSection(
    String title,
    List<RingkasItem> items,
    String pelapor,
  ) {
    final isOpen = _showDetail['$title $pelapor'] ?? false;
    if (items.isEmpty) {
      return Text('$title: -');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.contains('Tasmi')) ...[
          _buildRingkasTasmi(title, items, pelapor),
        ] else ...[
          _buildRingkas(title, items, pelapor),

          const SizedBox(height: 6),

          GestureDetector(
            onTap: () {
              setState(() {
                _showDetail['$title $pelapor'] = !isOpen;
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
        _buildRingkasContent(),
      ],
    );
  }

  Widget _buildRingkasContent() {
    final provider = laporanRingkasDetailProvider((
      idSiswa: siswa!.idDataSiswa!,
      idKelas: kelas!.idRuangKelas!,
    ));

    final ringkasAsync = ref.refresh(provider);

    return ringkasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Gagal memuat ringkasan: $e'),
      data: (data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ringkasan Laporan dari Guru",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 8),
            _buildRingkasSection('Ziyadah', data['ziyadahGuru']!, 'Guru'),
            const Divider(height: 8),
            _buildRingkasSection('Murajaah', data['murajaahGuru']!, 'Guru'),
            const Divider(height: 8),
            _buildRingkasSection('Tasmi', data['tasmiGuru']!, 'Guru'),
            const Divider(height: 24),
            Text(
              "Ringkasan Laporan dari Orang Tua",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 8),
            _buildRingkasSection(
              'Ziyadah',
              data['ziyadahOrangTua']!,
              'Orang Tua',
            ),
            const Divider(height: 8),
            _buildRingkasSection(
              'Murajaah',
              data['murajaahOrangTua']!,
              'Orang Tua',
            ),
          ],
        );
      },
    );
  }

  Widget _buildRingkas(String title, List<RingkasItem> items, String pelapor) {
    if (items.isEmpty) {
      return Text('$title: -');
    }

    final Map<int, Map<String, List<RingkasItem>>> grouped = {};

    for (final item in items) {
      if (item.pelapor != pelapor) continue;
      grouped
          .putIfAbsent(item.juz, () => {})
          .putIfAbsent(item.surah!, () => [])
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
            .map((e) => getAyatMin(e.ayat!))
            .reduce((a, b) => a < b ? a : b);

        final maxAyat = list
            .map((e) => getAyatMax(e.ayat!))
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

  Widget _buildRingkasTasmi(
    String title,
    List<RingkasItem> items,
    String pelapor,
  ) {
    if (items.isEmpty) {
      return Text('$title: -');
    }

    // Mengelompokkan berdasarkan Juz
    final Map<int, List<RingkasItem>> grouped = {};

    for (final item in items) {
      if (item.pelapor != pelapor) continue;
      grouped.putIfAbsent(item.juz, () => []).add(item);
    }

    if (grouped.isEmpty) return const SizedBox.shrink();

    final lines = <Widget>[];

    grouped.forEach((juz, itemsInJuz) {
      final firstItem = itemsInJuz.first;

      lines.add(
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),

          child: Text(
            '• Juz $juz dengan Predikat: ${firstItem.predikat} pada tanggal: ${firstItem.tanggal}',
          ),
        ),
      );
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
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.book),
                        title: const Text('Target Juz'),
                        subtitle: _isEditingJuz
                            ? Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _jumlahJuzController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        hintText: 'Masukkan target juz',
                                      ),
                                    ),
                                  ),
                                  if (_isSavingJuz)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  else ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      ),
                                      onPressed: _updateJumlahJuz,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isEditingJuz = false;
                                          _jumlahJuzController.text =
                                              siswa?.jumlahJuz?.toString() ??
                                              '';
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      siswa?.jumlahJuz.toString() ?? '-',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() => _isEditingJuz = true);
                                    },
                                  ),
                                ],
                              ),
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
