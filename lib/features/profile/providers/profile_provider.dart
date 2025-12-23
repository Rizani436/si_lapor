import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/session_provider.dart';
import '../data/profile_service.dart';
import '../models/profile_model.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(Supabase.instance.client);
});

final myProfileProvider =
    AsyncNotifierProvider<MyProfileNotifier, ProfileModel?>(
      MyProfileNotifier.new,
    );

class MyProfileNotifier extends AsyncNotifier<ProfileModel?> {
  late final ProfileService _service = ref.read(profileServiceProvider);

  @override
  Future<ProfileModel?> build() async {
    final session = ref.watch(sessionProvider);
    if (!session.isLoggedIn || session.userId == null) return null;

    return _service.getMyProfile(session.userId!);
  }

  Future<void> refresh() async {
    final session = ref.read(sessionProvider);
    if (!session.isLoggedIn || session.userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.getMyProfile(session.userId!),
    );
    // sync ke session state (foto/nama/email)
    await ref.read(sessionProvider.notifier).refreshProfile();
  }

  Future<void> updateNama(String nama) async {
    final session = ref.read(sessionProvider);
    final uid = session.userId;
    if (uid == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.updateProfile(uid, {'nama_lengkap': nama.trim()}),
    );
    await ref.read(sessionProvider.notifier).refreshProfile();
  }

  Future<void> updateNoHP(String noHp) async {
    final session = ref.read(sessionProvider);
    final uid = session.userId;
    if (uid == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.updateNoHP(uid, {'no_hp': noHp.trim()}),
    );
    await ref.read(sessionProvider.notifier).refreshProfile();
  }

  Future<void> updateEmail(String email) async {
    final session = ref.read(sessionProvider);
    final uid = session.userId;
    if (uid == null) return;

    final clean = email.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

    // 2) Update kolom email di profiles
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.updateEmail(uid, clean),
    );

    await ref.read(sessionProvider.notifier).refreshProfile();
  }

  Future<void> uploadAvatar(Uint8List bytes, String filename) async {
    final session = ref.read(sessionProvider);
    final uid = session.userId;
    if (uid == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.uploadAvatar(
        userId: uid,
        bytes: bytes,
        originalFilename: filename,
      ),
    );

    // sync session (ambil URL baru)
    await ref.read(sessionProvider.notifier).refreshProfile();

    // ✅ paksa bust cache di UI (drawer/navbar/profile)
    ref.read(sessionProvider.notifier).bumpAvatarVersion();
  }
}
