import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../../../core/config/supabase_client.dart';
import '../../../core/network/net_guard.dart';

class ProfileService {
  final SupabaseClient _db;
  ProfileService(this._db);

  Future<ProfileModel> getMyProfile(String userId) async {
    return networkGuard(
      () async {
        final data = await _db
            .from('profiles')
            .select('id, role, is_active, foto_profile, nama_lengkap, email, no_hp')
            .eq('id', userId)
            .single();
        return ProfileModel.fromJson(data);
      },
      'Gagal mengambil profil',
    );
  }

  Future<ProfileModel> updateProfile(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    return networkGuard(
      () async {
        final data = await _db
            .from('profiles')
            .update(patch)
            .eq('id', userId)
            .select('id, role, is_active, foto_profile, nama_lengkap, email, no_hp')
            .single();
        return ProfileModel.fromJson(data);
      },
      'Gagal memperbarui profil',
    );
  }

  Future<ProfileModel> updateEmail(String id, String email) async {
    return networkGuard(
      () async {
        await supabase.functions
            .invoke('update-user', body: {'user_id': id, 'email': email});

        final res = await _db
            .from('profiles')
            .update({'email': email})
            .eq('id', id)
            .select()
            .single();

        return ProfileModel.fromJson(res);
      },
      'Gagal memperbarui email',
    );
  }

  Future<void> changeMyEmail(String email) async {
    return networkGuard(
      () async {
        await _db.auth.updateUser(UserAttributes(email: email));
      },
      'Gagal mengganti email',
    );
  }

  Future<ProfileModel> updateNoHP(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    return networkGuard(
      () async {
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
      },
      'Gagal memperbarui nomor HP',
    );
  }

  Future<ProfileModel> updatePassword(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    return networkGuard(
      () async {
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
      },
      'Gagal memperbarui password',
    );
  }

  Future<void> changePassword(String newPassword) async {
    return networkGuard(
      () async {
        await _db.auth.updateUser(UserAttributes(password: newPassword));
      },
      'Gagal mengubah password',
    );
  }

  Future<ProfileModel> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String originalFilename,
  }) async {
    return networkGuard(
      () async {
        final ext = p.extension(originalFilename).toLowerCase();
        final safeExt =
            (ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp')
                ? ext
                : '.jpg';

        final filePath = 'profile/$userId/avatar$safeExt';

        await _db.storage
            .from('fotoprofile')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: _contentTypeFromExt(safeExt),
              ),
            );

        final url = _db.storage.from('fotoprofile').getPublicUrl(filePath);

        return updateProfile(userId, {'foto_profile': url});
      },
      'Gagal mengunggah foto profil',
    );
  }

  String _contentTypeFromExt(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<ProfileModel> removeAvatar({required String userId}) async {
    return networkGuard(
      () async {
        final paths = [
          'profile/$userId/avatar.jpg',
          'profile/$userId/avatar.jpeg',
          'profile/$userId/avatar.png',
          'profile/$userId/avatar.webp',
        ];

        try {
          await _db.storage.from('fotoprofile').remove(paths);
        } catch (_) {}

        return updateProfile(userId, {'foto_profile': null});
      },
      'Gagal menghapus foto profil',
    );
  }
}
