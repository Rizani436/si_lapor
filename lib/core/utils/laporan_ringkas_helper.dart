import 'ringkas_item.dart';
import 'parse_laporan.dart';

Map<String, List<RingkasItem>> buildRingkasanDetail(
  List<Map<String, dynamic>> laporan
) {
  final result = {
    'ziyadahGuru': <RingkasItem>[],
    'murajaahGuru': <RingkasItem>[],
    'tasmiGuru': <RingkasItem>[],
    'ziyadahOrangTua': <RingkasItem>[],
    'murajaahOrangTua': <RingkasItem>[],
    'tasmiOrangTua': <RingkasItem>[],
  };

  for (final row in laporan) {
    if (row['pelapor'] == 'Guru') {
      final z = parseLaporan(row['ziyadah'], row['tanggal'] as String?, row['pelapor'] as String?);
      final m = parseLaporan(row['murajaah'], row['tanggal'] as String?, row['pelapor'] as String?);
      final t = parseLaporanTasmi(row['tasmi'], row['tanggal'] as String?, row['pelapor'] as String?);

      if (z != null) result['ziyadahGuru']!.add(z);
      if (m != null) result['murajaahGuru']!.add(m);
      if (t != null) result['tasmiGuru']!.add(t);
    } 
    else if (row['pelapor'] == 'Orang Tua') {
      final z = parseLaporan(row['ziyadah'], row['tanggal'] as String?, row['pelapor'] as String?);
      final m = parseLaporan(row['murajaah'], row['tanggal'] as String?, row['pelapor'] as String?);

      if (z != null) result['ziyadahOrangTua']!.add(z);
      if (m != null) result['murajaahOrangTua']!.add(m);
    }
  }

  return result;
}
