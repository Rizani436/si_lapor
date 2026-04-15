import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:si_lapor/features/kelas/models/isi_ruang_kelas_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../siswa/models/siswa_model.dart';
import '../../kelas/models/kelas_model.dart';
import '../providers/laporan_siswa_provider.dart';
import '../widgets/widgets_laporan_helper.dart';
import '../../../core/utils/ringkas_item.dart';
import '../../../core/utils/text_helper.dart';
import '../../notifications/providers/notifikasi_provider.dart';
import '../providers/laporan_ringkas_provider.dart';
import '../../kelas/providers/isi_ruang_kelas_provider.dart';
import '../../siswa/data/siswa_service.dart';
import '../../siswa/providers/siswa_provider.dart';

class LaporanSiswaInput {
  Widget _sectionButton(
    String key,
    String label,
    IconData icon,
    Function(String) onToggle,
  ) {
    final active = _openSections.contains(key);
    return OutlinedButton.icon(
      onPressed: () => onToggle(key),
      icon: Icon(icon, size: 18),
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? Colors.white : Color(0xFF27AE60),
        side: const BorderSide(color: Colors.white),
        backgroundColor: active ? const Color(0xFF27AE60) : Colors.white,
      ),
      label: Text(label),
    );
  }

  final Set<String> _openSections = {};
  final int idSiswa;

  final TextEditingController tasmiJuzC = TextEditingController();
  final TextEditingController tasmiPredikatC = TextEditingController();

  final TextEditingController zJuzC = TextEditingController();
  final TextEditingController zSurahC = TextEditingController();
  final TextEditingController zAyatC = TextEditingController();

  final TextEditingController mJuzC = TextEditingController();
  final TextEditingController mSurahC = TextEditingController();
  final TextEditingController mAyatC = TextEditingController();

  final TextEditingController tJilidC = TextEditingController();
  final TextEditingController tHalamanC = TextEditingController();
  final TextEditingController tMateriC = TextEditingController();

  final TextEditingController prC = TextEditingController();

  final TextEditingController noteC = TextEditingController();

  LaporanSiswaInput(this.idSiswa);
}

class LaporanSemuaSiswaFormPage extends ConsumerStatefulWidget {
  final List<IsiRuangKelasModel>? existing;
  final KelasModel? existingKelas;

  const LaporanSemuaSiswaFormPage({
    super.key,
    this.existing,
    this.existingKelas,
  });

  @override
  ConsumerState<LaporanSemuaSiswaFormPage> createState() =>
      _LaporanSemuaSiswaFormPageState();
}

class _LaporanSemuaSiswaFormPageState
    extends ConsumerState<LaporanSemuaSiswaFormPage> {
  final Set<int> _selectedSiswaIds = {};
  final Map<int, Set<String>> _openSectionsPerSiswa = {};

  late List<LaporanSiswaInput> laporanInputs;
  List<IsiRuangKelasModel>? siswas;
  KelasModel? kelas;

  List<SiswaModel>? _siswaData;
  bool _isLoadingData = true;

  DateTime? selectedDate;

  void _toggleSection(int idSiswa, String key) {
    setState(() {
      _openSectionsPerSiswa.putIfAbsent(idSiswa, () => {});
      if (_openSectionsPerSiswa[idSiswa]!.contains(key)) {
        _openSectionsPerSiswa[idSiswa]!.remove(key);
      } else {
        _openSectionsPerSiswa[idSiswa]!.add(key);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    siswas = widget.existing;
    kelas = widget.existingKelas;

    laporanInputs = siswas!
        .map((s) => LaporanSiswaInput(s.idDataSiswa!))
        .toList();

    selectedDate = DateTime.now();

    _fetchFullSiswaData();

    for (final input in laporanInputs) {
      input.tasmiJuzC.addListener(() {
        if (input.tasmiJuzC.text.isNotEmpty) {
          setState(() => _selectedSiswaIds.add(input.idSiswa));
        }
      });
    }
  }

  String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Map<String, dynamic> _buildPayloadPerSiswa({
    required LaporanSiswaInput input,
    required int idRuangKelas,
    required String tanggalStr,
  }) {
    final tasmi = buildJPText(
      juz: input.tasmiJuzC,
      predikat: input.tasmiPredikatC,
    ).trim();

    final ziyadah = buildJsaText(
      juz: input.zJuzC,
      surah: input.zSurahC,
      ayat: input.zAyatC,
    ).trim();

    final murajaah = buildJsaText(
      juz: input.mJuzC,
      surah: input.mSurahC,
      ayat: input.mAyatC,
    ).trim();

    final tahsin = buildJHMText(
      jilid: input.tJilidC,
      halaman: input.tHalamanC,
      materi: input.tMateriC,
    ).trim();

    final pr = input.prC.text.trim();

    final note = input.noteC.text.trim();

    return {
      'id_ruang_kelas': idRuangKelas,
      'id_data_siswa': input.idSiswa,
      'tanggal': tanggalStr,
      'tasmi': tasmi.isEmpty ? null : tasmi,
      'ziyadah': ziyadah.isEmpty ? null : ziyadah,
      'murajaah': murajaah.isEmpty ? null : murajaah,
      'tahsin': tahsin.isEmpty ? null : tahsin,
      'pr': pr.isEmpty ? null : pr,
      'note': note.isEmpty ? null : note,
      'pelapor': 'Guru',
    };
  }

  Future<void> _save() async {
    if (_selectedSiswaIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 siswa')));
      return;
    }

    String? pesanError;
    for (final input in laporanInputs) {
      if (_selectedSiswaIds.contains(input.idSiswa)) {
        bool isAnyFilled =
            input.tasmiJuzC.text.trim().isNotEmpty ||
            input.tasmiPredikatC.text.trim().isNotEmpty ||
            input.zJuzC.text.trim().isNotEmpty ||
            input.zSurahC.text.trim().isNotEmpty ||
            input.zAyatC.text.trim().isNotEmpty ||
            input.mJuzC.text.trim().isNotEmpty ||
            input.mSurahC.text.trim().isNotEmpty ||
            input.mAyatC.text.trim().isNotEmpty ||
            input.tJilidC.text.trim().isNotEmpty ||
            input.tHalamanC.text.trim().isNotEmpty ||
            input.tMateriC.text.trim().isNotEmpty ||
            input.prC.text.trim().isNotEmpty ||
            input.noteC.text.trim().isNotEmpty;

        if (!isAnyFilled) {
          final siswa = _siswaData?.firstWhere(
            (s) => s.idDataSiswa == input.idSiswa,
          );
          pesanError = 'Laporan ${siswa?.namaLengkap ?? 'Siswa'} belum diisi.';
          break;
        }
      }
    }

    if (pesanError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesanError), backgroundColor: Colors.red),
      );
      return;
    }

    final idRuangKelas = kelas?.idRuangKelas;
    final tanggalStr = selectedDate == null ? null : _fmtDate(selectedDate!);

    if (idRuangKelas == null || tanggalStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal / kelas belum lengkap')),
      );
      return;
    }

    try {
      for (final input in laporanInputs) {
        if (!_selectedSiswaIds.contains(input.idSiswa)) continue;
        final siswa = _siswaData?.firstWhere(
          (s) => s.idDataSiswa == input.idSiswa,
        );

        final payload = _buildPayloadPerSiswa(
          input: input,
          idRuangKelas: idRuangKelas,
          tanggalStr: tanggalStr,
        );

        await ref.read(laporanActionProvider.notifier).createLaporan(payload);
        final uid = await ref
            .read(isiRuangKelasProvider)
            .getIdUser(
              isiruangkelasId: idRuangKelas,
              idDataSiswa: input.idSiswa,
            );

        if (uid != null) {
          final response = Supabase.instance.client.functions.invoke(
            'push-notification-v1',
            body: {
              'user_id': uid,
              'title': 'Laporan Baru',
              'body':
                  'Guru telah menambahkan laporan baru untuk ${siswa?.namaLengkap ?? 'Siswa'}.',
              'data': {'type': 'INFO'},
            },
          );
          await ref
              .read(notifikasiServiceProvider)
              .createNotifikasi(
                uid,
                title: 'Laporan Baru',
                body:
                    'Guru telah menambahkan laporan baru untuk  ${siswa?.namaLengkap ?? 'Siswa'}.',
              );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil menyimpan laporan')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _fetchFullSiswaData() async {
    try {
      if (siswas == null || siswas!.isEmpty) return;

      final futures = siswas!.map((s) {
        return ref.read(siswaServiceProvider).getSiswa(s.idDataSiswa!);
      }).toList();

      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _siswaData = results;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data siswa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(laporanActionProvider).isLoading;

    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan Semua Siswa')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFf6f2fa),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF27AE60),
                ),
                title: const Text(
                  'Tanggal Laporan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                subtitle: Text(
                  selectedDate == null ? '-' : _fmtDate(selectedDate!),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: ElevatedButton(
                  onPressed: _pickDate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Pilih',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Pilih siswa lalu isi laporan masing-masing',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: laporanInputs.map((input) {
                  final siswa = _siswaData?.firstWhere(
                    (s) => s.idDataSiswa == input.idSiswa,
                  );

                  final isSelected = _selectedSiswaIds.contains(input.idSiswa);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: isSelected,
                            title: Text(siswa?.namaLengkap ?? '-'),
                            subtitle: Text('NIS: ${siswa?.nis ?? '-'}'),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedSiswaIds.add(input.idSiswa);
                                } else {
                                  _selectedSiswaIds.remove(input.idSiswa);
                                }
                              });
                            },
                          ),

                          if (isSelected) ...[
                            const SizedBox(height: 8),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                input._sectionButton(
                                  'tasmi',
                                  'Tasmi',
                                  Icons.record_voice_over,
                                  (key) => _toggleSection(input.idSiswa, key),
                                ),
                                input._sectionButton(
                                  'ziyadah',
                                  'Ziyadah',
                                  Icons.add_circle_outline,
                                  (key) => _toggleSection(input.idSiswa, key),
                                ),
                                input._sectionButton(
                                  'murajaah',
                                  'Murajaah',
                                  Icons.refresh,
                                  (key) => _toggleSection(input.idSiswa, key),
                                ),
                                input._sectionButton(
                                  'tahsin',
                                  'Tahsin',
                                  Icons.school_outlined,
                                  (key) => _toggleSection(input.idSiswa, key),
                                ),
                                input._sectionButton(
                                  'pr',
                                  'PR',
                                  Icons.task_alt,
                                  (key) => _toggleSection(input.idSiswa, key),
                                ),
                                input._sectionButton(
                                  'note',
                                  'Note',
                                  Icons.note_alt,
                                  (key) => _toggleSection(input.idSiswa, key),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            if (_openSectionsPerSiswa[input.idSiswa]?.contains(
                                  'tasmi',
                                ) ??
                                false) ...[
                              jpFields(
                                'Tasmi',
                                juz: input.tasmiJuzC,
                                predikat: input.tasmiPredikatC,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_openSectionsPerSiswa[input.idSiswa]?.contains(
                                  'ziyadah',
                                ) ??
                                false) ...[
                              jsaFields(
                                'Ziyadah',
                                juz: input.zJuzC,
                                surah: input.zSurahC,
                                ayat: input.zAyatC,
                              ),
                              const SizedBox(height: 12),
                            ],

                            if (_openSectionsPerSiswa[input.idSiswa]?.contains(
                                  'murajaah',
                                ) ??
                                false) ...[
                              jsaFields(
                                'Murajaah',
                                juz: input.mJuzC,
                                surah: input.mSurahC,
                                ayat: input.mAyatC,
                              ),
                              const SizedBox(height: 12),
                            ],

                            if (_openSectionsPerSiswa[input.idSiswa]?.contains(
                                  'tahsin',
                                ) ??
                                false) ...[
                              jhmFields(
                                'Tahsin',
                                jilid: input.tJilidC,
                                halaman: input.tHalamanC,
                                materi: input.tMateriC,
                              ),
                              //   oneField('Tahsin', tahsinC),
                              const SizedBox(height: 12),
                            ],
                            if (_openSectionsPerSiswa[input.idSiswa]?.contains(
                                  'pr',
                                ) ??
                                false) ...[
                              oneField('PR', input.prC),
                              const SizedBox(height: 12),
                            ],
                            if (_openSectionsPerSiswa[input.idSiswa]?.contains(
                                  'note',
                                ) ??
                                false) ...[
                              oneField('Note', input.noteC),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _save,
                child: saving
                    ? const CircularProgressIndicator()
                    : const Text('Simpan Semua'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
