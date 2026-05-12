import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileService {
  final _client = Supabase.instance.client;
  static const _table = 'user_profiles';

  /// Fetch the current user's profile. Returns null if not yet created.
  Future<UserProfile?> fetchProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final rows = await _client
        .from(_table)
        .select()
        .eq('id', uid)
        .limit(1);

    if ((rows as List).isEmpty) return null;
    return UserProfile.fromMap(rows.first as Map<String, dynamic>);
  }

  /// Upsert (create or update) the current user's profile.
  Future<UserProfile> upsertProfile(UserProfile profile) async {
    final row = await _client
        .from(_table)
        .upsert(profile.toUpsertMap())
        .select()
        .single();
    return UserProfile.fromMap(row);
  }

  /// Create a profile from Google OAuth metadata on first login.
  Future<UserProfile> createFromGoogle() async {
    final user = _client.auth.currentUser!;
    final meta = user.userMetadata ?? {};
    final profile = UserProfile(
      id: user.id,
      nickname: meta['full_name'] as String? ??
          meta['name'] as String? ??
          user.email?.split('@').first,
      avatarUrl: meta['avatar_url'] as String? ??
          meta['picture'] as String?,
      updatedAt: DateTime.now(),
    );
    return upsertProfile(profile);
  }

  /// Update only nickname and/or avatar URL.
  /// [Fix #7] If both fields are null, skip the network call and return the
  /// current profile to avoid sending an empty UPDATE to Supabase.
  Future<UserProfile> updateProfile({
    required String id,
    String? nickname,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      if (nickname != null) 'nickname': nickname,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    if (updates.isEmpty) {
      final current = await fetchProfile();
      if (current != null) return current;
      throw StateError('updateProfile called with no fields and no existing profile');
    }
    final row = await _client
        .from(_table)
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return UserProfile.fromMap(row);
  }

  /// Delete the current user's profile row (account data removal).
  Future<void> deleteProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from(_table).delete().eq('id', uid);
  }
}
