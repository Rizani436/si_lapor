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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _q,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari nama / NIS...',
              ),
              onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: asyncSiswa.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => SingleChildScrollView(
                  child: Text('Error: $e'),
                ),
                data: (list) {
                  final filtered = list.where((s) {
                    final name = (s.namaLengkap).toLowerCase();
                    final nis = (s.nis ?? '').toLowerCase();
                    return query.isEmpty ||
                        name.contains(query) ||
                        nis.contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Tidak ada siswa.'));
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = filtered[i];

                      final subtitle = [
                        if ((s.nis ?? '').isNotEmpty) 'NIS: ${s.nis}',
                        if ((s.jenisKelamin ?? '').isNotEmpty) 'JK: ${s.jenisKelamin}',
                        if (s.tahunMasuk != null) 'Masuk: ${s.tahunMasuk}',
                        if (s.ketAktif != null) 'Aktif: ${s.ketAktif}',
                      ].join(' • ');

                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          s.namaLengkap.isEmpty ? '(Tanpa nama)' : s.namaLengkap,
                        ),
                        subtitle: Text(subtitle.isEmpty ? '-' : subtitle),
                        onTap: () => Navigator.pop(context, s),
                      );
                    },
                  );
                },
              ),
            ),
          ],
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
