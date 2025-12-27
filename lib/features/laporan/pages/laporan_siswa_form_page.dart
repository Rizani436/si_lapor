import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../siswa/models/siswa_model.dart';
import '../../kelas/models/kelas_model.dart';
import '../providers/laporan_siswa_provider.dart';
import '../widgets/widgets_laporan_helper.dart';
import '../../../core/utils/text_helper.dart';

class LaporanSiswaFormPage extends ConsumerStatefulWidget {
  final SiswaModel? existing;
  final KelasModel? existingKelas;

  final Map<String, dynamic>? existingLaporanRow;
  final int? existingIdLaporan;

  const LaporanSiswaFormPage({
    super.key,
    this.existing,
    this.existingKelas,
    this.existingLaporanRow,
    this.existingIdLaporan,
  });

  @override
  ConsumerState<LaporanSiswaFormPage> createState() =>
      _LaporanSiswaFormPageState();
}

class _LaporanSiswaFormPageState extends ConsumerState<LaporanSiswaFormPage> {
  final _formKey = GlobalKey<FormState>();

  SiswaModel? siswa;
  KelasModel? kelas;

  DateTime? selectedDate;

  final Set<String> _openSections = {};

  late final TextEditingController tahsinC;
  late final TextEditingController zJuzC;
  late final TextEditingController zSurahC;
  late final TextEditingController zAyatC;

  late final TextEditingController mJuzC;
  late final TextEditingController mSurahC;
  late final TextEditingController mAyatC;

  late final TextEditingController tJuzC;
  late final TextEditingController tSurahC;
  late final TextEditingController tAyatC;

  late final TextEditingController prC;

  bool get isEdit => widget.existingIdLaporan != null;

  @override
  void initState() {
    super.initState();
    siswa = widget.existing;
    kelas = widget.existingKelas;

    selectedDate = DateTime.now();

    tahsinC = TextEditingController();

    zJuzC = TextEditingController();
    zSurahC = TextEditingController();
    zAyatC = TextEditingController();

    mJuzC = TextEditingController();
    mSurahC = TextEditingController();
    mAyatC = TextEditingController();

    tJuzC = TextEditingController();
    tSurahC = TextEditingController();
    tAyatC = TextEditingController();

    prC = TextEditingController();

    final row = widget.existingLaporanRow;
    if (row != null) {
      final t = row['tanggal']?.toString();
      if (t != null && t.isNotEmpty) {
        final parts = t.split('-');
        if (parts.length == 3) {
          selectedDate = DateTime(
            int.tryParse(parts[0]) ?? DateTime.now().year,
            int.tryParse(parts[1]) ?? DateTime.now().month,
            int.tryParse(parts[2]) ?? DateTime.now().day,
          );
        }
      }

      void fillJsaFromText({
        required String? text,
        required TextEditingController juz,
        required TextEditingController surah,
        required TextEditingController ayat,
      }) {
        final s = (text ?? '').toString().trim();
        if (s.isEmpty) return;

        for (final raw in s.split('\n')) {
          final line = raw.trim();
          final lower = line.toLowerCase();

          if (lower.startsWith('juz:')) {
            juz.text = line.substring(4).trim();
          } else if (lower.startsWith('surah:')) {
            surah.text = line.substring(6).trim();
          } else if (lower.startsWith('ayat:')) {
            ayat.text = line.substring(5).trim();
          }
        }
      }

      fillJsaFromText(
        text: row['ziyadah']?.toString(),
        juz: zJuzC,
        surah: zSurahC,
        ayat: zAyatC,
      );

      fillJsaFromText(
        text: row['murajaah']?.toString(),
        juz: mJuzC,
        surah: mSurahC,
        ayat: mAyatC,
      );

      fillJsaFromText(
        text: row['tasmi']?.toString(),
        juz: tJuzC,
        surah: tSurahC,
        ayat: tAyatC,
      );

      prC.text = (row['pr'] ?? '').toString();
      tahsinC.text = (row['tahsin'] ?? '').toString();

      bool hasJsa(
        TextEditingController a,
        TextEditingController b,
        TextEditingController c,
      ) {
        return a.text.trim().isNotEmpty ||
            b.text.trim().isNotEmpty ||
            c.text.trim().isNotEmpty;
      }

      if (hasJsa(zJuzC, zSurahC, zAyatC)) _openSections.add('ziyadah');
      if (hasJsa(mJuzC, mSurahC, mAyatC)) _openSections.add('murajaah');
      if (hasJsa(tJuzC, tSurahC, tAyatC)) _openSections.add('tasmi');
      if (prC.text.trim().isNotEmpty) _openSections.add('pr');
      if (tahsinC.text.trim().isNotEmpty) _openSections.add('tahsin');
    }
  }

  @override
  void dispose() {
    tahsinC.dispose();
    zJuzC.dispose();
    zSurahC.dispose();
    zAyatC.dispose();
    mJuzC.dispose();
    mSurahC.dispose();
    mAyatC.dispose();
    tJuzC.dispose();
    tSurahC.dispose();
    tAyatC.dispose();
    prC.dispose();

    super.dispose();
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
    if (picked == null) return;
    setState(() => selectedDate = picked);
  }

  Widget _sectionButton(String key, String label, IconData icon) {
    final active = _openSections.contains(key);
    return OutlinedButton.icon(
      onPressed: () => _toggle(key),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? Colors.grey.shade200 : null,
      ),
    );
  }

  void _toggle(String key) {
    setState(() {
      if (_openSections.contains(key)) {
        _openSections.remove(key);
      } else {
        _openSections.add(key);
      }
    });
  }

  Map<String, dynamic> _buildPayload({
    required int idRuangKelas,
    required int idDataSiswa,
    required String tanggalStr,
  }) {
    final ziyadah = buildJsaText(
      juz: zJuzC,
      surah: zSurahC,
      ayat: zAyatC,
    ).trim();
    final murajaah = buildJsaText(
      juz: mJuzC,
      surah: mSurahC,
      ayat: mAyatC,
    ).trim();
    final tasmi = buildJsaText(juz: tJuzC, surah: tSurahC, ayat: tAyatC).trim();
    final pr = prC.text.trim();
    final tahsin = tahsinC.text.trim();

    return {
      'id_ruang_kelas': idRuangKelas,
      'id_data_siswa': idDataSiswa,
      'tanggal': tanggalStr,
      'ziyadah': ziyadah.isEmpty ? null : ziyadah,
      'murajaah': murajaah.isEmpty ? null : murajaah,
      'tahsin': tahsin.isEmpty ? null : tahsin,
      'tasmi': tasmi.isEmpty ? null : tasmi,
      'pr': pr.isEmpty ? null : pr,
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final idDataSiswa = siswa?.idDataSiswa;
    final idRuangKelas = kelas?.idRuangKelas;
    final tanggalStr = selectedDate == null ? null : _fmtDate(selectedDate!);

    if (idDataSiswa == null || idRuangKelas == null || tanggalStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data siswa/kelas/tanggal belum lengkap')),
      );
      return;
    }

    bool isFilledPartially(
      TextEditingController j,
      TextEditingController s,
      TextEditingController a,
    ) {
      final jj = j.text.trim().isNotEmpty;
      final ss = s.text.trim().isNotEmpty;
      final aa = a.text.trim().isNotEmpty;
      return (jj || ss || aa) && !(jj && ss && aa);
    }

    if (_openSections.contains('tasmi') &&
        isFilledPartially(tJuzC, tSurahC, tAyatC)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tasmi harus lengkap: Juz, Surah, Ayat')),
      );
      return;
    }

    final payload = _buildPayload(
      idRuangKelas: idRuangKelas,
      idDataSiswa: idDataSiswa,
      tanggalStr: tanggalStr,
    );

    try {
      if (!isEdit) {
        await ref.read(laporanActionProvider.notifier).createLaporan(payload);
      } else {
        await ref
            .read(laporanActionProvider.notifier)
            .updateLaporan(widget.existingIdLaporan!, payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'Berhasil diupdate' : 'Berhasil ditambahkan',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(laporanActionProvider);
    final saving = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Laporan' : 'Buat Laporan')),
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
                        'Data Siswa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.badge),
                        title: const Text('Nama Siswa'),
                        subtitle: Text(siswa?.namaLengkap ?? '-'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.confirmation_number),
                        title: const Text('NIS'),
                        subtitle: Text(siswa?.nis ?? '-'),
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
                      const Text(
                        'Laporan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tanggal'),
                        subtitle: Text(
                          selectedDate == null ? '-' : _fmtDate(selectedDate!),
                        ),
                        trailing: TextButton(
                          onPressed: saving ? null : _pickDate,
                          child: const Text('Pilih'),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _sectionButton(
                            'tasmi',
                            'Tasmi',
                            Icons.record_voice_over,
                          ),
                          _sectionButton(
                            'ziyadah',
                            'Ziyadah',
                            Icons.add_circle_outline,
                          ),
                          _sectionButton('murajaah', 'Murajaah', Icons.refresh),
                          _sectionButton(
                            'tahsin',
                            'Tahsin',
                            Icons.school_outlined,
                          ),
                          _sectionButton('pr', 'PR', Icons.task_alt),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (_openSections.contains('tasmi')) ...[
                        jsaFields(
                          'Tasmi',
                          juz: tJuzC,
                          surah: tSurahC,
                          ayat: tAyatC,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_openSections.contains('ziyadah')) ...[
                        jsaFields(
                          'Ziyadah',
                          juz: zJuzC,
                          surah: zSurahC,
                          ayat: zAyatC,
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_openSections.contains('murajaah')) ...[
                        jsaFields(
                          'Murajaah',
                          juz: mJuzC,
                          surah: mSurahC,
                          ayat: mAyatC,
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_openSections.contains('tahsin')) ...[
                        oneField('Tahsin', tahsinC),
                        const SizedBox(height: 12),
                      ],
                      if (_openSections.contains('pr')) ...[
                        oneField('PR', prC),
                        const SizedBox(height: 12),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(isEdit ? Icons.save : Icons.add),
                          label: Text(
                            isEdit ? 'Simpan Perubahan' : 'Tambah Laporan',
                          ),
                          onPressed: saving ? null : _save,
                        ),
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
