import '../models/news_item.dart';
import 'supabase_service.dart';

class NewsService {
  /// Fetches news from Supabase posts table.
  /// Returns an empty list if no posts are found or on error.
  Future<List<NewsItem>> fetchNewsFromSupabase() async {
    try {
      final posts = await SupabaseService.instance.getPosts();
      if (posts.isEmpty) return [];

      return posts.map((post) {
        final publishedAt = post['published_at'] != null
            ? DateTime.tryParse(post['published_at'].toString()) ?? DateTime.now()
            : DateTime.now();

        return NewsItem(
          title: (post['title'] as String?) ?? 'Untitled',
          description: (post['excerpt'] as String?) ??
              _stripHtml((post['body'] as String?) ?? ''),
          imageUrl: (post['featured_image_url'] as String?) ?? '',
          link: '/news/${post['slug']}',
          pubDate: publishedAt,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }
}
