import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notifikasi_model.dart';

class NotifikasiService {
  final SupabaseClient sb;
  NotifikasiService(this.sb);

  String _requireUserId() {
    final uid = sb.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) throw Exception('User belum login');
    return uid;
  }

  Future<List<NotifikasiModel>> getMine() async {
    final uid = _requireUserId();

    final res = await sb
        .from('notifikasi')
        .select()
        .eq('id_user', uid)
        .order('created_at', ascending: false);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(NotifikasiModel.fromJson).toList();
  }

  Future<int> countUnread() async {
    final uid = _requireUserId();

    final res = await sb
        .from('notifikasi')
        .select('id_notifikasi')
        .eq('id_user', uid)
        .eq('is_read', 0);

    return (res as List).length;
  }

  Future<void> markRead(int idNotifikasi) async {
    final uid = _requireUserId();

    await sb
        .from('notifikasi')
        .update({'is_read': 1})
        .eq('id_notifikasi', idNotifikasi)
        .eq('id_user', uid);
  }

  Future<void> markAllRead() async {
    final uid = _requireUserId();

    await sb
        .from('notifikasi')
        .update({'is_read': 1})
        .eq('id_user', uid)
        .eq('is_read', 0);
  }

  Future<void> deleteNotifikasi(int idNotifikasi) async {
    final uid = _requireUserId();

    await sb
        .from('notifikasi')
        .delete()
        .eq('id_notifikasi', idNotifikasi)
        .eq('id_user', uid);
  }

  Future<void> createNotifikasi(
    String uid, {
    required String title,
    required String body,
  }) async {
    await sb.from('notifikasi').insert({
      'id_user': uid,
      'title': title,
      'body': body,
      'is_read': 0, // INT: 0 belum dibaca, 1 sudah dibaca
    });
  }
}
