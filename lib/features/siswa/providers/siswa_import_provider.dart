import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/siswa_import_service.dart';

final siswaImportServiceProvider = Provider<SiswaImportService>((ref) {
  return SiswaImportService(Supabase.instance.client);
});

class ImportResult {
  final int totalRows;
  final int successRows;
  final List<String> errors;

  ImportResult({
    required this.totalRows,
    required this.successRows,
    required this.errors,
  });
}

final siswaImportControllerProvider =
    AsyncNotifierProvider<SiswaImportController, ImportResult?>(
  SiswaImportController.new,
);

class SiswaImportController extends AsyncNotifier<ImportResult?> {
  late final SiswaImportService _service = ref.read(siswaImportServiceProvider);

  @override
  Future<ImportResult?> build() async => null;

  Future<ImportResult> importXlsxBytes(Uint8List bytes) async {
    state = const AsyncLoading();

    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        throw Exception('File Excel tidak memiliki sheet.');
      }

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;
      if (sheet.rows.isEmpty) throw Exception('Sheet kosong.');

      final headerRow = sheet.rows.first;
      final headers = headerRow
          .map((c) => (c?.value?.toString() ?? '').trim())
          .toList();

      const requiredHeaders = [
        'nama_lengkap',
        'nis',
        'alamat',
        'jenis_kelamin',
        'tahun_masuk',
        'tanggal_lahir',
        'ket_aktif',
      ];

      for (final h in requiredHeaders) {
        if (!headers.contains(h)) {
          throw Exception('Header "$h" tidak ditemukan. Gunakan template.');
        }
      }

      int col(String name) => headers.indexOf(name);

      final List<Map<String, dynamic>> payload = [];
      final List<String> errors = [];

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];

        String cell(int idx) {
          if (idx < 0 || idx >= row.length) return '';
          return (row[idx]?.value?.toString() ?? '').trim();
        }

        final nama = cell(col('nama_lengkap'));
        final nis = cell(col('nis'));
        final alamat = cell(col('alamat'));
        final jk = cell(col('jenis_kelamin'));
        final tahunMasuk = cell(col('tahun_masuk'));
        final tgl = cell(col('tanggal_lahir'));
        final aktifStr = cell(col('ket_aktif'));

        final isEmptyRow = [nama, nis, alamat, jk, tahunMasuk, tgl, aktifStr]
            .every((e) => e.isEmpty);
        if (isEmptyRow) continue;

        if (nis.isEmpty) {
          errors.add('Baris ${r + 1}: NIS kosong.');
          continue;
        }
        if (nama.isEmpty) {
          errors.add('Baris ${r + 1}: nama_lengkap kosong.');
          continue;
        }
        if (jk.isNotEmpty && jk != 'L' && jk != 'P') {
          errors.add('Baris ${r + 1}: jenis_kelamin harus "L" atau "P".');
          continue;
        }

        final year = int.tryParse(tahunMasuk);
        if (year == null || year < 1990 || year > 2100) {
          errors.add('Baris ${r + 1}: tahun_masuk tidak valid.');
          continue;
        }

        final dt = DateTime.tryParse(tgl);
        if (dt == null) {
          errors.add('Baris ${r + 1}: tanggal_lahir harus format YYYY-MM-DD.');
          continue;
        }

        final akt = int.tryParse(aktifStr);
        if (akt == null || (akt != 0 && akt != 1)) {
          errors.add('Baris ${r + 1}: ket_aktif harus 0 atau 1.');
          continue;
        }

        payload.add({
          'nama_lengkap': nama,
          'nis': nis,
          'alamat': alamat,
          'jenis_kelamin': jk,
          'tahun_masuk': tahunMasuk,
          'tanggal_lahir':
              '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
          'ket_aktif': akt,
        });
      }

      await _service.upsertByNis(payload);

      final result = ImportResult(
        totalRows: payload.length + errors.length,
        successRows: payload.length,
        errors: errors,
      );

      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
