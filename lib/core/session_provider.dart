import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_client.dart';

class SessionState {
  final bool isLoggedIn;
  final String? userId;
  final String? role;

  const SessionState({
    required this.isLoggedIn,
    required this.userId,
    required this.role,
  });

  const SessionState.guest() : this(isLoggedIn: false, userId: null, role: null);

  SessionState copyWith({bool? isLoggedIn, String? userId, String? role}) {
    return SessionState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      role: role ?? this.role,
    );
  }
}

final sessionProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    final user = supabase.auth.currentUser;
    if (user == null) return const SessionState.guest();
    return SessionState(isLoggedIn: true, userId: user.id, role: null);
  }

  Future<void> refreshProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      state = const SessionState.guest();
      return;
    }

    final data = await supabase
        .from('profiles')
        .select('role, is_active')
        .eq('id', user.id)
        .maybeSingle();

    final isActive = data?['is_active'] as bool?;
    if (isActive == false) {
      await supabase.auth.signOut();
      state = const SessionState.guest();
      throw Exception('Akun dinonaktifkan oleh admin.');
    }

    final role = data?['role'] as String?;
    state = SessionState(isLoggedIn: true, userId: user.id, role: role);
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    state = const SessionState.guest();
  }
}
