import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client.dart';
import '../models/akun_model.dart';
import '../../../core/network/net_guard.dart';

class AkunService {
  final SupabaseClient _client;
  AkunService(this._client);

  static const String _table = 'profiles';

  Future<List<AkunModel>> getAll() async {
    return networkGuard(() async {
      final res = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false);

      return (res as List).map((e) => AkunModel.fromMap(e)).toList();
    }, 'Gagal mengambil daftar siswa');
  }

  Future<AkunModel> create({
    required AkunModel payload,
    required String password,
  }) async {
    return networkGuard(() async {
      await supabase.functions.invoke(
        'create-user',
        body: {
          'email': payload.email,
          'nama_lengkap': payload.namaLengkap,
          'no_hp': payload.noHp,
          'password': password.trim(),
          'role': payload.role,
        },
      );

      final res = await _client
          .from(_table)
          .select()
          .eq('email', payload.email!)
          .single();

      return AkunModel.fromMap(res);
    }, 'Gagal mengambil daftar siswa');
  }

  Future<AkunModel> update(
    String id,
    AkunModel payload,
    String? newPassword,
  ) async {
    return networkGuard(() async {
      await supabase.functions.invoke(
        'update-user',
        body: {
          'user_id': id,
          'email': payload.email,
          'nama_lengkap': payload.namaLengkap,
          'no_hp': payload.noHp,
          if (newPassword != null && newPassword.trim().isNotEmpty)
            'password': newPassword.trim(),
        },
      );

      final res = await _client
          .from(_table)
          .update(payload.toMap())
          .eq('id', id)
          .select()
          .single();

      return AkunModel.fromMap(res);
    }, 'Gagal mengambil daftar siswa');
  }

  Future<void> delete(String userId) async {
    return networkGuard(() async {
      await supabase.functions.invoke('delete-user', body: {'user_id': userId});
    }, 'Gagal mengambil daftar siswa');
  }

  Future<AkunModel> toggleAktif(AkunModel a) async {
    return networkGuard(() async {
      final next = !(a.isActive ?? true);

      final res = await _client
          .from(_table)
          .update({'is_active': next})
          .eq('id', a.id)
          .select()
          .single();

      return AkunModel.fromMap(res);
    }, 'Gagal mengambil daftar siswa');
  }
}
