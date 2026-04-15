import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/dashboard_service.dart';
import '../../kelas/models/kelas_model.dart';
import '../../../core/session/session_provider.dart';
import '../../kelas/data/kelas_service.dart';
import '../models/teacher_dashboard_model.dart';
import '../models/parent_dashboard_model.dart';
import '../models/kepsek_dashboard_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final kelasGuruServiceProvider = Provider<KelasService>((ref) {
  return KelasService(ref.read(supabaseClientProvider));
});

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.read(supabaseClientProvider));
});

class StatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'Semua';

  void setStatus(String value) {
    state = value;
  }
}

final ruangkelasFilterProvider = NotifierProvider<StatusFilterNotifier, String>(
  StatusFilterNotifier.new,
);

final datasiswaFilterProvider = NotifierProvider<StatusFilterNotifier, String>(
  StatusFilterNotifier.new,
);

final dataguruFilterProvider = NotifierProvider<StatusFilterNotifier, String>(
  StatusFilterNotifier.new,
);

final profilesFilterProvider = NotifierProvider<StatusFilterNotifier, String>(
  StatusFilterNotifier.new,
);

final dashboardCountProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.read(dashboardServiceProvider);

  final ruangkelasStatus = ref.watch(ruangkelasFilterProvider);
  final datasiswaStatus = ref.watch(datasiswaFilterProvider);
  final dataguruStatus = ref.watch(dataguruFilterProvider);
  final profilesStatus = ref.watch(profilesFilterProvider);

  final results = await Future.wait([
    service.getCount('ruangkelas', ruangkelasStatus),
    service.getCount('datasiswa', datasiswaStatus),
    service.getCount('dataguru', dataguruStatus),
    service.getCount('profiles', profilesStatus),
  ]);

  return {
    'ruangkelas': results[0],
    'datasiswa': results[1],
    'dataguru': results[2],
    'profiles': results[3],
  };
});

final teacherDashboardProvider = FutureProvider<List<TeacherDashboardItem>>((
  ref,
) async {
  final service = ref.read(dashboardServiceProvider);
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser!;

  return service.getDashboardGuru(user.id);
});

final kepsekDashboardProvider =
    FutureProvider.family<
      List<KepsekDashboardItem>,
      ({String tahun, int semester})
    >((
      ref,
      arg, 
    ) async {
      final service = ref.read(dashboardServiceProvider);
      return service.getDashboardKepsek(arg.tahun, arg.semester);
    });

final siswaDashboardProvider = FutureProvider<List<ParentDashboardItem>>((
  ref,
) async {
  final service = ref.read(dashboardServiceProvider);
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser!;

  return service.getDashboardSiswa(user.id);
});
