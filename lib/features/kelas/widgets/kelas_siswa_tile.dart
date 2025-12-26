import 'package:flutter/material.dart';
import '../models/kelas_model.dart';

class KelasSiswaTile extends StatelessWidget {
  final KelasModel s;
  final VoidCallback onTap;
  final VoidCallback onDetail;

  const KelasSiswaTile({
    super.key,
    required this.s,
    required this.onTap,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        '${s.namaKelas.isNotEmpty ? s.namaKelas : '(Tanpa nama)'} (${s.kodeKelas})',
      ),
      subtitle: Text(
        '${s.tahunPelajaran} (Semester ${s.semester})\n'
        '${s.jenisKelas}\n'
        'Status: ${s.isAktif ? 'Aktif' : 'Nonaktif'}',
      ),
      onTap: onTap,
      trailing: IconButton(
        icon: const Icon(Icons.drag_indicator),
        tooltip: 'Detail kelas',
        onPressed: onDetail,
      ),
      isThreeLine: true,
    );
  }
}
