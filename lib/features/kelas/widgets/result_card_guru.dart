
import 'package:flutter/material.dart';
import '../providers/gabung_kelas_provider(guru).dart';
class ResultCardGuru extends StatelessWidget {
  final GabungKelasState st;
  final GabungKelasNotifier notifier;

  const ResultCardGuru({required this.st, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (st.error != null) {
      return Text(
        'Error:\n${st.error}',
        style: const TextStyle(color: Colors.red),
      );
    }

    if (!st.checked) {
      return const Text('Masukkan kode kelas lalu tekan "Gabung Kelas".');
    }

    if (st.notFound) {
      return const Text(
        'Kelas tidak ada.',
        style: TextStyle(fontWeight: FontWeight.w600),
      );
    }

    if (st.idRuangKelas == null) {
      return const Text('Belum ada hasil.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kelas ditemukan)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pilih salah satu data guru:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (st.guruList.isEmpty)
          const Text('Tidak ada data guru untuk dipilih.')
        else
          ...st.guruList.map((s) {
            return RadioListTile<int>(
              value: s.idDataGuru,
              groupValue: st.selectedIdDataGuru,
              title: Text(
                s.namaLengkap.isNotEmpty ? s.namaLengkap : '(Tanpa nama)',
              ),
              onChanged: (v) {
                if (v != null) notifier.pilihGuru(v);
              },
            );
          }),
      ],
    );
  }
}