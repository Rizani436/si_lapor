import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_client.dart';

class SessionState {
  final bool isLoggedIn;
  final String? userId;
  final String? role;
  final String? fotoProfile;
  final String? namaLengkap;
  final String? email;
  final int avatarVersion;

  final bool isBootstrapping;
  final bool isOffline;
  final String? offlineMessage;

  const SessionState({
    required this.isLoggedIn,
    required this.userId,
    required this.role,
    required this.fotoProfile,
    required this.namaLengkap,
    required this.email,
    required this.avatarVersion,
    required this.isBootstrapping,
    required this.isOffline,
    required this.offlineMessage,
  });

  const SessionState.guest({bool bootstrapping = false})
      : this(
          isLoggedIn: false,
          userId: null,
          role: null,
          fotoProfile: null,
          namaLengkap: null,
          email: null,
          avatarVersion: 0,
          isBootstrapping: bootstrapping,
          isOffline: false,
          offlineMessage: null,
        );

  SessionState copyWith({
    bool? isLoggedIn,
    String? userId,
    String? role,
    String? fotoProfile,
    String? namaLengkap,
    String? email,
    int? avatarVersion,
    bool? isBootstrapping,
    bool? isOffline,
    String? offlineMessage,
  }) {
    return SessionState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      fotoProfile: fotoProfile ?? this.fotoProfile,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      avatarVersion: avatarVersion ?? this.avatarVersion,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isOffline: isOffline ?? this.isOffline,
      offlineMessage: offlineMessage,
    );
  }
}

final sessionProvider =
    NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SessionController extends Notifier<SessionState> {
  StreamSubscription<AuthState>? _authSub;

  Future<bool> _checkOnline() async {
    try {
      await supabase.rpc('ping');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  SessionState build() {
    final user = supabase.auth.currentUser;

    state = (user == null)
        ? const SessionState.guest(bootstrapping: true)
        : SessionState(
            isLoggedIn: true,
            userId: user.id,
            role: null,
            fotoProfile: null,
            namaLengkap: null,
            email: user.email,
            avatarVersion: 0,
            isBootstrapping: true,
            isOffline: false,
            offlineMessage: null,
          );

    Future.microtask(() async {
      final online = await _checkOnline();
      if (!online) {
        state = state.copyWith(
          isBootstrapping: false,
          isOffline: true,
          offlineMessage:
              'Tidak ada koneksi internet / server tidak dapat dijangkau.',
        );
        return;
      }

      if (supabase.auth.currentUser != null) {
        await refreshProfile();
      } else {
        state = state.copyWith(
          isBootstrapping: false,
          isOffline: false,
          offlineMessage: null,
        );
      }
    });

    _authSub?.cancel();
    _authSub = supabase.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;

      if (user == null) {
        state = const SessionState.guest(bootstrapping: false);
        return;
      }

      state = state.copyWith(
        isLoggedIn: true,
        userId: user.id,
        email: user.email,
        isBootstrapping: true,
      );

      await refreshProfile();
    });

    ref.onDispose(() {
      _authSub?.cancel();
      _authSub = null;
    });

    return state;
  }

  Future<void> bootstrap() async {
    state = state.copyWith(
      isBootstrapping: true,
      isOffline: false,
      offlineMessage: null,
    );

    final online = await _checkOnline();
    if (!online) {
      state = state.copyWith(
        isBootstrapping: false,
        isOffline: true,
        offlineMessage:
            'Tidak ada koneksi internet / server tidak dapat dijangkau.',
      );
      return;
    }

    await refreshProfile();
  }

  Future<void> refreshProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      state = const SessionState.guest(bootstrapping: false);
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select('role, is_active, foto_profile, nama_lengkap, email')
          .eq('id', user.id)
          .maybeSingle();

      if (data?['is_active'] == false) {
        await supabase.auth.signOut();
        state = const SessionState.guest(bootstrapping: false);
        return;
      }

      final newFoto = data?['foto_profile'] as String?;
      final nextVersion =
          (newFoto != null && newFoto != state.fotoProfile)
              ? state.avatarVersion + 1
              : state.avatarVersion;

      state = SessionState(
        isLoggedIn: true,
        userId: user.id,
        role: data?['role'] as String?,
        fotoProfile: newFoto,
        namaLengkap: data?['nama_lengkap'] as String?,
        email: data?['email'] as String? ?? user.email,
        avatarVersion: nextVersion,
        isBootstrapping: false,
        isOffline: false,
        offlineMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isBootstrapping: false,
        isOffline: true,
        offlineMessage:
            'Tidak ada koneksi internet / server tidak dapat dijangkau.',
      );
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    state = const SessionState.guest(bootstrapping: false);
  }

  void bumpAvatarVersion() {
    state = state.copyWith(avatarVersion: state.avatarVersion + 1);
  }
}
