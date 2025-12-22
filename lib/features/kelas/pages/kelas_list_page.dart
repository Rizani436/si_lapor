import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/kelas_model.dart';
import '../providers/kelas_provider.dart';
import '../widgets/kelas_tile.dart';
import 'kelas_form_page.dart';

class KelasListPage extends ConsumerStatefulWidget {
  const KelasListPage({super.key});

  @override
  ConsumerState<KelasListPage> createState() => _KelasListPageState();
}

class _KelasListPageState extends ConsumerState<KelasListPage> {
  final _search = TextEditingController();

  String? _filterJk;
  String? _filterTahunPelajaran;
  int? _filterSemester;
  int? _filterStatus;
  bool _showFilters = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kelasAsync = ref.watch(kelasListProvider);

    final hasActiveFilter =
        _filterJk != null ||
        _filterStatus != null ||
        _filterTahunPelajaran != null ||
        _filterSemester != null;

    final tahunPelajaranOptions =
        (kelasAsync.asData?.value ?? const <KelasModel>[])
            .map((e) => e.tahunPelajaran)
            .where((e) => e.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kelas'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(kelasListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const KelasFormPage()),
          );
          if (ok == true && context.mounted) {
            ref.read(kelasListProvider.notifier).refresh();
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
                      value: _filterTahunPelajaran,
                      decoration: const InputDecoration(
                        labelText: 'Tahun Pelajaran',
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
                        ...tahunPelajaranOptions.map(
                          (t) => DropdownMenuItem(value: t, child: Text(t)),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _filterTahunPelajaran = v),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<int?>(
                      isExpanded: true,
                      value: _filterSemester,
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Semua')),
                        DropdownMenuItem(value: 1, child: Text('1')),
                        DropdownMenuItem(value: 2, child: Text('2')),
                      ],
                      onChanged: (v) => setState(() => _filterSemester = v),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      value: _filterJk,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kelas',
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
                          value: 'Reguler',
                          child: Text('Reguler'),
                        ),
                        DropdownMenuItem(
                          value: 'Tahfiz',
                          child: Text('Tahfiz'),
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
                        labelText: 'Status Kelas',
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
            child: kelasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                final q = _search.text.trim().toLowerCase();

                final filtered = list.where((s) {
                  final okSearch =
                      q.isEmpty ||
                      s.namaKelas.toLowerCase().contains(q) ||
                      (s.kodeKelas ?? '').toLowerCase().contains(q);

                  final okJk = _filterJk == null || s.jenisKelas == _filterJk;
                  final okStatus =
                      _filterStatus == null || s.ketAktif == _filterStatus;

                  return okSearch && okJk && okStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Data kelas kosong.'));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = filtered[i];
                    return KelasTile(
                      s: s,
                      onTap: () async {
                        final ok = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KelasFormPage(existing: s),
                          ),
                        );
                        if (ok == true && context.mounted) {
                          ref.read(kelasListProvider.notifier).refresh();
                        }
                      },
                      onToggleAktif: () async {
                        await ref
                            .read(kelasListProvider.notifier)
                            .toggleAktif(s);
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Hapus kelas?'),
                            content: Text('Yakin hapus "${s.namaKelas}"?'),
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
                              .read(kelasListProvider.notifier)
                              .remove(s.idRuangKelas);
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
