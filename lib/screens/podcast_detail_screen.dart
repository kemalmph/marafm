import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/youtube_video.dart';
import '../widgets/tactile_container.dart';

class PodcastDetailScreen extends StatefulWidget {
  final YouTubeVideo video;

  const PodcastDetailScreen({super.key, required this.video});

  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDarkGrey,
        elevation: 0,
        leading: TactileContainer(
          onTap: () => Navigator.pop(context),
          builder: (context, isPressed) => Container(
            margin: const EdgeInsets.all(8),
            decoration: AppTheme.arcadeButtonDecoration(isPressed: isPressed),
            child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 18),
          ),
        ),
        title: Text(
          'PODCAST PLAYER',
          style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.primaryTeal),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: AppTheme.borderGrey, height: 4),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video Player Container with CRT Frame
            Container(
              margin: const EdgeInsets.all(12),
              decoration: AppTheme.screenDecoration.copyWith(
                border: Border.all(color: AppTheme.borderGrey, width: 8),
              ),
              child: kIsWeb
                  ? _buildWebVideoPlaceholder()
                  : YoutubePlayer(
                      controller: _controller,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: AppTheme.accentOrange,
                      progressColors: const ProgressBarColors(
                        playedColor: AppTheme.accentOrange,
                        handleColor: AppTheme.highlightOrange,
                      ),
                    ),
            ),

            // Video Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title.toUpperCase(),
                    style: AppTheme.retroStyle(
                      fontSize: 13,
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.video.channelTitle.toUpperCase(),
                    style: AppTheme.retroStyle(
                      fontSize: 11,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardGrey,
                      border: Border.all(color: AppTheme.borderGrey, width: 2),
                    ),
                    child: Text(
                      widget.video.description,
                      style: AppTheme.bodyStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // External Link Button
                  TactileContainer(
                    onTap: () async {
                      final uri = Uri.parse(widget.video.videoUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    builder: (context, isPressed) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: AppTheme.controlButtonDecoration(
                        color: AppTheme.primaryTeal,
                        isPressed: isPressed,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.externalLink, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'OPEN IN YOUTUBE',
                            style: AppTheme.retroStyle(fontSize: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Web fallback: youtube_player_flutter doesn't support web.
  /// Shows the video thumbnail with a play button that opens YouTube externally.
  Widget _buildWebVideoPlaceholder() {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(widget.video.videoUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.video.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
            // Darkened overlay
            Container(color: Colors.black.withValues(alpha: 0.4)),
            // YouTube-style play button
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000),
                  border: Border.all(color: Colors.white24, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 8),
                  ],
                ),
                child: const Icon(LucideIcons.play, color: Colors.white, size: 32),
              ),
            ),
            // Label
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: Colors.black54,
                  child: Text(
                    'TAP TO OPEN IN YOUTUBE',
                    style: AppTheme.retroStyle(fontSize: 9, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
