import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marquee/marquee.dart';
import '../theme/app_theme.dart';
import '../bloc/playback_bloc.dart';
import '../models/station_metadata.dart';
import '../modals/share_modal.dart';
import '../widgets/tactile_container.dart';
import '../services/liked_songs_service.dart';
import '../bloc/config_bloc.dart';
import '../bloc/auth_bloc.dart';

class PlayerTab extends StatefulWidget {
  const PlayerTab({super.key});

  @override
  State<PlayerTab> createState() => _PlayerTabState();
}

class _PlayerTabState extends State<PlayerTab> {
  final LikedSongsService _likedSongsService = LikedSongsService();
  bool _isLiked = false;
  String? _lastSongKey;

  void _checkLikedStatus(StationMetadata? metadata) async {
    if (metadata == null) return;
    final currentKey = '${metadata.title}-${metadata.artist}';
    if (_lastSongKey != currentKey) {
      _lastSongKey = currentKey;
      final isLiked = await _likedSongsService.isLiked(metadata.title, metadata.artist);
      if (mounted) {
        setState(() => _isLiked = isLiked);
      }
    }
  }

  void _toggleLike(StationMetadata? metadata) async {
    if (metadata == null) return;
    if (context.read<AuthBloc>().state is! AuthAuthenticated) {
      _showSnackBar('LOGIN TO LIKE A SONG');
      return;
    }
    if (_isLiked) {
      await _likedSongsService.removeLikedSong(metadata.title, metadata.artist);
    } else {
      await _likedSongsService.addLikedSong(metadata.title, metadata.artist);
    }
    if (mounted) {
      setState(() => _isLiked = !_isLiked);
    }
  }

  void _showSnackBar(String message) {
    _showSnackBarWithContext(context, message);
  }

  void _showSnackBarWithContext(BuildContext ctx, String message) {
    final overlay = Overlay.of(ctx, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => GestureDetector(
        onTap: () => entry.remove(),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  border: Border.all(color: AppTheme.shadowOrange, width: 4),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                ),
                child: Text(message,
                    style: AppTheme.retroStyle(fontSize: 12, color: Colors.white),
                    textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaybackBloc, PlaybackState>(
      builder: (context, state) {
        final metadata = state.metadata;
        _checkLikedStatus(metadata);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 16),
          child: Column(
            children: [
              // CRT Screen (Album Art)
              _buildCrtScreen(metadata?.artUrl, state.isVideoOn, state.currentChannel.name),

              const SizedBox(height: 12),

              // Channel Selector
              _buildChannelSelector(state),

              const SizedBox(height: 8),

              // Now Playing Card
              _buildNowPlayingCard(state),

              const SizedBox(height: 12),

              // Action Grid
              _buildActionGrid(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCrtScreen(String? artUrl, bool isVideoOn, String channelName) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: AppTheme.screenDecoration.copyWith(
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (artUrl != null && artUrl.isNotEmpty)
              ColorFiltered(
                colorFilter: isVideoOn
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                    : const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0,      0,      0,      1, 0,
                      ]),
                child: Image.network(
                  kIsWeb ? 'https://wsrv.nl/?url=${Uri.encodeComponent(artUrl)}' : artUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
                ),
              )
            else
              ColorFiltered(
                colorFilter: isVideoOn
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                    : const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0,      0,      0,      1, 0,
                      ]),
                child: Image.asset(
                  channelName == 'MARA FM' ? 'assets/mara_default.gif' : 'assets/default_artwork.gif',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
                ),
              ),
            // Inner Scanlines for the screen
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: List.generate(
                    100,
                    (index) => index % 2 == 0 ? Colors.black.withValues(alpha: 0.15) : Colors.transparent,
                  ),
                  stops: List.generate(100, (index) => index / 100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSelector(PlaybackState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.borderGrey,
        border: Border.all(color: AppTheme.cardGrey, width: 4),
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
          HapticFeedback.mediumImpact();
          _showChannelSelectionModal(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CH: ${state.currentChannel.name.toUpperCase()}',
              style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
            ),
            const Icon(LucideIcons.chevronDown, color: AppTheme.accentOrange, size: 12),
          ],
        ),
      ),
    );
  }

  void _showChannelSelectionModal(BuildContext context) {
    // Capture the bloc before opening the modal
    final bloc = context.read<PlaybackBloc>();
    final outerContext = context; // capture for snackbar
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundDarkGrey,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) => BlocBuilder<ConfigBloc, ConfigState>(
        builder: (context, configState) {
          final channels = configState.config.channels;
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderGrey, width: 8)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.cardGrey,
                  child: Text(
                    'SELECT CHANNEL',
                    style: AppTheme.retroStyle(fontSize: 16, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: channels.map((channel) {
                        final isCurrent = bloc.state.currentChannel == channel;
                        final isLast = channels.last == channel;
                        final authState = outerContext.read<AuthBloc>().state;
                        final isLocked = channel.name != 'MARA FM' && authState is! AuthAuthenticated;

                        return Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                          child: TactileContainer(
                            onTap: () {
                              if (isLocked) {
                                Navigator.pop(context);
                                _showSnackBarWithContext(outerContext, 'LOG IN TO ACCESS OTHER CHANNELS');
                                return;
                              }
                              bloc.add(ChannelSelected(channel));
                              Navigator.pop(context);
                            },
                            builder: (context, isPressed) => Container(
                              padding: const EdgeInsets.all(12),
                              decoration: AppTheme.controlButtonDecoration(
                                color: isLocked
                                    ? Colors.black
                                    : isCurrent ? AppTheme.primaryTeal : AppTheme.cardGrey,
                                isPressed: isLocked ? false : isPressed,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isLocked
                                        ? LucideIcons.lock
                                        : isCurrent ? LucideIcons.radio : LucideIcons.circle,
                                    color: isLocked
                                        ? Colors.grey.shade700
                                        : isCurrent ? Colors.white : AppTheme.borderGrey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      channel.name.toUpperCase(),
                                      style: AppTheme.retroStyle(
                                        fontSize: 14,
                                        color: isLocked
                                            ? Colors.grey.shade600
                                            : isCurrent ? Colors.white : Colors.white70,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isCurrent && !isLocked)
                                    const Icon(LucideIcons.check, color: Colors.white, size: 16),
                                  if (isLocked)
                                    const Icon(LucideIcons.lock, color: AppTheme.borderGrey, size: 14),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollableText(String text, TextStyle style) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        if (textPainter.width > constraints.maxWidth) {
          return SizedBox(
            height: (style.fontSize ?? 14) * 1.5,
            child: Marquee(
              text: text,
              style: style,
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              blankSpace: 30.0,
              velocity: 30.0,
              pauseAfterRound: const Duration(seconds: 2),
              startPadding: 0.0,
              accelerationDuration: const Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          );
        } else {
          return Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          );
        }
      },
    );
  }

  Widget _buildNowPlayingCard(PlaybackState state) {
    final title = state.metadata?.title;
    final artist = state.metadata?.artist;
    final isLoading = state.isLoading;
    final isPlaying = state.isPlaying;
    final hasMetadata = state.currentChannel.metadataUrl != null || 
                        (title != null && title.isNotEmpty);

    String mainText;
    String subText;

    if (isPlaying) {
      if (hasMetadata && title != null && title.isNotEmpty) {
        mainText = title.toUpperCase();
        subText = (artist ?? '').toUpperCase();
      } else {
        mainText = 'PLAYING STREAM...';
        subText = state.currentChannel.name.toUpperCase();
      }
    } else if (state.isPaused) {
      if (hasMetadata && title != null && title.isNotEmpty) {
        mainText = title.toUpperCase();
        subText = (artist ?? '').toUpperCase();
      } else {
        mainText = 'PAUSED';
        subText = state.currentChannel.name.toUpperCase();
      }
    } else if (isLoading) {
      mainText = 'LOADING AUDIO...';
      subText = 'PLEASE WAIT';
    } else {
      if (hasMetadata && title != null && title.isNotEmpty) {
        mainText = title.toUpperCase();
        subText = (artist ?? '').toUpperCase();
      } else {
        mainText = 'PRESS PLAY BUTTON TO START';
        subText = state.currentChannel.name.toUpperCase();
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        border: Border.all(color: AppTheme.borderGrey, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScrollableText(
            mainText,
            AppTheme.retroStyle(fontSize: 13, color: AppTheme.accentOrange, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _buildScrollableText(
            subText,
            AppTheme.retroStyle(fontSize: 10, color: AppTheme.primaryTeal),
          ),
        ],
      ),
    );
  }

  void _showShareModal(StationMetadata? metadata, String channelName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareModal(
        songTitle: metadata?.title ?? 'Unknown Title',
        artist: metadata?.artist ?? 'Unknown Artist',
        channelName: channelName,
      ),
    );
  }

  Widget _buildActionGrid(PlaybackState state) {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.0, 
      children: [
        _buildActionButton(
          icon: LucideIcons.heart,
          isActive: _isLiked,
          color: AppTheme.accentOrange,
          onTap: () => _toggleLike(state.metadata),
        ),
        _buildActionButton(
          icon: LucideIcons.share2,
          color: AppTheme.primaryTeal,
          onTap: () => _showShareModal(state.metadata, state.currentChannel.name),
        ),
        _buildActionButton(
          icon: LucideIcons.history,
          color: AppTheme.accentOrange,
          onTap: () => _showHistoryBottomSheet(state.metadata?.history ?? []),
        ),
        _buildActionButton(
          icon: LucideIcons.messageSquare,
          color: AppTheme.accentOrange,
          onTap: () async {
            final authState = context.read<AuthBloc>().state;
            if (authState is! AuthAuthenticated) {
              _showSnackBar('LOGIN TO MESSAGE STUDIO AND REGISTER YOUR WHATSAPP NUMBER');
              return;
            }
            final whatsapp = authState.profile?['whatsapp_number'] as String? ?? '';
            if (whatsapp.isEmpty) {
              _showSnackBar('REGISTER YOUR WHATSAPP NUMBER TO MESSAGE STUDIO');
              return;
            }
            final Uri whatsappUri = Uri.parse('https://wa.me/6285111441067');
            if (await canLaunchUrl(whatsappUri)) {
              await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    );
  }

  void _showHistoryBottomSheet(List<HistoryItem> history) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundDarkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.borderGrey, width: 8)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SONG HISTORY',
                    style: AppTheme.retroStyle(fontSize: 14, color: AppTheme.accentOrange),
                  ),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange,
                        border: Border.all(color: AppTheme.shadowOrange, width: 2),
                      ),
                      child: const Icon(LucideIcons.x, color: Colors.black, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: history.isEmpty 
                  ? Center(child: Text('NO HISTORY', style: AppTheme.retroStyle(color: AppTheme.primaryTeal)))
                  : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardGrey,
                          border: Border.all(color: AppTheme.borderGrey, width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.borderGrey,
                                border: Border.all(color: AppTheme.shadowGrey, width: 2),
                              ),
                              child: item.artUrl.isNotEmpty 
                                ? Image.network(
                                    kIsWeb ? 'https://wsrv.nl/?url=${Uri.encodeComponent(item.artUrl)}' : item.artUrl, 
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.black,
                                      child: const Icon(LucideIcons.music, color: AppTheme.borderGrey, size: 16),
                                    ),
                                  )
                                : Container(color: Colors.black),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.retroStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    item.artist.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.primaryTeal),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    bool isActive = false,
    Color color = AppTheme.primaryTeal,
    required VoidCallback onTap,
  }) {
    return TactileContainer(
      onTap: onTap,
      builder: (context, isPressed) => Container(
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentOrange : AppTheme.borderGrey,
          border: isPressed 
            ? Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.3), width: 4),
                left: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 2),
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
                right: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
              )
            : Border.all(
                color: isActive ? AppTheme.shadowOrange : AppTheme.cardGrey,
                width: 4,
              ),
          boxShadow: (isActive || isPressed)
            ? []
            : const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : color,
          size: 14, 
        ),
      ),
    );
  }
}
