import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/guru_import_service.dart';

final guruImportServiceProvider = Provider<GuruImportService>((ref) {
  return GuruImportService(Supabase.instance.client);
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

final guruImportControllerProvider =
    AsyncNotifierProvider<GuruImportController, ImportResult?>(
  GuruImportController.new,
);

class GuruImportController extends AsyncNotifier<ImportResult?> {
  late final GuruImportService _service = ref.read(guruImportServiceProvider);

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
        'nip',
        'alamat',
        'jenis_kelamin',
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
        final nip = cell(col('nip'));
        final alamat = cell(col('alamat'));
        final jk = cell(col('jenis_kelamin'));
        final aktifStr = cell(col('ket_aktif'));

        final isEmptyRow = [nama, nip, alamat, jk, aktifStr]
            .every((e) => e.isEmpty);
        if (isEmptyRow) continue;

        if (nip.isEmpty) {
          errors.add('Baris ${r + 1}: NIP kosong.');
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

        final akt = int.tryParse(aktifStr);
        if (akt == null || (akt != 0 && akt != 1)) {
          errors.add('Baris ${r + 1}: ket_aktif harus 0 atau 1.');
          continue;
        }

        payload.add({
          'nama_lengkap': nama,
          'nip': nip,
          'alamat': alamat,
          'jenis_kelamin': jk,
          'ket_aktif': akt,
        });
      }

      await _service.upsertByNip(payload);

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
