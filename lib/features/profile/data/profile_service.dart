import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _db;
  ProfileService(this._db);

  Future<ProfileModel> getMyProfile(String userId) async {
    final data = await _db
        .from('profiles')
        .select('id, role, is_active, foto_profile, nama_lengkap, email, no_hp')
        .eq('id', userId)
        .single();

    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel> updateProfile(String userId, Map<String, dynamic> patch) async {
    final data = await _db
        .from('profiles')
        .update(patch)
        .eq('id', userId)
        .select('id, role, is_active, foto_profile, nama_lengkap, email, no_hp')
        .single();

    return ProfileModel.fromJson(data);
  }

  /// Ubah password (Supabase Auth)
  Future<void> changePassword(String newPassword) async {
    await _db.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Ubah email (opsional) - biasanya butuh konfirmasi email
  Future<void> changeEmail(String newEmail) async {
    await _db.auth.updateUser(UserAttributes(email: newEmail));
  }

  /// Upload avatar ke Storage dan update profiles.foto_profile
  /// BUTUH bucket: "avatars" (public atau signed URL)
  Future<ProfileModel> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String originalFilename,
  }) async {
    final ext = p.extension(originalFilename).isNotEmpty
        ? p.extension(originalFilename)
        : '.jpg';

    final filePath = 'profile/$userId/avatar${ext.toLowerCase()}';

    await _db.storage.from('avatars').uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    // kalau bucket public:
    final publicUrl = _db.storage.from('avatars').getPublicUrl(filePath);

    return updateProfile(userId, {'foto_profile': publicUrl});
  }
}
