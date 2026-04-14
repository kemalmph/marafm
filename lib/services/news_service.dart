import 'package:flutter/foundation.dart';
import '../models/news_item.dart';
import 'supabase_service.dart';

class NewsService {
  /// Fetches Instagram posts from the news_feed table, newest first.
  /// If [forceSync] is true, triggers the Edge Function to fetch latest posts from Instagram first.
  Future<List<NewsItem>> fetchNewsFromSupabase({bool forceSync = false}) async {
    if (forceSync) {
      try {
        await SupabaseService.instance.client.functions.invoke('sync-instagram');
      } catch (e) {
        debugPrint('Failed to sync Instagram: $e');
      }
    }
    final rows = await SupabaseService.instance.getNewsFeed();
    return rows.map(NewsItem.fromMap).toList();
  }
}
