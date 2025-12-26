import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kelas_model.dart';
import '../providers/isiruangkelas_provider.dart';
import 'edit_isi_kelas_page.dart';
import '../../laporan/pages/laporan_siswa_list_page.dart';
import '../../siswa/providers/siswa_provider.dart';

class DetailKelasPage extends ConsumerStatefulWidget {
  final KelasModel? existing;
  const DetailKelasPage({super.key, this.existing});

  @override
  ConsumerState<DetailKelasPage> createState() => _DetailKelasPageState();
}

class _DetailKelasPageState extends ConsumerState<DetailKelasPage> {
  final _formKey = GlobalKey<FormState>();

  KelasModel? kelas;
  String namaKelas = '';
  String tahunPelajaran = '';
  int semester = 0;
  String jenisKelas = '';

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    kelas = s;
    namaKelas = s?.namaKelas ?? '';
    tahunPelajaran = s?.tahunPelajaran ?? '';
    semester = s?.semester ?? 1;
    jenisKelas = s?.jenisKelas ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final idRuangKelas = widget.existing?.idRuangKelas;

    return Scaffold(
      appBar: AppBar(
        title: Text(namaKelas.isEmpty ? 'Detail Kelas' : namaKelas),
      ),
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
                        'Informasi Kelas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.badge),
                        title: const Text('Nama Kelas'),
                        subtitle: Text(namaKelas.isEmpty ? '-' : namaKelas),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.date_range),
                        title: const Text('Tahun Pelajaran'),
                        subtitle: Text(
                          tahunPelajaran.isEmpty ? '-' : tahunPelajaran,
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.confirmation_number),
                        title: const Text('Semester'),
                        subtitle: Text(
                          semester <= 0 ? '-' : semester.toString(),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.category),
                        title: const Text('Jenis Kelas'),
                        subtitle: Text(jenisKelas.isEmpty ? '-' : jenisKelas),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          IconButton(
                            tooltip: 'Edit isi kelas',
                            icon: const Icon(Icons.edit),
                            onPressed: idRuangKelas == null
                                ? null
                                : () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditIsiKelasPage(
                                          idRuangKelas: idRuangKelas,
                                        ),
                                      ),
                                    );
                                    ref.invalidate(
                                      isiRuangKelasNamaProvider(idRuangKelas),
                                    );
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (idRuangKelas == null)
                        const Text('ID kelas tidak ditemukan.')
                      else
                        ref
                            .watch(isiRuangKelasNamaProvider(idRuangKelas))
                            .when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (e, _) => Text('Error: $e'),
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

                                if (gurus.isEmpty && siswas.isEmpty) {
                                  return const Text(
                                    'Belum ada anggota pada kelas ini.',
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (gurus.isNotEmpty) ...[
                                      const Text(
                                        'Guru',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...gurus.map(
                                        (name) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(Icons.school),
                                          title: Text(name),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    if (siswas.isNotEmpty) ...[
                                      const Text(
                                        'Siswa',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: siswas.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, i) {
                                          final s = siswas[i];
                                          final idDataSiswa = s.idDataSiswa!;
                                          final nama = (s.namaSiswa ?? '-')
                                              .trim();

                                          return ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: const Icon(Icons.person),
                                            title: Text(nama),
                                            trailing: const Icon(
                                              Icons.chevron_right,
                                            ),
                                            onTap: () async {
                                              final siswa = await ref
                                                  .read(
                                                    siswaListProvider.notifier,
                                                  )
                                                  .getSiswa(idDataSiswa);
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      LaporanSiswaListPage(
                                                        existing: siswa,
                                                        existingKelas: kelas,
                                                      ),
                                                ),
                                              );

                                              ref.invalidate(
                                                isiRuangKelasNamaProvider(
                                                  idRuangKelas,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
