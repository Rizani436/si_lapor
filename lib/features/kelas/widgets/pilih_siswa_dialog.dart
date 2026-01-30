import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../siswa/models/siswa_model.dart';
import '../../siswa/providers/siswa_provider.dart';

Future<SiswaModel?> showPilihSiswaDialog(BuildContext context) async {
  return showDialog<SiswaModel?>(
    context: context,
    builder: (_) => const _PilihSiswaDialog(),
  );
}

class _PilihSiswaDialog extends ConsumerStatefulWidget {
  const _PilihSiswaDialog();

  @override
  ConsumerState<_PilihSiswaDialog> createState() => _PilihSiswaDialogState();
}

class _PilihSiswaDialogState extends ConsumerState<_PilihSiswaDialog> {
  final _q = TextEditingController();

  String query = '';
  String? _filterTahun;
  String? _filterJk;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncSiswa = ref.watch(siswaListProvider);

    return AlertDialog(
      title: const Text('Pilih Siswa'),
      content: SizedBox(
        width: double.maxFinite,
        child: asyncSiswa.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (list) {
            final tahunOptions = list
                .map((e) => e.tahunMasuk)
                .where((e) => e != null && e!.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

            final filtered = list.where((s) {
              final nama = s.namaLengkap.toLowerCase();
              final nis = (s.nis ?? '').toLowerCase();

              final matchSearch = query.isEmpty ||
                  nama.contains(query) ||
                  nis.contains(query);

              final matchTahun =
                  _filterTahun == null || s.tahunMasuk == _filterTahun;

              final matchJk =
                  _filterJk == null || s.jenisKelamin == _filterJk;

              return matchSearch && matchTahun && matchJk;
            }).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Row(
                  children: [

                    Expanded(
                      child: TextField(
                        controller: _q,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Cari nama / NIS...',
                        ),
                        onChanged: (v) => setState(
                          () => query = v.trim().toLowerCase(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),


                    PopupMenuButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.filter_alt),
                          if (_filterTahun != null || _filterJk != null)
                            const Positioned(
                              right: 0,
                              top: 0,
                              child: CircleAvatar(radius: 4),
                            ),
                        ],
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              DropdownButtonFormField<String>(
                                value: _filterTahun,
                                hint: const Text('Tahun Masuk'),
                                items: tahunOptions
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e!),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _filterTahun = v),
                              ),

                              const SizedBox(height: 8),

                              DropdownButtonFormField<String>(
                                value: _filterJk,
                                hint: const Text('Jenis Kelamin'),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'L',
                                    child: Text('Laki-laki'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'P',
                                    child: Text('Perempuan'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _filterJk = v),
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => setState(() {
                                    _filterTahun = null;
                                    _filterJk = null;
                                  }),
                                  child: const Text('Reset'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Tidak ada siswa'))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final s = filtered[i];

                            final subtitle = [
                              if ((s.nis ?? '').isNotEmpty)
                                'NIS: ${s.nis}',
                              if ((s.jenisKelamin ?? '').isNotEmpty)
                                'JK: ${s.jenisKelamin}',
                              if ((s.tahunMasuk ?? '').isNotEmpty)
                                'Masuk: ${s.tahunMasuk}',
                              if (s.ketAktif != null)
                                'Aktif: ${s.ketAktif}',
                            ].join(' • ');

                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(
                                s.namaLengkap.isEmpty
                                    ? '(Tanpa nama)'
                                    : s.namaLengkap,
                              ),
                              subtitle:
                                  Text(subtitle.isEmpty ? '-' : subtitle),
                              onTap: () =>
                                  Navigator.pop(context, s),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
