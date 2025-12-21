import 'package:flutter/material.dart';
import '../models/guru_model.dart';

class GuruTile extends StatelessWidget {
  final GuruModel s;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleAktif;

  const GuruTile({
    super.key,
    required this.s,
    required this.onTap,
    required this.onDelete,
    required this.onToggleAktif,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(s.namaLengkap.isNotEmpty ? s.namaLengkap : '(Tanpa nama)'),
      subtitle: Text(
        'NIP: ${s.nip}\nStatus: ${s.isAktif ? 'Aktif' : 'Nonaktif'}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'toggle') onToggleAktif();
          if (v == 'delete') onDelete();
        },
        itemBuilder: (ctx) => [
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
