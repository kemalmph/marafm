import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';
import '../screens/podcast_detail_screen.dart';

class PodcastTab extends StatefulWidget {
  const PodcastTab({super.key});

  @override
  State<PodcastTab> createState() => _PodcastTabState();
}

class _PodcastTabState extends State<PodcastTab> {
  final YouTubeService _youtubeService = YouTubeService(
    apiKey: 'AIzaSyAhnU8eT-ig6z5GDUsGAZLLRKG2AcDEawM',
  );
  final String _playlistId = 'PL0D016RZTNd9Gbr8Ma96MdrqoD0KwVYLq';
  
  List<YouTubeVideo>? _videos;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPodcasts();
  }

  Future<void> _fetchPodcasts() async {
    try {
      final videos = await _youtubeService.fetchPlaylistVideos(_playlistId);
      if (mounted) {
        setState(() {
          _videos = videos;
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


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertTriangle, color: AppTheme.accentOrange, size: 48),
            const SizedBox(height: 16),
            Text(
              'ERROR LOADING PODCASTS',
              style: AppTheme.retroStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTheme.retroStyle(fontSize: 11, color: AppTheme.primaryTeal),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchPodcasts();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange),
              child: Text('RETRY', style: AppTheme.retroStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Text(
          'PODCASTS',
          style: AppTheme.retroStyle(fontSize: 12, color: Colors.white),
        ),
        const SizedBox(height: 16),
        ..._videos!.map((v) => _buildPodcastCard(v)),
      ],
    );
  }

  Widget _buildPodcastCard(YouTubeVideo video) {
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PodcastDetailScreen(video: video),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.black,
                        child: const Icon(LucideIcons.playCircle, color: AppTheme.borderGrey, size: 32),
                      ),
                    ),
                    // Duration Badge
                    if (video.duration != null)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: AppTheme.accentOrange, width: 2),
                          ),
                          child: Text(
                            video.duration!,
                            style: AppTheme.retroStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info Area
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.retroStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.channelTitle.toUpperCase(),
                              style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.primaryTeal),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              video.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.retroStyle(fontSize: 9, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Play Button Icon Style
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange,
                          border: Border.all(color: AppTheme.shadowOrange, width: 2),
                        ),
                        child: const Icon(LucideIcons.play, color: Colors.black, size: 12),
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
}
