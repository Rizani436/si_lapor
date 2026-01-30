import 'package:flutter/material.dart';
import '../models/guru_model.dart';

class GuruTile extends StatelessWidget {
  final GuruModel s;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onToggleAktif;
  final bool selected;

  const GuruTile({
    super.key,
    required this.s,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onToggleAktif,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected ? Colors.blue.withOpacity(0.12) : null,
      child: ListTile(
        title: Text(
          s.namaLengkap.isNotEmpty ? s.namaLengkap : '(Tanpa nama)',
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),

        subtitle: Text(
          'NIP: ${s.nip}\nStatus: ${s.isAktif ? 'Aktif' : 'Nonaktif'}',
        ),

        trailing: selected
            ? null
            : PopupMenuButton<String>(
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
        onLongPress: onLongPress,
      ),
    );
  }
}
