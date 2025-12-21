import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/akun_provider.dart';
import '../widgets/akun_tile.dart';
import 'akun_form_page.dart';

class AkunListPage extends ConsumerStatefulWidget {
  const AkunListPage({super.key});

  @override
  ConsumerState<AkunListPage> createState() => _AkunListPageState();
}

class _AkunListPageState extends ConsumerState<AkunListPage> {
  final _search = TextEditingController();

  String? _filterRole;
  bool? _filterStatus;
  bool _showFilters = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final akunAsync = ref.watch(akunListProvider);

    final hasActiveFilter = _filterRole != null || _filterStatus != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Akun'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(akunListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AkunFormPage()),
          );

          if (ok == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Akun berhasil dibuat')),
            );

            ref.read(akunListProvider.notifier).refresh();
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
                      hintText: 'Cari nama / email...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Stack(
                    children: [
                      Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
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
                children: [
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String?>(
                      value: _filterRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Semua')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'parent', child: Text('Parent')),
                        DropdownMenuItem(value: 'guru', child: Text('Guru')),
                        DropdownMenuItem(value: 'kepsek', child: Text('Kepsek')),
                      ],
                      onChanged: (v) => setState(() => _filterRole = v),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<bool?>(
                      value: _filterStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Semua')),
                        DropdownMenuItem(value: true, child: Text('Aktif')),
                        DropdownMenuItem(value: false, child: Text('Nonaktif')),
                      ],
                      onChanged: (v) => setState(() => _filterStatus = v),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _filterRole = null;
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
            child: akunAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                final q = _search.text.trim().toLowerCase();

                final filtered = list.where((a) {
                  final okSearch = q.isEmpty ||
                      (a.namaLengkap ?? '').toLowerCase().contains(q) ||
                      (a.email ?? '').toLowerCase().contains(q);

                  final okRole = _filterRole == null || a.role == _filterRole;
                  final okStatus =
                      _filterStatus == null || a.isActive == _filterStatus;

                  return okSearch && okRole && okStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Data akun kosong.'));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final a = filtered[i];
                    return AkunTile(
                      p: a,
                      onTap: () async {
                        final ok = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => AkunFormPage(existing: a)),
                        );
                        if (ok == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Akun berhasil diperbarui')),
                          );
                          ref.read(akunListProvider.notifier).refresh();
                        }
                      },
                      onToggleAktif: () async {
                        await ref.read(akunListProvider.notifier).toggleAktif(a);
                      },
                      onDelete: () async {
                        await ref.read(akunListProvider.notifier).remove(a.id);
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
