import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/laporan_kepsek_provider.dart';
import '../widgets/widgets_laporan_helper.dart';
import '../../siswa/models/siswa_model.dart';
import '../../kelas/models/kelas_model.dart';
import '../../../core/utils/ringkas_item.dart';
import '../../../core/utils/text_helper.dart';

import '../providers/laporan_siswa_provider.dart';
import '../providers/rapor_provider.dart';
import '../providers/laporan_ringkas_provider.dart';
import 'laporan_siswa_form_page(guru).dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SearchMode { filter, siswa }

class LaporanKepSekPage extends ConsumerStatefulWidget {
  const LaporanKepSekPage({super.key});

  @override
  ConsumerState<LaporanKepSekPage> createState() => _LaporanKepSekPageState();
}

class _LaporanKepSekPageState extends ConsumerState<LaporanKepSekPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController tahunPelajaranC;
  late final TextEditingController semesterC;
  late final TextEditingController searchSiswaC; 
  final Map<String, bool> _showDetail = {
    'Ziyadah Guru': false,
    'Tasmi Guru': false,
    'Ziyadah Orang Tua': false,
    'Murajaah Orang Tua': false,
  };
  SearchMode _currentMode = SearchMode.filter;
  List<SiswaModel>? _foundSiswaList; 

  @override
  void initState() {
    super.initState();
    tahunPelajaranC = TextEditingController();
    semesterC = TextEditingController();
    searchSiswaC = TextEditingController();
  }

  @override
  void dispose() {
    ref.read(laporanKepsekProvider.notifier).reset();
    tahunPelajaranC.dispose();
    semesterC.dispose();
    searchSiswaC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(laporanKepsekProvider);
    final notifier = ref.read(laporanKepsekProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Laporan')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: SegmentedButton<SearchMode>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: const Color(0xFF27AE60),
                    selectedForegroundColor: Colors.white,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: SearchMode.filter,
                      label: Text('Tahun/Semester'),
                      icon: Icon(Icons.filter_alt),
                    ),
                    ButtonSegment(
                      value: SearchMode.siswa,
                      label: Text('Berdasarkan Siswa'),
                      icon: Icon(Icons.person),
                    ),
                  ],
                  selected: {_currentMode},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _currentMode = newSelection.first;
                      _foundSiswaList = null;  
                      _showDetail.clear(); 
                      notifier.reset();
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              if (_currentMode == SearchMode.filter) ...[
                TextFormField(
                  controller: tahunPelajaranC,
                  decoration: InputDecoration(
                    labelText: 'Tahun Pelajaran',
                    hintText: '2024-2025',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: semesterC,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Semester (Opsional)',
                    hintText: 'Isi 1 atau 2',
                    helperText: semesterC.text.isEmpty
                        ? 'Kosongkan untuk mencari SEMUA semester'
                        : 'Mencari spesifik Semester ${semesterC.text}',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.list_alt),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSearchButton(st.loading, () async {
                  if (!_formKey.currentState!.validate()) return;
                  await notifier.fetchSummary(
                    tahunPelajaran: tahunPelajaranC.text,
                    semester: semesterC.text.trim().isEmpty
                        ? null
                        : semesterC.text.trim(),
                  );
                }),

                const SizedBox(height: 24),
                _buildSummarySection(st),
              ] else ...[
                TextFormField(
                  controller: searchSiswaC,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Nama Siswa atau NIS',
                    hintText: 'Masukkan nama lengkap atau nomor induk...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF27AE60),
                    ),
                    suffixIcon: searchSiswaC.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchSiswaC.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama/NIS tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12),
                _buildSearchButton(st.loading, () async {
                  if (!_formKey.currentState!.validate()) return;

                  final searchText = searchSiswaC.text.trim();
                  try {
                    final List<SiswaModel> siswaList = await searchSiswaData(searchText);
                    final List<int> ids = siswaList.map((s) => s.idDataSiswa!).toList();

                    if (ids.isEmpty) {
                      setState(
                        () => _foundSiswaList = null,
                      ); 
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Siswa tidak ditemukan/Siswa tidak aktif')),
                      );
                      return;
                    }

                    setState(() {
                      _foundSiswaList = siswaList;
                    });
                  } catch (e) {
                    debugPrint("Error query siswa: $e");
                  }
                }),
                const SizedBox(height: 20),

                if (_foundSiswaList != null) ...[
                  if (_foundSiswaList!.length > 1) ...[
                    const Text("Ditemukan beberapa siswa, pilih salah satu:"),
                    const SizedBox(height: 8),
                    ..._foundSiswaList!.map(
                      (s) => Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(s.namaLengkap ?? '-'),
                          subtitle: Text("NIS: ${s.nis}"),
                          onTap: () {
                            setState(() {
                              _foundSiswaList = [s];
                            });
                          },
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildLaporanRingkas(_foundSiswaList!),

                    TextButton.icon(
                      onPressed: () => setState(() => _foundSiswaList = null),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Cari siswa lain"),
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<List<SiswaModel>> searchSiswaData(String query) async {
    final supabase = Supabase.instance.client;
    final res = await supabase
        .from('datasiswa')
        .select('id_data_siswa, nama_lengkap, nis')
        .eq('ket_aktif', 1)
        .or('nama_lengkap.ilike.%$query%,nis.eq.$query');

    return (res as List).map((item) => SiswaModel.fromJson(item)).toList();
  }

  Widget _buildRingkasContent(SiswaModel siswa) {
    final provider = laporanSeluruhRingkasDetailProvider((idSiswa: siswa.idDataSiswa!));

    final ringkasAsync = ref.watch(provider);

    return ringkasAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Gagal memuat ringkasan: $e'),
      data: (data) {
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  siswa.namaLengkap ?? '-',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "NIS: ${siswa.nis ?? '-'}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Ringkasan Laporan dari Guru",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 20),
                _buildRingkasSection(
                  'Ziyadah',
                  data['ziyadahGuru'] ?? [],
                  'Guru',
                ),
                const Divider(height: 20),
                _buildRingkasSection(
                  'Murajaah',
                  data['murajaahGuru'] ?? [],
                  'Guru',
                ),
                const Divider(height: 20),
                _buildRingkasSection('Tasmi', data['tasmiGuru'] ?? [], 'Guru'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRingkasSection(
    String title,
    List<RingkasItem> items,
    String pelapor,
  ) {
    final isOpen = _showDetail['$title $pelapor'] ?? false;
    if (items.isEmpty) {
      return Text('$title: -');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.contains('Tasmi')) ...[
          _buildRingkasTasmi(title, items, pelapor),
        ] else ...[
          _buildRingkas(title, items, pelapor),

          const SizedBox(height: 6),

          GestureDetector(
            onTap: () {
              setState(() {
                _showDetail['$title $pelapor'] = !isOpen;
              });
            },
            child: Text(
              isOpen ? 'Sembunyikan detail' : 'Lihat detail',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (isOpen) ...[
            const SizedBox(height: 8),
            _buildRingkasDetail(title, items),
          ],
        ],
      ],
    );
  }

  Widget _buildRingkas(String title, List<RingkasItem> items, String pelapor) {
    if (items.isEmpty) {
      return Text('$title: -');
    }

    final Map<int, Map<String, List<RingkasItem>>> grouped = {};

    for (final item in items) {
      if (item.pelapor != pelapor) continue;
      grouped
          .putIfAbsent(item.juz, () => {})
          .putIfAbsent(item.surah!, () => [])
          .add(item);
    }

    final lines = <Widget>[];

    grouped.forEach((juz, surahMap) {
      lines.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Juz $juz',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );

      surahMap.forEach((surah, list) {
        final minAyat = list
            .map((e) => getAyatMin(e.ayat!))
            .reduce((a, b) => a < b ? a : b);

        final maxAyat = list
            .map((e) => getAyatMax(e.ayat!))
            .reduce((a, b) => a > b ? a : b);

        final ayatText = minAyat == maxAyat ? '$minAyat' : '$minAyat-$maxAyat';

        lines.add(
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text('• $surah ayat $ayatText'),
          ),
        );
      });
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...lines,
      ],
    );
  }

  Widget _buildRingkasTasmi(
    String title,
    List<RingkasItem> items,
    String pelapor,
  ) {
    if (items.isEmpty) {
      return Text('$title: -');
    }

    final Map<int, List<RingkasItem>> grouped = {};

    for (final item in items) {
      if (item.pelapor != pelapor) continue;
      grouped.putIfAbsent(item.juz, () => []).add(item);
    }

    if (grouped.isEmpty) return const SizedBox.shrink();

    final lines = <Widget>[];

    grouped.forEach((juz, itemsInJuz) {
      final firstItem = itemsInJuz.first;

      lines.add(
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),

          child: Text(
            '• Juz $juz dengan Predikat: ${firstItem.predikat} pada tanggal: ${firstItem.tanggal}',
          ),
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...lines,
      ],
    );
  }

  Widget _buildLaporanRingkas(List<SiswaModel> siswas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan Ringkas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildRingkasContent(siswas.first),
      ],
    );
  }

  Widget _buildRingkasDetail(String title, List<RingkasItem> items) {
    if (items.isEmpty) {
      return Text('$title: -');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        ...items.map(
          (e) => Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Text(
              '• Juz ${e.juz} — ${e.surah} ayat ${e.ayat} (${e.tanggal} | ${e.pelapor})',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchButton(bool isLoading, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF27AE60),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.search),
        label: Text(isLoading ? 'Memuat...' : 'Cek Laporan'),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }

  Widget _buildSummarySection(LaporanKepsekState st) {
    return Column(
      children: [
        if (st.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(st.error!, style: const TextStyle(color: Colors.red)),
          ),
        SummarySectionCard(
          title: 'Reguler',
          memenuhi: st.memenuhiReguler,
          belum: st.belumReguler,
          items: st.summaryReguler,
        ),
        const SizedBox(height: 12),
        SummarySectionCard(
          title: 'Tahfiz',
          memenuhi: st.memenuhiTahfiz,
          belum: st.belumTahfiz,
          items: st.summaryTahfiz,
        ),
      ],
    );
  }
}
