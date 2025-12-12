import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const supabaseUrl = 'https://vkyflwqushrernyjyseb.supabase.co';
  static const anonKey = 'sb_publishable_0acJLClRKB9ZvUVfH8vEzw_41EnvnC7';

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
    );
  }
}

final supabase = Supabase.instance.client;
