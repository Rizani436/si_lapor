import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase_client.dart';
import '../models/akun_model.dart';

class AdminAccountsState {
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final int pageSize;

  final String search;

  // FILTER (client-side)
  final String roleFilter; // 'all' | 'admin' | 'guru' | 'kepsek' | 'parent'
  final String statusFilter; // 'all' | 'active' | 'inactive'

  // items = hasil yang tampil (sudah filter+search client-side)
  final List<AkunModel> items;
  final String? error;

  const AdminAccountsState({
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.pageSize,
    required this.search,
    required this.roleFilter,
    required this.statusFilter,
    required this.items,
    required this.error,
  });

  const AdminAccountsState.initial()
    : loading = false,
      loadingMore = false,
      hasMore = true,
      pageSize = 20,
      search = '',
      roleFilter = 'all',
      statusFilter = 'all',
      items = const [],
      error = null;

  AdminAccountsState copyWith({
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? pageSize,
    String? search,
    String? roleFilter,
    String? statusFilter,
    List<AkunModel>? items,
    String? error,
  }) {
    return AdminAccountsState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      roleFilter: roleFilter ?? this.roleFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      items: items ?? this.items,
      error: error,
    );
  }
}

final adminAccountsProvider =
    NotifierProvider<AdminAccountsController, AdminAccountsState>(
      AdminAccountsController.new,
    );

class AdminAccountsController extends Notifier<AdminAccountsState> {
  // buffer raw dari server (tanpa filter/search)
  final List<AkunModel> _buffer = [];

  @override
  AdminAccountsState build() {
    state = const AdminAccountsState.initial();
    loadFirstPage();
    return state;
  }

  // Server query: SELECT + ORDER + RANGE saja (paling kompatibel)
  dynamic _baseQueryServer() {
    return supabase
        .from('profiles')
        .select('id, email, nama_lengkap, no_hp, role, is_active, foto_profile')
        .order('nama_lengkap', ascending: true);
  }

  // Apply FILTER + SEARCH di client-side
  List<AkunModel> _applyClientFilterSearch(List<AkunModel> list) {
    Iterable<AkunModel> it = list;

    // Role filter
    if (state.roleFilter != 'all') {
      it = it.where((x) => (x.role ?? 'parent') == state.roleFilter);
    }

    // Status filter
    if (state.statusFilter == 'active') {
      it = it.where((x) => x.isActive == true);
    } else if (state.statusFilter == 'inactive') {
      it = it.where((x) => x.isActive == false);
    }

    // Search
    final s = state.search.trim().toLowerCase();
    if (s.isNotEmpty) {
      it = it.where((x) {
        final nama = (x.namaLengkap ?? '').toLowerCase();
        final email = (x.email ?? '').toLowerCase();
        return nama.contains(s) || email.contains(s);
      });
    }

    return it.toList();
  }

  Future<List<AkunModel>> _fetchServerPage({
    required int start,
    required int end,
  }) async {
    final res = await _baseQueryServer().range(start, end);
    return (res as List)
        .map((e) => AkunModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // Pastikan item yang tampil minimal "pageSize" kalau memungkinkan,
  // dengan fetch page tambahan sampai cukup / habis.
  Future<void> _ensureVisibleFill() async {
    while (true) {
      final visible = _applyClientFilterSearch(_buffer);

      // kalau sudah cukup ditampilkan (atau memang pageSize kecil), stop
      if (visible.length >= state.pageSize) {
        state = state.copyWith(items: List.unmodifiable(visible));
        return;
      }

      // kalau server sudah habis, stop
      if (!state.hasMore) {
        state = state.copyWith(items: List.unmodifiable(visible));
        return;
      }

      // fetch page berikutnya
      final start = _buffer.length;
      final end = start + state.pageSize - 1;

      final fetched = await _fetchServerPage(start: start, end: end);
      _buffer.addAll(fetched);

      // update hasMore
      state = state.copyWith(hasMore: fetched.length == state.pageSize);

      // jika fetched kosong, berarti habis
      if (fetched.isEmpty) {
        final v = _applyClientFilterSearch(_buffer);
        state = state.copyWith(items: List.unmodifiable(v), hasMore: false);
        return;
      }
    }
  }

  // ===== Pagination =====
  Future<void> loadFirstPage() async {
    try {
      state = state.copyWith(
        loading: true,
        loadingMore: false,
        hasMore: true,
        items: const [],
        error: null,
      );

      _buffer.clear();

      final fetched = await _fetchServerPage(start: 0, end: state.pageSize - 1);
      _buffer.addAll(fetched);

      state = state.copyWith(
        loading: false,
        hasMore: fetched.length == state.pageSize,
      );

      await _ensureVisibleFill();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;

    try {
      state = state.copyWith(loadingMore: true, error: null);

      final start = _buffer.length;
      final end = start + state.pageSize - 1;

      final fetched = await _fetchServerPage(start: start, end: end);
      _buffer.addAll(fetched);

      state = state.copyWith(
        loadingMore: false,
        hasMore: fetched.length == state.pageSize,
      );

      await _ensureVisibleFill();
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  // ===== Search & Filter setters =====
  void setSearch(String value) => state = state.copyWith(search: value);
  void setRoleFilter(String value) => state = state.copyWith(roleFilter: value);
  void setStatusFilter(String value) =>
      state = state.copyWith(statusFilter: value);

  // Karena filter/search client-side, apply cukup hitung ulang + fill
  Future<void> applySearch() async {
    state = state.copyWith(loading: true, error: null);
    state = state.copyWith(loading: false);
    await _ensureVisibleFill();
  }

  Future<void> applyFilters() async {
    state = state.copyWith(loading: true, error: null);
    state = state.copyWith(loading: false);
    await _ensureVisibleFill();
  }

  Future<void> refresh() async => loadFirstPage();

  void resetFilters() {
    state = state.copyWith(roleFilter: 'all', statusFilter: 'all', search: '');
  }

  // ===== Mutations (UPDATE builder kamu sudah support match) =====
  Future<void> updateRole({
    required String userId,
    required String role,
  }) async {
    await supabase.from('profiles').update({'role': role}).match({
      'id': userId,
    });
    await loadFirstPage();
  }

  Future<void> setActive({
    required String userId,
    required bool isActive,
  }) async {
    await supabase.from('profiles').update({'is_active': isActive}).match({
      'id': userId,
    });
    await loadFirstPage();
  }

  Future<void> hardDeleteUser(String userId) async {
    await supabase.functions.invoke('delete-user', body: {'user_id': userId});
    await loadFirstPage();
  }

  Future<void> createUser({
    required String email,
    required String namaLengkap,
    required String noHp,
    required String password,
    required String role,
  }) async {
    await supabase.functions.invoke(
      'create-user',
      body: {
        'email': email.trim(),
        'nama_lengkap': namaLengkap.trim(),
        'no_hp': noHp.trim(),
        'password': password,
        'role': role.trim(),
      },
    );

    await loadFirstPage();
  }
  

  Future<void> updateUserFull({
    required String userId,
    required String email,
    required String namaLengkap,
    required String noHp,
    String? password, // optional
    String? fotoProfile, // optional
  }) async {
    await supabase.functions.invoke(
      'update-user',
      body: {
        'user_id': userId,
        'email': email.trim(),
        'nama_lengkap': namaLengkap.trim(),
        'no_hp': noHp.trim(),
        if (password != null && password.trim().isNotEmpty)
          'password': password,
        if (fotoProfile != null)
          'foto_profile': fotoProfile.trim().isEmpty
              ? null
              : fotoProfile.trim(),
      },
    );

    await loadFirstPage();
  }
}
