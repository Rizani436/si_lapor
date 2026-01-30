import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';


import '../models/siswa_model.dart';
import '../providers/siswa_import_provider.dart';
import '../providers/siswa_provider.dart';
import '../widgets/siswa_tile.dart';
import 'siswa_form_page.dart';
import '../../../core/utils/error_mapper.dart';

class SiswaListPage extends ConsumerStatefulWidget {
  const SiswaListPage({super.key});

  @override
  ConsumerState<SiswaListPage> createState() => _SiswaListPageState();
}

class _SiswaListPageState extends ConsumerState<SiswaListPage> {
  final _search = TextEditingController();
  final Set<int> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;
  List<SiswaModel> _filtered = [];

  String? _filterTahun;
  String? _filterJk;
  int? _filterStatus;
  bool _showFilters = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    try {
      final data = await rootBundle.load(
        'lib/assets/templates/template_siswa.xlsx',
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/template_siswa.xlsx');

      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Template Import Siswa');
    } catch (e) {
      final error = ErrorMapper.fromGeneric(e);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal download template: $error')),
      );
    }
  }

  void _toggleSelect(SiswaModel s) {
    setState(() {
      if (_selectedIds.contains(s.idDataSiswa)) {
        _selectedIds.remove(s.idDataSiswa);
      } else {
        _selectedIds.add(s.idDataSiswa!);
      }
    });
  }

  Future<void> _importExcel(BuildContext context) async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (picked == null) return;

      final bytes = picked.files.single.bytes;
      if (bytes == null) throw Exception('Tidak bisa membaca file.');

      final res = await ref
          .read(siswaImportControllerProvider.notifier)
          .importXlsxBytes(bytes);

      await ref.read(siswaListProvider.notifier).refresh();

      if (!context.mounted) return;

      final msg = res.errors.isEmpty
          ? 'Import selesai. Berhasil: ${res.successRows}'
          : 'Import selesai. Berhasil: ${res.successRows}, Gagal: ${res.errors.length}';

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hasil Import'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                res.errors.isEmpty
                    ? msg
                    : '$msg\n\nDetail error:\n- ${res.errors.take(20).join('\n- ')}'
                          '${res.errors.length > 20 ? '\n... (${res.errors.length - 20} error lain)' : ''}',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      final error = ErrorMapper.fromGeneric(e);

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import gagal: $error')));
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus siswa'),
        content: Text('Yakin hapus ${_selectedIds.length} siswa terpilih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok == true) {
      for (final id in _selectedIds) {
        await ref.read(siswaListProvider.notifier).remove(id);
      }
      setState(_selectedIds.clear);
    }
  }

  Future<void> _deleteSelected() async {
    final ids = _selectedIds.toList();
    for (final id in ids) {
      await ref.read(siswaListProvider.notifier).remove(id);
    }
    setState(() => _selectedIds.clear());
  }

  void _selectAll() {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(_filtered.map((e) => e.idDataSiswa));
    });
  }

  Future<void> _downloadSelectedAsXlsx() async {
    if (_selectedIds.isEmpty) return;

    final selected = _filtered
        .where((s) => _selectedIds.contains(s.idDataSiswa))
        .toList();

    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    final headers = [
      'nama_lengkap',
      'nis',
      'alamat',
      'jenis_kelamin',
      'tahun_masuk',
      'tanggal_lahir',
      'ket_aktif',
    ];

    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (final s in selected) {
      sheet.appendRow([
        TextCellValue(s.namaLengkap),
        TextCellValue(s.nis),
        TextCellValue(s.alamat ?? ''),
        TextCellValue(s.jenisKelamin),
        TextCellValue(s.tahunMasuk),
        TextCellValue(
          s.tanggalLahir != null
              ? s.tanggalLahir!.toIso8601String().split('T').first
              : '',
        ),
        TextCellValue(s.isAktif ? '1' : '0'),
      ]);
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/data_siswa_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    await file.writeAsBytes(excel.encode()!);

    await Share.shareXFiles([XFile(file.path)], text: 'Data Siswa');
  }

  @override
  Widget build(BuildContext context) {
    final siswaAsync = ref.watch(siswaListProvider);

    final importState = ref.watch(siswaImportControllerProvider);
    final importing = importState.isLoading;
    final hasActiveFilter =
        _filterTahun != null || _filterJk != null || _filterStatus != null;

    final tahunOptions =
        (siswaAsync.asData?.value ?? const <SiswaModel>[])
            .map((e) => e.tahunMasuk)
            .where((e) => e.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedIds.length} dipilih')
            : const Text('Kelola Siswa'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(_selectedIds.clear),
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  tooltip: 'Pilih Semua',
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    setState(() {
                      _selectedIds
                        ..clear()
                        ..addAll(_filtered.map((e) => e.idDataSiswa!));
                    });
                  },
                ),
                IconButton(
                  tooltip: 'Download',
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadSelectedAsXlsx(),
                ),
                IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteSelected(),
                ),
              ]
            : [
                IconButton(
                  tooltip: 'Download Template',
                  icon: const Icon(Icons.file_download),
                  onPressed: () => _downloadTemplate(context),
                ),
                IconButton(
                  tooltip: 'Import Excel',
                  icon: importing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  onPressed: importing ? null : () => _importExcel(context),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      ref.read(siswaListProvider.notifier).refresh(),
                ),
              ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const SiswaFormPage()),
          );
          if (ok == true && context.mounted) {
            ref.read(siswaListProvider.notifier).refresh();
          }
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cari nama / NIS...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                IconButton(
                  tooltip: 'Filter',
                  icon: Stack(
                    children: [
                      Icon(
                        _showFilters ? Icons.filter_alt_off : Icons.filter_alt,
                      ),
                      if (hasActiveFilter)
                        const Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(radius: 4),
                        ),
                    ],
                  ),
                  onPressed: () => setState(() => _showFilters = !_showFilters),
                ),
              ],
            ),
          ),

          if (_showFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      value: _filterTahun,
                      decoration: const InputDecoration(
                        labelText: 'Tahun Masuk',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Semua'),
                        ),
                        ...tahunOptions.map(
                          (t) => DropdownMenuItem(value: t, child: Text(t)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _filterTahun = v),
                    ),
                  ),

                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      value: _filterJk,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kelamin',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Semua')),
                        DropdownMenuItem(
                          value: 'L',
                          child: Text('Laki-laki (L)'),
                        ),
                        DropdownMenuItem(
                          value: 'P',
                          child: Text('Perempuan (P)'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _filterJk = v),
                    ),
                  ),

                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<int?>(
                      isExpanded: true,
                      value: _filterStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Semua')),
                        DropdownMenuItem(value: 1, child: Text('Aktif')),
                        DropdownMenuItem(value: 0, child: Text('Nonaktif')),
                      ],
                      onChanged: (v) => setState(() => _filterStatus = v),
                    ),
                  ),

                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _filterTahun = null;
                        _filterJk = null;
                        _filterStatus = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: siswaAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                final q = _search.text.trim().toLowerCase();

                _filtered = list.where((s) {
                  final q = _search.text.trim().toLowerCase();

                  final okSearch =
                      q.isEmpty ||
                      s.namaLengkap.toLowerCase().contains(q) ||
                      s.nis.toLowerCase().contains(q);

                  final okTahun =
                      _filterTahun == null || s.tahunMasuk == _filterTahun;
                  final okJk = _filterJk == null || s.jenisKelamin == _filterJk;
                  final okStatus =
                      _filterStatus == null || s.ketAktif == _filterStatus;

                  return okSearch && okTahun && okJk && okStatus;
                }).toList();

                if (_filtered.isEmpty) {
                  return const Center(child: Text('Data siswa kosong.'));
                }

                return ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = _filtered[i];
                    final selected = _selectedIds.contains(s.idDataSiswa);

                    return SiswaTile(
                      s: s,
                      selected: selected,
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelect(s);
                          return;
                        }else{
                          final ok = Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SiswaFormPage(existing: s),
                          ),
                        );
                        if (ok == true && context.mounted) {
                          ref.read(siswaListProvider.notifier).refresh();
                        }
                        }


                      },
                      onLongPress: () => _toggleSelect(s),
                      onToggleAktif: () async {
                        await ref
                            .read(siswaListProvider.notifier)
                            .toggleAktif(s);
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Hapus siswa?'),
                            content: Text('Yakin hapus "${s.namaLengkap}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          await ref
                              .read(siswaListProvider.notifier)
                              .remove(s.idDataSiswa);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
