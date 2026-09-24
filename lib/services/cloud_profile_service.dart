import 'package:supabase_flutter/supabase_flutter.dart';

class CloudProfileService {
  CloudProfileService._();

  static final instance = CloudProfileService._();
  SupabaseClient get _client => Supabase.instance.client;

  Future<String?> loadUsername() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client
        .from('profiles')
        .select('username')
        .eq('id', user.id)
        .maybeSingle();
    return row?['username'] as String?;
  }

  Future<void> saveUsername(String username) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User is not signed in');
    await _client.from('profiles').upsert({
      'id': user.id,
      'username': username,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'id');
  }

  Future<void> syncUsernameFromMetadata() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final existing = await loadUsername();
    if (existing != null && existing.isNotEmpty) return;
    final metadataUsername = user.userMetadata?['username'] as String?;
    if (metadataUsername == null || metadataUsername.isEmpty) return;
    try {
      await saveUsername(metadataUsername);
    } on PostgrestException {
      // A legacy account may contain a username now claimed by another user.
      // The user can choose a new one from Profile settings.
    }
  }

  bool isDuplicateUsername(PostgrestException error) =>
      error.code == '23505' ||
      error.message.toLowerCase().contains('profiles_username_unique');
}
