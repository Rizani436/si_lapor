import 'package:flutter/material.dart';

class LaporanSiswaTile extends StatelessWidget {
  final Map<String, dynamic> laporan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LaporanSiswaTile({
    super.key,
    required this.laporan,
    required this.onEdit,
    required this.onDelete,
  });
  

  String? _visibleText(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  Widget _section(String label, String value, {bool multiline = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(multiline ? '$label:\n$value' : '$label: $value'),
      const Divider(height: 6),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    final tgl = laporan['tanggal']?.toString() ?? '';

    final ziyadah = _visibleText(laporan['ziyadah']);
    final murajaah = _visibleText(laporan['murajaah']);
    final tahsin = _visibleText(laporan['tahsin']);
    final tasmi = _visibleText(laporan['tasmi']);
    final pr = _visibleText(laporan['pr']);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Laporan • $tgl',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),

            const SizedBox(height: 6),
            if (ziyadah != null) _section('Ziyadah', ziyadah, multiline: true),
            if (murajaah != null)
              _section('Murajaah', murajaah, multiline: true),
            if (tahsin != null) _section('Tahsin', tahsin),
            if (tasmi != null) _section('Tasmi', tasmi, multiline: true),
            if (pr != null) Text('PR: $pr'),
          ],
        ),
      ),
    );
  }
  
}
