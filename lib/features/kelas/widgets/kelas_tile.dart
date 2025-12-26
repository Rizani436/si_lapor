import 'package:flutter/material.dart';
import '../models/kelas_model.dart';

class KelasTile extends StatelessWidget {
  final KelasModel s;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAktif;

  const KelasTile({
    super.key,
    required this.s,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAktif,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${s.namaKelas.isNotEmpty ? s.namaKelas : '(Tanpa nama)'} (${s.kodeKelas})'),
      subtitle: Text(
        '${s.tahunPelajaran} (${s.semester})\n${s.jenisKelas}\nStatus: ${s.isAktif ? 'Aktif' : 'Nonaktif'}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'edit') onEdit();
          if (v == 'toggle') onToggleAktif();
          if (v == 'delete') onDelete();
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit'),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: Text(s.isAktif ? 'Nonaktifkan' : 'Aktifkan'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
