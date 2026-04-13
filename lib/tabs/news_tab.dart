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
  List<NewsItem>? _items;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _newsService.fetchNewsFromSupabase();
      if (mounted) {
        setState(() {
          _items = items;
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
    return RefreshIndicator(
      onRefresh: _fetchNews,
      color: AppTheme.primaryTeal,
      backgroundColor: AppTheme.cardGrey,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(),
          if (_isLoading)
            const SliverFillRemaining(child: _LoadingState())
          else if (_error != null)
            SliverFillRemaining(
              child: _ErrorState(error: _error!, onRetry: _fetchNews),
            )
          else if (_items == null || _items!.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _PostCard(
                    item: _items![index],
                    onTap: () => _launchUrl(_items![index].instagramUrl),
                  ),
                  childCount: _items!.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          children: [
            // Instagram gradient avatar-style icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF), Color(0xFF515BD4)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                border: Border.all(color: AppTheme.borderGrey, width: 2),
              ),
              child: const Icon(LucideIcons.instagram, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@MARAFMBDG',
                  style: AppTheme.retroStyle(fontSize: 10, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'LATEST FROM INSTAGRAM',
                  style: AppTheme.retroStyle(fontSize: 6, color: AppTheme.primaryTeal),
                ),
              ],
            ),
            const Spacer(),
            // Refresh button
            GestureDetector(
              onTap: _fetchNews,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.cardGrey,
                  border: Border.all(color: AppTheme.borderGrey, width: 2),
                  boxShadow: const [AppTheme.miniArcadeShadow],
                ),
                child: const Icon(LucideIcons.refreshCw, color: AppTheme.primaryTeal, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Post Card
// ---------------------------------------------------------------------------
class _PostCard extends StatelessWidget {
  final NewsItem item;
  final VoidCallback onTap;

  const _PostCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardGrey,
          border: Border.all(color: AppTheme.borderGrey, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Media image ──────────────────────────────────────────────
            if (item.mediaUrl != null && item.mediaUrl!.isNotEmpty)
              _MediaImage(mediaUrl: item.mediaUrl!, mediaType: item.mediaType),

            // ── Caption area ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media type badge
                  _MediaBadge(mediaType: item.mediaType),
                  const SizedBox(height: 6),

                  // Title (first line of caption)
                  if (item.title.isNotEmpty)
                    Text(
                      item.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.retroStyle(
                        fontSize: 9,
                        color: AppTheme.accentOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  // Body (rest of caption)
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Footer: date + IG icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (item.timestamp != null)
                        Text(
                          _formatDate(item.timestamp!),
                          style: AppTheme.retroStyle(fontSize: 7, color: AppTheme.primaryTeal),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDD2A7B), Color(0xFF8134AF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          border: Border.all(color: AppTheme.borderGrey, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.instagram, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              'VIEW POST',
                              style: AppTheme.retroStyle(fontSize: 6, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
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

  String _formatDate(DateTime dt) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// Media Image widget – handles wsrv.nl proxy on web + VIDEO thumbnail label
// ---------------------------------------------------------------------------
class _MediaImage extends StatelessWidget {
  final String mediaUrl;
  final String mediaType;

  const _MediaImage({required this.mediaUrl, required this.mediaType});

  @override
  Widget build(BuildContext context) {
    final proxyUrl = kIsWeb
        ? 'https://wsrv.nl/?url=${Uri.encodeComponent(mediaUrl)}'
        : mediaUrl;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            proxyUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.black,
              child: const Icon(LucideIcons.image, color: AppTheme.borderGrey, size: 32),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                        : null,
                    color: AppTheme.primaryTeal,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
          // VIDEO overlay icon
          if (mediaType == 'VIDEO')
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: const Icon(LucideIcons.play, color: Colors.white, size: 22),
              ),
            ),
          // CAROUSEL_ALBUM overlay icon
          if (mediaType == 'CAROUSEL_ALBUM')
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                color: Colors.black54,
                child: const Icon(LucideIcons.layers, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Media type badge
// ---------------------------------------------------------------------------
class _MediaBadge extends StatelessWidget {
  final String mediaType;

  const _MediaBadge({required this.mediaType});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (mediaType) {
      'VIDEO' => ('VIDEO', LucideIcons.video, AppTheme.accentOrange),
      'CAROUSEL_ALBUM' => ('ALBUM', LucideIcons.layers, AppTheme.primaryTeal),
      _ => ('PHOTO', LucideIcons.camera, AppTheme.tealHighlight),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.retroStyle(fontSize: 7, color: color)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / Loading / Error states
// ---------------------------------------------------------------------------
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppTheme.primaryTeal,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'LOADING FEED…',
            style: AppTheme.retroStyle(fontSize: 8, color: AppTheme.primaryTeal),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.instagram, color: AppTheme.borderGrey, size: 48),
          const SizedBox(height: 16),
          Text(
            'NO POSTS YET',
            style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.primaryTeal),
          ),
          const SizedBox(height: 8),
          Text(
            'PULL DOWN TO REFRESH',
            style: AppTheme.retroStyle(fontSize: 7, color: AppTheme.borderGrey),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, color: AppTheme.accentOrange, size: 44),
            const SizedBox(height: 16),
            Text(
              'FAILED TO LOAD',
              style: AppTheme.retroStyle(fontSize: 10, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle(fontSize: 11, color: Colors.white54),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  border: Border.all(color: AppTheme.shadowOrange, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
                  ],
                ),
                child: Text(
                  'RETRY',
                  style: AppTheme.retroStyle(fontSize: 9, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
