import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:si_lapor/core/session/session_provider.dart';
import '../providers/isiruangkelas_provider.dart';
import '../providers/isiruangkelas_action_provider.dart';
import '../widgets/pilih_siswa_dialog.dart';
import '../widgets/pilih_guru_dialog.dart';

class EditIsiKelasPage extends ConsumerWidget {
  final int idRuangKelas;
  const EditIsiKelasPage({super.key, required this.idRuangKelas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRows = ref.watch(isiRuangKelasNamaProvider(idRuangKelas));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Isi Kelas')),
      body: asyncRows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rows) {
          final gurus = rows
              .where(
                (r) =>
                    r.idDataGuru != null &&
                    (r.namaGuru ?? '').trim().isNotEmpty,
              )
              .map((r) => r.namaGuru!.trim())
              .toSet()
              .toList();

          final siswas = rows
              .where(
                (r) =>
                    r.idDataSiswa != null &&
                    (r.namaSiswa ?? '').trim().isNotEmpty,
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Anggota Kelas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Siswa'),
                    onPressed: () async {
                      final picked = await showPilihSiswaDialog(context);
                      if (picked == null) return;

                      try {
                        await ref
                            .read(isiRuangKelasActionProvider)
                            .tambahSiswa(
                              idRuangKelas: idRuangKelas,
                              idDataSiswa: picked.idDataSiswa,
                            );

                        ref.invalidate(isiRuangKelasNamaProvider(idRuangKelas));

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Siswa ditambahkan: ${picked.namaLengkap}',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal tambah siswa: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (gurus.isNotEmpty) ...[
                const Text(
                  'Guru',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                ...gurus.map(
                  (g) => ListTile(
                    leading: const Icon(Icons.school),
                    title: Text(g),
                    trailing: IconButton(
                      tooltip: 'Ganti Guru',
                      icon: const Icon(Icons.swap_horiz),
                      onPressed: () async {
                        final picked = await showPilihGuruDialog(context);
                        if (picked == null) return;

                        final session = ref.read(sessionProvider);
                        final uid = session.userId;
                        if (uid == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Session tidak valid. Silakan login ulang.',
                                ),
                              ),
                            );
                          }
                          return;
                        }

                        try {
                          await ref
                              .read(isiRuangKelasActionProvider)
                              .updateData(
                                isiruangkelasId: idRuangKelas,
                                idUserGuru: uid,
                                idDataGuru: picked.idDataGuru,
                              );

                          ref.invalidate(
                            isiRuangKelasNamaProvider(idRuangKelas),
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Guru berhasil diganti menjadi: ${picked.namaLengkap}',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal mengganti guru: $e'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),

                const Divider(height: 24),
              ] else if (gurus.isEmpty) ...[
                const Text(
                  'Guru',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Belum ada data guru',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),

                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Data'),
                      onPressed: () async {
                        final picked = await showPilihGuruDialog(context);
                        if (picked == null) return;
                        final session = ref.read(sessionProvider);
                        final uid = session.userId;
                        if (uid == null)
                          throw Exception(
                            'Session tidak valid. Silakan login ulang.',
                          );

                        try {
                          await ref
                              .read(isiRuangKelasActionProvider)
                              .updateData(
                                isiruangkelasId: idRuangKelas,
                                idUserGuru: uid,
                                idDataGuru: picked.idDataGuru,
                              );

                          ref.invalidate(
                            isiRuangKelasNamaProvider(idRuangKelas),
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Data Guru ditambahkan: ${picked.namaLengkap}',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal tambah data guru: $e'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],

              const Text(
                'Siswa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (siswas.isEmpty)
                const Text('Belum ada siswa.')
              else
                ...siswas.map((s) {
                  final rowId = s.id; 
                  final nama = (s.namaSiswa ?? '-').trim();
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(nama),
                      subtitle: Text(
                        'row_id: ${rowId ?? "-"} | id_data_siswa: ${s.idDataSiswa} | id_user_siswa: ${s.idUserSiswa ?? "-"}',
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          if ((s.idUserSiswa ?? '').trim().isNotEmpty)
                            IconButton(
                              tooltip: 'Unlink (hapus id_user_siswa)',
                              icon: const Icon(Icons.link_off),
                              onPressed: () async {
                                if (rowId == null) return;

                                final ok = await _confirm(
                                  context,
                                  title: 'Unlink siswa?',
                                  msg:
                                      'Unlink hanya menghapus id_user_siswa (akun). id_data_siswa tetap.',
                                );
                                if (!ok) return;

                                await ref
                                    .read(isiRuangKelasActionProvider)
                                    .unlinkSiswa(isiruangkelasId: rowId);

                                ref.invalidate(
                                  isiRuangKelasNamaProvider(idRuangKelas),
                                );
                              },
                            ),

                          IconButton(
                            tooltip:
                                'Delete (hapus id_user_siswa & id_data_siswa)',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (rowId == null) return;

                              final ok = await _confirm(
                                context,
                                title: 'Delete relasi siswa?',
                                msg:
                                    'Delete akan menghapus id_user_siswa dan id_data_siswa (set NULL).',
                              );
                              if (!ok) return;

                              await ref
                                  .read(isiRuangKelasActionProvider)
                                  .deleteSiswaRelasi(isiruangkelasId: rowId);

                              ref.invalidate(
                                isiRuangKelasNamaProvider(idRuangKelas),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Future<int?> _showInputIdSiswaDialog(BuildContext context) async {
    final c = TextEditingController();
    return showDialog<int?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Siswa'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Masukkan id_data_siswa',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(c.text.trim())),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String msg,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}
