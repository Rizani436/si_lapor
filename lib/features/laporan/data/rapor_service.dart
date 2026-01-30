import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/net_guard.dart';

class RaporService {
  final SupabaseClient _db;
  RaporService(this._db);

  static const String bucketName = 'rapor'; 
  static const String tableName = 'rapor';       
  static const String urlColumn = 'rapor';         

  Future<String?> getRaporUrl({
    required int idDataSiswa,
    required int idRuangKelas,
  }) async {
    return networkGuard(
      () async {
    final res = await _db
        .from(tableName)
        .select(urlColumn)
        .eq('id_data_siswa', idDataSiswa)
        .eq('id_ruang_kelas', idRuangKelas)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res == null) return null;
    return (res[urlColumn] as String?)?.trim();
    },
      'Gagal mengambil daftar siswa',
    );
  }

  Future<void> uploadRapor({
    required int idDataSiswa,
    required int idRuangKelas,
    required Uint8List bytes,
    required String originalFilename,
  }) async {
    return networkGuard(
      () async {
    final ext = p.extension(originalFilename).toLowerCase();

    const allowed = {'.pdf', '.doc', '.docx'};
    final safeExt = allowed.contains(ext) ? ext : '.pdf';

    final ts = DateTime.now().millisecondsSinceEpoch;
    final filePath = 'rapor/$idRuangKelas/$idDataSiswa/rapor_$ts$safeExt';

    await _db.storage.from(bucketName).uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeFromExt(safeExt),
          ),
        );

    final publicUrl = _db.storage.from(bucketName).getPublicUrl(filePath);

    await _db.from(tableName).upsert(
      {
        'id_data_siswa': idDataSiswa,
        'id_ruang_kelas': idRuangKelas,
        urlColumn: publicUrl,
        'updated_at': DateTime.now().toIso8601String(), 
      },
      onConflict: 'id_data_siswa,id_ruang_kelas', 
    );
    },
      'Gagal mengambil daftar siswa',
    );
  }

  Future<void> removeRapor({
    required int idDataSiswa,
    required int idRuangKelas,
  }) async {
    return networkGuard(
      () async {
    final row = await _db
        .from(tableName)
        .select(urlColumn)
        .eq('id_data_siswa', idDataSiswa)
        .eq('id_ruang_kelas', idRuangKelas)
        .maybeSingle();

    final url = (row?[urlColumn] as String?)?.trim();

    if (url != null && url.isNotEmpty) {
      final path = _tryExtractStoragePath(url, bucket: bucketName);
      if (path != null) {
        try {
          await _db.storage.from(bucketName).remove([path]);
        } catch (_) {
        }
      }
    }

    await _db
        .from(tableName)
        .update({urlColumn: null})
        .eq('id_data_siswa', idDataSiswa)
        .eq('id_ruang_kelas', idRuangKelas);
        },
      'Gagal mengambil daftar siswa',
    );
  }

  String _contentTypeFromExt(String ext) {
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  String? _tryExtractStoragePath(String url, {required String bucket}) {
    final marker = '/storage/v1/object/public/$bucket/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    final start = idx + marker.length;
    if (start >= url.length) return null;
    return url.substring(start);
  }
}
