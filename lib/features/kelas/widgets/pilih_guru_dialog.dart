import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../guru/models/guru_model.dart';
import '../../guru/providers/guru_provider.dart';

Future<GuruModel?> showPilihGuruDialog(BuildContext context) async {
  return showDialog<GuruModel?>(
    context: context,
    builder: (_) => const _PilihGuruDialog(),
  );
}

class _PilihGuruDialog extends ConsumerStatefulWidget {
  const _PilihGuruDialog();

  @override
  ConsumerState<_PilihGuruDialog> createState() => _PilihGuruDialogState();
}

class _PilihGuruDialogState extends ConsumerState<_PilihGuruDialog> {
  final _q = TextEditingController();
  String query = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncGuru = ref.watch(guruListProvider);

    return AlertDialog(
      title: const Text('Pilih Guru'),
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
              child: asyncGuru.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => SingleChildScrollView(
                  child: Text('Error: $e'),
                ),
                data: (list) {
                  final filtered = list.where((s) {
                    final name = (s.namaLengkap).toLowerCase();
                    final nip = (s.nip ?? '').toLowerCase();
                    return query.isEmpty ||
                        name.contains(query) ||
                        nip.contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Tidak ada guru.'));
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = filtered[i];

                      final subtitle = [
                        if ((s.nip ?? '').isNotEmpty) 'NIS: ${s.nip}',
                        if ((s.jenisKelamin ?? '').isNotEmpty) 'JK: ${s.jenisKelamin}',
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
