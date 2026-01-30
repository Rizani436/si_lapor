import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/guru_model.dart';
import '../providers/guru_import_provider.dart';
import '../providers/guru_provider.dart';
import '../widgets/guru_tile.dart';
import 'guru_form_page.dart';

class GuruListPage extends ConsumerStatefulWidget {
  const GuruListPage({super.key});

  @override
  ConsumerState<GuruListPage> createState() => _GuruListPageState();
}

class _GuruListPageState extends ConsumerState<GuruListPage> {
  final _search = TextEditingController();
  final Set<int> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;
  List<GuruModel> _filtered = [];

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
        'lib/assets/templates/template_guru.xlsx',
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/template_guru.xlsx');

      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

      await Share.shareXFiles([XFile(file.path)], text: 'Template Import Guru');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal download template: $e')));
    }
  }

  void _toggleSelect(GuruModel s) {
    setState(() {
      if (_selectedIds.contains(s.idDataGuru)) {
        _selectedIds.remove(s.idDataGuru);
      } else {
        _selectedIds.add(s.idDataGuru!);
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
          .read(guruImportControllerProvider.notifier)
          .importXlsxBytes(bytes);

      await ref.read(guruListProvider.notifier).refresh();

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
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import gagal: $e')));
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus guru'),
        content: Text('Yakin hapus ${_selectedIds.length} guru terpilih?'),
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
        await ref.read(guruListProvider.notifier).remove(id);
      }
      setState(_selectedIds.clear);
    }
  }

  Future<void> _deleteSelected() async {
    final ids = _selectedIds.toList();
    for (final id in ids) {
      await ref.read(guruListProvider.notifier).remove(id);
    }
    setState(() => _selectedIds.clear());
  }

  void _selectAll() {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(_filtered.map((e) => e.idDataGuru));
    });
  }

  Future<void> _downloadSelectedAsXlsx() async {
    if (_selectedIds.isEmpty) return;

    final selected = _filtered
        .where((s) => _selectedIds.contains(s.idDataGuru))
        .toList();

    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    final headers = [
      'nama_lengkap',
      'nip',
      'alamat',
      'jenis_kelamin',
      'ket_aktif',
    ];

    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (final s in selected) {
      sheet.appendRow([
        TextCellValue(s.namaLengkap),
        TextCellValue(s.nip),
        TextCellValue(s.alamat ?? ''),
        TextCellValue(s.jenisKelamin),
        TextCellValue(s.isAktif ? '1' : '0'),
      ]);
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/data_guru_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    await file.writeAsBytes(excel.encode()!);

    await Share.shareXFiles([XFile(file.path)], text: 'Data Guru');
  }

  @override
  Widget build(BuildContext context) {
    final guruAsync = ref.watch(guruListProvider);

    final importState = ref.watch(guruImportControllerProvider);
    final importing = importState.isLoading;
    final hasActiveFilter = _filterJk != null || _filterStatus != null;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedIds.length} dipilih')
            : const Text('Kelola Guru'),
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
                        ..addAll(_filtered.map((e) => e.idDataGuru!));
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
                      ref.read(guruListProvider.notifier).refresh(),
                ),
              ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const GuruFormPage()),
          );
          if (ok == true && context.mounted) {
            ref.read(guruListProvider.notifier).refresh();
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
                      hintText: 'Cari nama / NIP...',
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
            child: guruAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                final q = _search.text.trim().toLowerCase();

                _filtered = list.where((s) {
                  final okSearch =
                      q.isEmpty ||
                      s.namaLengkap.toLowerCase().contains(q) ||
                      s.nip.toLowerCase().contains(q);

                  final okJk = _filterJk == null || s.jenisKelamin == _filterJk;
                  final okStatus =
                      _filterStatus == null || s.ketAktif == _filterStatus;

                  return okSearch && okJk && okStatus;
                }).toList();

                if (_filtered.isEmpty) {
                  return const Center(child: Text('Data guru kosong.'));
                }

                return ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = _filtered[i];
                    final selected = _selectedIds.contains(s.idDataGuru);
                    return GuruTile(
                      s: s,
                      selected: selected,
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelect(s);
                          return;
                        } else {
                          final ok = Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuruFormPage(existing: s),
                            ),
                          );
                          if (ok == true && context.mounted) {
                            ref.read(guruListProvider.notifier).refresh();
                          }
                        }
                      },
                      onLongPress: () => _toggleSelect(s),
                      onToggleAktif: () async {
                        await ref
                            .read(guruListProvider.notifier)
                            .toggleAktif(s);
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Hapus guru?'),
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
                              .read(guruListProvider.notifier)
                              .remove(s.idDataGuru);
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
