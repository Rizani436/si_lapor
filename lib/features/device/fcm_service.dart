import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmService {
  static final _fcm = FirebaseMessaging.instance;
  static final _supabase = Supabase.instance.client;

  static Future<void> initPermission() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> registerDevice() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final token = await _fcm.getToken();
    if (token == null) return;

    debugPrint('FCM REGISTER: $token');

    await _supabase.from('user_devices').upsert({
      'user_id': user.id,
      'fcm_token': token,
      'platform': 'android',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static void listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      debugPrint('FCM TOKEN REFRESH: $newToken');

      await _supabase.from('user_devices').upsert({
        'user_id': user.id,
        'fcm_token': newToken,
        'platform': 'android',
        'updated_at': DateTime.now().toIso8601String(),
      });
    });
  }
  Future<void> hapusToken() async {
  final supabase = Supabase.instance.client;
  final token = await FirebaseMessaging.instance.getToken();

  if (token != null) {
    await supabase
        .from('user_devices')
        .delete()
        .eq('fcm_token', token);
  }

  await supabase.auth.signOut();
}

}
