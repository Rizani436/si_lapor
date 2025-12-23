import 'package:flutter/material.dart';
import '../models/akun_model.dart';

class AkunTile extends StatelessWidget {
  final AkunModel p;
  final VoidCallback onTap;
  final Future<void> Function() onDelete; // 🔧 ubah
  final VoidCallback onToggleAktif;

  const AkunTile({
    super.key,
    required this.p,
    required this.onTap,
    required this.onDelete,
    required this.onToggleAktif,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = p.isActive ?? true;
    final status = isActive ? 'Aktif' : 'Nonaktif';

    final hasPhoto = p.fotoProfile != null && p.fotoProfile!.trim().isNotEmpty;
    final photoUrl = hasPhoto
        ? '${p.fotoProfile!}?v=${DateTime.now().millisecondsSinceEpoch}'
        : null;

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        child: photoUrl == null
            ? Icon(Icons.person, color: Colors.grey.shade600)
            : null,
        onBackgroundImageError: photoUrl != null ? (_, __) {} : null,
      ),
      title: Text(
        p.namaLengkap?.isNotEmpty == true ? p.namaLengkap! : '(Tanpa nama)',
      ),
      subtitle: Text(
        '${p.email ?? ''}\nHP: ${p.noHp ?? '-'}\nRole: ${p.role ?? 'parent'} • $status',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'toggle') onToggleAktif();
          if (v == 'delete') {
            final confirm = await _confirmDelete(context);
            if (confirm == true) await onDelete();
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'toggle',
            child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
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

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: Text(
          'Yakin ingin menghapus akun "${p.namaLengkap ?? 'ini'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
