import 'package:flutter/material.dart';
import '../../../core/utils/quran_picker_helper.dart';
import '../../../core/utils/juz_map.dart';
import '../../../core/utils/hasil_laporan_helper.dart';


Widget jsaFields(
  String title, {
  required TextEditingController juz,
  required TextEditingController surah,
  required TextEditingController ayat,
}) {
  int? juzVal = int.tryParse(juz.text.trim());
  String? surahKeyVal = surah.text.trim().isEmpty
      ? null
      : normSurah(surah.text.trim());
  int? ayatVal = int.tryParse(ayat.text.trim());

  if (juzVal != null && (juzVal < 1 || juzVal > 30)) juzVal = null;

  return StatefulBuilder(
    builder: (context, setInner) {
      List<String> currentSurahKeys = (juzVal == null)
          ? <String>[]
          : surahKeysForJuz(juzVal!);

      if (juzVal != null &&
          surahKeyVal != null &&
          !currentSurahKeys.contains(surahKeyVal)) {
        surahKeyVal = null;
        surah.text = '';
        ayatVal = null;
        ayat.text = '';
      }

      ({int start, int end})? range;
      if (juzVal != null && surahKeyVal != null) {
        range = ayatRangeFor(juzVal!, surahKeyVal!);
      }

      void setJuz(int? v) {
        setInner(() {
          juzVal = v;
          juz.text = v?.toString() ?? '';

          surahKeyVal = null;
          surah.text = '';
          ayatVal = null;
          ayat.text = '';
        });
      }

      void setSurahKey(String? key) {
        setInner(() {
          surahKeyVal = key;
          surah.text = key == null ? '' : displaySurahFromKey(key);

          ayatVal = null;
          ayat.text = '';
        });
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            value: juzVal,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Juz',
              border: OutlineInputBorder(),
            ),
            items: allJuz()
                .map((j) => DropdownMenuItem(value: j, child: Text('Juz $j')))
                .toList(),
            onChanged: (v) => setJuz(v),
            validator: (v) {
              if (v == null) return 'Pilih Juz';
              if (v < 1 || v > 30) return 'Juz tidak valid';
              return null;
            },
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: surahKeyVal,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Surah',
              border: OutlineInputBorder(),
            ),
            items: currentSurahKeys
                .map(
                  (k) => DropdownMenuItem(
                    value: k,
                    child: Text(displaySurahFromKey(k)),
                  ),
                )
                .toList(),
            onChanged: (juzVal == null) ? null : (v) => setSurahKey(v),
            validator: (v) {
              if (juzVal == null) return null;
              if (v == null) return 'Pilih Surah';
              return null;
            },
          ),

          const SizedBox(height: 10),

          TextFormField(
            controller: ayat,
            keyboardType: TextInputType.text,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Ayat',
              hintText: 'Contoh: 7 atau 1-7',
              border: OutlineInputBorder(),
            ),
            validator: (_) {
              if (juzVal == null || surahKeyVal == null) return null;

              final raw = ayat.text.trim();
              if (raw.isEmpty) return 'Ayat wajib diisi';

              final m = RegExp(r'^(\d+)(?:\s*-\s*(\d+))?$').firstMatch(raw);
              if (m == null) return 'Format ayat: 7 atau 1-7';

              final a1 = int.parse(m.group(1)!);
              final a2 = m.group(2) == null ? a1 : int.parse(m.group(2)!);

              if (a1 <= 0 || a2 <= 0) return 'Ayat harus > 0';
              if (a2 < a1) return 'Range ayat tidak valid (contoh: 1-7)';

              final r = ayatRangeFor(juzVal!, surahKeyVal!);

              if (a1 < r.start || a1 > r.end || a2 < r.start || a2 > r.end) {
                return 'Ayat harus dalam range ${r.start}–${r.end}';
              }

              return null;
            },
          ),

          if (range != null) ...[
            const SizedBox(height: 8),
            Text(
              'Range ayat untuk ${displaySurahFromKey(surahKeyVal!)}: ${range.start}–${range.end}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ],
      );
    },
  );
}


Widget oneField(String label, TextEditingController c) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),

      TextFormField(
        controller: c,
        minLines: 1,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    ],
  );
}

class SummarySectionCard extends StatelessWidget {
  final String title;
  final int minWajib;
  final int memenuhi;
  final int belum;
  final List<TasmiSummary> items;

  const SummarySectionCard({
    required this.title,
    required this.minWajib,
    required this.memenuhi,
    required this.belum,
    required this.items,
  });

  String juzRangeText(List<int> juzSelesai) {
    if (juzSelesai.isEmpty) return 'Belum ada juz selesai';
    final min = juzSelesai.first;
    final max = juzSelesai.last;
    return (min == max) ? 'Juz $min' : 'Juz $min–$max';
  }

  double _pct(int part, int total) => total == 0 ? 0 : (part / total) * 100;

  @override
Widget build(BuildContext context) {
  final total = items.length;
  final pctSelesai = _pct(memenuhi, total);
  final pctBelum = _pct(belum, total);

  return Card(
    child: ExpansionTile(
      tilePadding: const EdgeInsets.all(14),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      title: Text(
        '$title (minimal $minWajib juz selesai)',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total siswa: $total'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : (memenuhi / total),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text('✅ Sudah selesai: $memenuhi (${pctSelesai.toStringAsFixed(1)}%)'),
            Text('⏳ Belum selesai: $belum (${pctBelum.toStringAsFixed(1)}%)'),
          ],
        ),
      ),

      children: [
        const Divider(height: 20),

        Row(
          children: [
            Expanded(child: MiniStat(label: 'Memenuhi', value: memenuhi.toString())),
            const SizedBox(width: 10),
            Expanded(child: MiniStat(label: 'Belum', value: belum.toString())),
          ],
        ),
        const SizedBox(height: 12),

        if (items.isEmpty)
          const Text('Tidak ada data untuk filter ini.')
        else
          ...items.map((s) {
            final nama = (s.nama?.isNotEmpty == true)
                ? s.nama!
                : 'Siswa #${s.idDataSiswa}';

            final range = juzRangeText(s.juzSelesai);
            final status = s.memenuhi ? 'Memenuhi' : 'Belum';


            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(nama),
              subtitle: Text(
                    '$range • Selesai: ${s.juzSelesai.length} juz',
                  ),
              trailing: Text(status),
            );
          }),
      ],
    ),
  );
}
}

class MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
