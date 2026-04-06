import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_item.dart';

class NewsService {
  final String _feedUrl = 'https://rss.app/feeds/ot1t6FUIsYc7bunh.xml';

  Future<List<NewsItem>> fetchNews() async {
    try {
      final response = await http.get(Uri.parse(_feedUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to load feed: ${response.statusCode}');
      }

      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item');

      return items.map((node) {
        final title = node.findElements('title').singleOrNull?.innerText ?? 'Untitled';
        final link = node.findElements('link').singleOrNull?.innerText ?? '';
        final description = node.findElements('description').singleOrNull?.innerText ?? '';
        final pubDateStr = node.findElements('pubDate').singleOrNull?.innerText ?? '';
        
        // Handle image extraction - often in media:content or enclosure
        String imageUrl = '';
        final mediaContent = node.findElements('media:content');
        if (mediaContent.isNotEmpty) {
          imageUrl = mediaContent.first.getAttribute('url') ?? '';
        }
        
        if (imageUrl.isEmpty) {
          final enclosure = node.findElements('enclosure');
          if (enclosure.isNotEmpty) {
            imageUrl = enclosure.first.getAttribute('url') ?? '';
          }
        }

        // Fallback for descriptions that might contain HTML/Images
        // Some RSS feeds put the image in the description HTML.
        if (imageUrl.isEmpty && description.contains('<img')) {
          final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
          final match = imgRegex.firstMatch(description);
          imageUrl = match?.group(1) ?? '';
        }

        return NewsItem(
          title: title,
          link: link,
          description: _stripHtml(description),
          imageUrl: imageUrl,
          pubDate: DateTime.tryParse(pubDateStr) ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }
}
