import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/change_password_service.dart';

final changePasswordServiceProvider = Provider<ChangePasswordService>((ref) {
  return ChangePasswordService(Supabase.instance.client);
});

final changePasswordControllerProvider =
    AsyncNotifierProvider<ChangePasswordController, void>(
  ChangePasswordController.new,
);

class ChangePasswordController extends AsyncNotifier<void> {
  ChangePasswordService get _svc => ref.read(changePasswordServiceProvider);

  @override
  Future<void> build() async {}

  Future<void> sendOtp({required String email}) async {
    state = const AsyncLoading();
    try {
      await _svc.sendOtpToEmail(email);
      state = const AsyncData(null);
    } on AuthException catch (e) {
      state = const AsyncData(null);
      throw Exception(e.message);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> verifyAndChange({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = const AsyncLoading();
    try {
      await _svc.verifyOtpAndChangePassword(
        email: email,
        code: code,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      state = const AsyncData(null);
    } on AuthException catch (e) {
      state = const AsyncData(null);
      throw Exception(e.message);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
