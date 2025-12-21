import 'package:supabase_flutter/supabase_flutter.dart';

class SiswaImportService {
  final SupabaseClient _db;
  SiswaImportService(this._db);

  Future<void> upsertByNis(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;

    const chunkSize = 200;
    for (var i = 0; i < rows.length; i += chunkSize) {
      final chunk = rows.sublist(i, (i + chunkSize).clamp(0, rows.length));
      await _db.from('datasiswa').upsert(
        chunk,
        onConflict: 'nis',
      );
    }
  }
}
