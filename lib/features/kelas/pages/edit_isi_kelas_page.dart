import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:si_lapor/core/session/session_provider.dart';
import '../providers/isi_ruang_kelas_provider.dart';
import '../widgets/pilih_siswa_dialog.dart';
import '../widgets/pilih_guru_dialog.dart';
import '../../../core/UI/ui_helpers.dart';

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

                      final exists = await ref
                          .read(isiRuangKelasProvider)
                          .cekIdDataSiswa(
                            idRuangKelas: idRuangKelas,
                            idDataSiswa: picked.idDataSiswa,
                          );

                      if (exists) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Siswa sudah ada di dalam kelas.'),
                            ),
                          );
                        }
                        return;
                      }

                      try {
                        await ref
                            .read(isiRuangKelasProvider)
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

                ...gurus.map((g) {
                  final rowId = g.id;
                  final hasLinkedAccount = (g.idUserGuru ?? '')
                      .trim()
                      .isNotEmpty;

                  return ListTile(
                    leading: const Icon(Icons.school),
                    title: Text(g.namaGuru ?? '-'),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasLinkedAccount &&
                            ref.read(sessionProvider).role == 'admin')
                          IconButton(
                            icon: const Icon(Icons.link_off),
                            tooltip: 'Unlink (hapus id_user_guru)',
                            onPressed: () async {
                              if (rowId == null) return;

                              final ok = await confirm(
                                context,
                                title: 'Unlink guru?',
                                msg:
                                    'Unlink hanya menghapus id_user_guru (akun). id_data_guru tetap.',
                              );
                              if (!ok) return;

                              await ref
                                  .read(isiRuangKelasProvider)
                                  .unlinkGuru(isiruangkelasId: rowId);

                              ref.invalidate(
                                isiRuangKelasNamaProvider(idRuangKelas),
                              );
                            },
                          ),

                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          tooltip: 'Ganti Guru',
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

                                if (rowId == null) return;
                                await ref
                                    .read(isiRuangKelasProvider)
                                    .updateDataByAdmin(
                                      isiruangkelasId: rowId,
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
                      ],
                    ),
                  );
                }),

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
                        final role = session.role;
                        if (role == 'admin') {
                          try {
                            await ref
                                .read(isiRuangKelasProvider)
                                .tambahGuru(
                                  idRuangKelas: idRuangKelas,
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
                        } else {
                          try {
                            await ref
                                .read(isiRuangKelasProvider)
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

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((s.idUserSiswa ?? '').trim().isNotEmpty)
                            IconButton(
                              tooltip: 'Unlink (hapus id_user_siswa)',
                              icon: const Icon(Icons.link_off),
                              onPressed: () async {
                                if (rowId == null) return;

                                final ok = await confirm(
                                  context,
                                  title: 'Unlink siswa?',
                                  msg:
                                      'Unlink hanya menghapus id_user_siswa (akun). id_data_siswa tetap.',
                                );
                                if (!ok) return;

                                await ref
                                    .read(isiRuangKelasProvider)
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

                              final ok = await confirm(
                                context,
                                title: 'Delete relasi siswa?',
                                msg:
                                    'Delete akan menghapus id_user_siswa dan id_data_siswa (set NULL).',
                              );
                              if (!ok) return;

                              await ref
                                  .read(isiRuangKelasProvider)
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
}
