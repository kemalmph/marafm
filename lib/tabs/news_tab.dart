import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/news_service.dart';
import '../models/news_item.dart';

class NewsTab extends StatefulWidget {
  const NewsTab({super.key});

  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  final NewsService _newsService = NewsService();
  List<NewsItem>? _newsItems;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    try {
      final items = await _newsService.fetchNewsFromSupabase();
      if (mounted) {
        setState(() {
          _newsItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: AppTheme.accentOrange, size: 48),
              const SizedBox(height: 16),
              Text(
                'FAILED TO LOAD NEWS',
                style: AppTheme.retroStyle(fontSize: 12, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTheme.bodyStyle(fontSize: 11, color: AppTheme.primaryTeal),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchNews();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange),
                child: Text('RETRY', style: AppTheme.retroStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Text(
          '@MARAFM',
          style: AppTheme.retroStyle(fontSize: 12, color: Colors.white),
        ),
        const SizedBox(height: 16),
        if (_newsItems == null || _newsItems!.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                children: [
                  const Icon(LucideIcons.newspaper, color: AppTheme.primaryTeal, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'NO NEWS YET',
                    style: AppTheme.retroStyle(fontSize: 14, color: AppTheme.primaryTeal),
                  ),
                ],
              ),
            ),
          )
        else
          ..._newsItems!.map((item) => _buildPostCard(item)),

        const SizedBox(height: 80), // Padding for footer
      ],
    );
  }

  Widget _buildPostCard(NewsItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        border: Border.all(color: AppTheme.borderGrey, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _launchUrl(item.link),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Image
            if (item.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: Colors.black,
                  child: Image.network(
                    kIsWeb ? 'https://wsrv.nl/?url=${Uri.encodeComponent(item.imageUrl)}' : item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black,
                      child: const Icon(LucideIcons.image, color: AppTheme.borderGrey, size: 32),
                    ),
                  ),
                ),
              ),
            // Post Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title/Caption
                  Text(
                    item.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.retroStyle(fontSize: 11, color: AppTheme.accentOrange, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  // Description
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyStyle(fontSize: 11, color: Colors.white),
                    ),
                  const SizedBox(height: 8),
                  // Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(item.pubDate),
                        style: AppTheme.retroStyle(fontSize: 9, color: AppTheme.primaryTeal),
                      ),
                      const Icon(LucideIcons.instagram, color: AppTheme.primaryTeal, size: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
