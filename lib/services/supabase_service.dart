import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  /// Fetch published posts ordered by newest first.
  Future<List<Map<String, dynamic>>> getPosts() async {
    final response = await client
        .from('posts')
        .select()
        .eq('status', 'published')
        .order('published_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch Instagram posts from news_feed ordered by newest first.
  Future<List<Map<String, dynamic>>> getNewsFeed({int limit = 30}) async {
    final response = await client
        .from('news_feed')
        .select()
        .order('timestamp', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch active channels ordered by sort_order ascending.
  Future<List<Map<String, dynamic>>> getChannels() async {
    final response = await client
        .from('channels')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch all non-secret site_config entries as a Map<String, String>.
  Future<Map<String, String>> getSiteConfig() async {
    final response = await client
        .from('site_config')
        .select('key, value')
        .eq('is_secret', false);
    final rows = List<Map<String, dynamic>>.from(response);
    return {
      for (final row in rows)
        (row['key'] as String): (row['value'] ?? '').toString(),
    };
  }

  /// Fetch active programs ordered by sort_order.
  Future<List<Map<String, dynamic>>> getPrograms() async {
    final response = await client
        .from('programs')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch recent now_playing_log entries, optionally filtered by channel.
  Future<List<Map<String, dynamic>>> getNowPlayingLog({
    String? channelId,
    int limit = 20,
  }) async {
    var query = client.from('now_playing_log').select();

    if (channelId != null) {
      query = query.eq('channel_id', channelId);
    }

    final response = await query
        .order('played_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }
}
