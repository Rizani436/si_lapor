import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../../../core/config/supabase_client.dart';

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

  Future<ProfileModel> updateProfile(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    final data = await _db
        .from('profiles')
        .update(patch)
        .eq('id', userId)
        .select('id, role, is_active, foto_profile, nama_lengkap, email, no_hp')
        .single();

    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel> updateEmail(
    String id,
    String email
  ) async {
    await supabase.functions.invoke(
      'update-user',
      body: {
        'user_id': id,
        'email': email,
      },
    );

    // 2) Update profiles (data tampilan)
    final res = await _db
        .from('profiles')
        .update({'email': email})
        .eq('id', id)
        .select()
        .single();

    return ProfileModel.fromJson(res);
  }

  Future<void> changeMyEmail(String email) async {
  await supabase.auth.updateUser(
    UserAttributes(email: email),
  );
}


  

  Future<ProfileModel> updateNoHP(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    await supabase.functions.invoke(
      'update-user',
      body: {'user_id': userId, 'no_hp': patch['no_hp']},
    );
    final data = await _db
        .from('profiles')
        .update(patch)
        .eq('id', userId)
        .select('id, role, is_active, foto_profile, nama_lengkap, email, no_hp')
        .single();

    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel> updatePassword(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    await supabase.functions.invoke(
      'update-user',
      body: {'user_id': userId, 'password': patch['password']},
    );
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

  /// Upload avatar ke Storage dan update profiles.foto_profile
  /// BUTUH bucket: "avatars" (public atau signed URL)
  Future<ProfileModel> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String originalFilename,
  }) async {
    final ext = p.extension(originalFilename).toLowerCase();
    final safeExt =
        (ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp')
        ? ext
        : '.jpg';

    final filePath = 'profile/$userId/avatar$safeExt';

    await _db.storage
        .from('fotoprofile') // ✅ bucket kamu
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeFromExt(safeExt),
          ),
        );

    // ✅ bucket public: URL publik permanen
    final publicUrl = _db.storage.from('fotoprofile').getPublicUrl(filePath);

    // ✅ simpan URL saja ke kolom foto_profile
    return updateProfile(userId, {'foto_profile': publicUrl});
  }

  String _contentTypeFromExt(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }
}
