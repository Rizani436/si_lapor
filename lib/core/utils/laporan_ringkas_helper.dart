import 'ringkas_item.dart';
import 'parse_laporan.dart';

Map<String, List<RingkasItem>> buildRingkasanDetail(
  List<Map<String, dynamic>> laporan,
) {
  final result = {
    'ziyadah': <RingkasItem>[],
    'murajaah': <RingkasItem>[],
    'tasmi': <RingkasItem>[],
  };

  for (final row in laporan) {
    final z = parseLaporan(row['ziyadah'], row['tanggal'] as String?, row['pelapor'] as String?);
    final m = parseLaporan(row['murajaah'], row['tanggal'] as String?, row['pelapor'] as String?);
    final t = parseLaporan(row['tasmi'], row['tanggal'] as String?, row['pelapor'] as String?);

    if (z != null) result['ziyadah']!.add(z);
    if (m != null) result['murajaah']!.add(m);
    if (t != null) result['tasmi']!.add(t);

  }

  return result;
}
