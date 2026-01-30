import 'package:flutter/material.dart';
import '../models/siswa_model.dart';

class SiswaTile extends StatelessWidget {
  final SiswaModel s;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onToggleAktif;
  final bool selected;

  const SiswaTile({
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
          'NIS: ${s.nis}\n'
          'JK: ${s.jenisKelamin} • Tahun Masuk: ${s.tahunMasuk}\n'
          'Status: ${s.isAktif ? 'Aktif' : 'Nonaktif'}',
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
                    child: Text(
                      'Hapus',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),

        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
