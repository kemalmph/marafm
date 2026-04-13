import '../models/news_item.dart';
import 'supabase_service.dart';

class NewsService {
  /// Fetches Instagram posts from the news_feed table, newest first.
  Future<List<NewsItem>> fetchNewsFromSupabase() async {
    final rows = await SupabaseService.instance.getNewsFeed();
    return rows.map(NewsItem.fromMap).toList();
  }
}
