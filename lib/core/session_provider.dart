import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class SessionState {
  final bool isLoggedIn;
  final String? userId;
  final String? role;
  final String? fotoProfile;
  final String? namaLengkap;
  final String? email;
  final int avatarVersion;

  const SessionState({
    required this.isLoggedIn,
    required this.userId,
    required this.role,
    required this.fotoProfile,
    required this.namaLengkap,
    required this.email,
    required this.avatarVersion,
  });

  const SessionState.guest()
    : this(
        isLoggedIn: false,
        userId: null,
        role: null,
        fotoProfile: null,
        namaLengkap: null,
        email: null,
        avatarVersion: 0,
      );

  SessionState copyWith({
    bool? isLoggedIn,
    String? userId,
    String? role,
    String? fotoProfile,
    String? namaLengkap,
    String? email,
    int? avatarVersion,
  }) {
    return SessionState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      fotoProfile: fotoProfile ?? this.fotoProfile,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      avatarVersion: avatarVersion ?? this.avatarVersion,
    );
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SessionController extends Notifier<SessionState> {
  StreamSubscription<AuthState>? _authSub;

  @override
  SessionState build() {
    final user = supabase.auth.currentUser;

    state = (user == null)
        ? const SessionState.guest()
        : SessionState(
            isLoggedIn: true,
            userId: user.id,
            role: null,
            fotoProfile: null,
            namaLengkap: null,
            email: user.email,
            avatarVersion: 0,
          );

    if (user != null) {
      Future.microtask(refreshProfile);
    }

    _authSub?.cancel();
    _authSub = supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      final user = session?.user;

      if (event == AuthChangeEvent.signedOut || user == null) {
        state = const SessionState.guest();
        return;
      }

      // pertahankan avatarVersion biar cache-busting tetap konsisten
      final prevVersion = state.avatarVersion;

      state = SessionState(
        isLoggedIn: true,
        userId: user.id,
        role: null,
        fotoProfile: null,
        namaLengkap: null,
        email: user.email,
        avatarVersion: prevVersion,
      );

      await refreshProfile();
    });

    ref.onDispose(() {
      _authSub?.cancel();
      _authSub = null;
    });

    return state;
  }

  Future<void> refreshProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      state = const SessionState.guest();
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select('role, is_active, foto_profile, nama_lengkap, email, no_hp')
          .eq('id', user.id)
          .maybeSingle();

      final isActive = data?['is_active'] as bool?;
      if (isActive == false) {
        await supabase.auth.signOut();
        state = const SessionState.guest();
        return;
      }

      final newFoto = data?['foto_profile'] as String?;
      final oldFoto = state.fotoProfile;

      // ✅ kalau URL foto berubah, naikkan versi supaya UI reload gambar
      final nextVersion =
          (newFoto != null && newFoto.isNotEmpty && newFoto != oldFoto)
          ? state.avatarVersion + 1
          : state.avatarVersion;

      state = SessionState(
        isLoggedIn: true,
        userId: user.id,
        role: data?['role'] as String?,
        fotoProfile: newFoto,
        namaLengkap: data?['nama_lengkap'] as String?,
        email: (data?['email'] as String?) ?? user.email,
        avatarVersion: nextVersion,
      );
    } catch (e) {
      // jangan reset avatarVersion biar UI tetap stabil
      state = SessionState(
        isLoggedIn: true,
        userId: user.id,
        role: null,
        fotoProfile: state.fotoProfile,
        namaLengkap: state.namaLengkap,
        email: user.email,
        avatarVersion: state.avatarVersion,
      );
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    state = const SessionState.guest();
  }

  void bumpAvatarVersion() {
    state = state.copyWith(avatarVersion: state.avatarVersion + 1);
  }
}
