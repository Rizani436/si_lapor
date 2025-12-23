import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/session_provider.dart';
import '../../../core/supabase_client.dart';


final profileActionProvider =
    AsyncNotifierProvider<ProfileActionNotifier, void>(
      ProfileActionNotifier.new,
    );

class ProfileActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateEmail(WidgetRef ref, String email) async {
    state = const AsyncLoading();
    try {
      await ref.read(myProfileProvider.notifier).updateEmail(email);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<bool> changePasswordWithVerify({
    required String oldPassword,
    required String newPassword,
  }) async {
    final session = ref.read(sessionProvider);
    final email = (session.email ?? '').trim();
    if (email.isEmpty)
      throw Exception('Session tidak valid. Silakan login ulang.');

    state = const AsyncLoading();
    try {
      // reauth
      try {
        final reauth = await supabase.auth.signInWithPassword(
          email: email,
          password: oldPassword.trim(),
        );
        if (reauth.session == null || reauth.user == null) {
          state = const AsyncData(null);
          return false;
        }
      } on AuthException {
        state = const AsyncData(null);
        return false;
      }

      await supabase.auth.updateUser(
        UserAttributes(password: newPassword.trim()),
      );

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateNoHp({
    required String noHpDigitsOnly,
  }) async {
    final session = ref.read(sessionProvider);
    final uid = session.userId;
    if (uid == null) throw Exception('Session tidak valid. Silakan login ulang.');

    final digits = noHpDigitsOnly.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) throw Exception('Nomor HP wajib diisi.');

    state = const AsyncLoading();
    try {
      await supabase.from('profiles').update({'no_hp': digits}).eq('id', uid);

      // refresh profile biar UI langsung update
      await ref.read(myProfileProvider.notifier).refresh();

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
