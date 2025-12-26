
import 'package:flutter/material.dart';
import '../providers/gabung_kelas_provider.dart';
class ResultCard extends StatelessWidget {
  final GabungKelasState st;
  final GabungKelasNotifier notifier;

  const ResultCard({required this.st, required this.notifier});

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
          'Kelas ditemukan ✅ (id_ruang_kelas: ${st.idRuangKelas})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pilih salah satu data siswa:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (st.siswaList.isEmpty)
          const Text('Tidak ada data siswa untuk dipilih.')
        else
          ...st.siswaList.map((s) {
            return RadioListTile<int>(
              value: s.idDataSiswa,
              groupValue: st.selectedIdDataSiswa,
              title: Text(
                s.namaLengkap.isNotEmpty ? s.namaLengkap : '(Tanpa nama)',
              ),
              onChanged: (v) {
                if (v != null) notifier.pilihSiswa(v);
              },
            );
          }),
      ],
    );
  }
}