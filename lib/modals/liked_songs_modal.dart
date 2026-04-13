import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/liked_songs_service.dart';

class LikedSongsModal extends StatefulWidget {
  const LikedSongsModal({super.key});

  @override
  State<LikedSongsModal> createState() => _LikedSongsModalState();
}

class _LikedSongsModalState extends State<LikedSongsModal> {
  final LikedSongsService _likedSongsService = LikedSongsService();
  List<LikedSong> _likedSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikedSongs();
  }

  Future<void> _loadLikedSongs() async {
    final songs = await _likedSongsService.getLikedSongs();
    if (mounted) {
      setState(() {
        _likedSongs = songs;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeSong(LikedSong song) async {
    await _likedSongsService.removeLikedSong(song.title, song.artist);
    await _loadLikedSongs();
  }

  Future<void> _shareLikedSongs() async {
    if (_likedSongs.isEmpty) return;

    final StringBuffer buffer = StringBuffer();
    final String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    
    buffer.writeln('MY LIKED SONGS ON MARA FM');
    buffer.writeln('Exported on: $timestamp');
    buffer.writeln('--------------------------');
    buffer.writeln('');
    
    for (int i = 0; i < _likedSongs.length; i++) {
      final song = _likedSongs[i];
      buffer.writeln('${i + 1}. ${song.title} - ${song.artist}');
    }

    try {
      if (kIsWeb) {
        await Share.share(buffer.toString(), subject: 'My Liked Songs on Mara FM');
        return;
      }

      final directory = await getTemporaryDirectory();
      final String fileName = 'My Liked Songs on Mara FM.txt';
      final File file = File('${directory.path}/$fileName');
      
      await file.writeAsString(buffer.toString());
      
      await Share.shareXFiles(
        [XFile(file.path, name: fileName)],
        subject: 'My Liked Songs on Mara FM',
      );
    } catch (e) {
      // Fallback to simple share if file writing fails
      Share.share(buffer.toString(), subject: 'My Liked Songs on Mara FM');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDarkGrey,
        border: const Border(top: BorderSide(color: AppTheme.borderGrey, width: 8)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIKED SONGS',
                style: AppTheme.retroStyle(fontSize: 14, color: AppTheme.accentOrange),
              ),
              Row(
                children: [
                  if (_likedSongs.isNotEmpty)
                    IconButton(
                      icon: const Icon(LucideIcons.share, color: AppTheme.primaryTeal, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _shareLikedSongs();
                      },
                    ),
                  const SizedBox(width: 8),
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
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentOrange))
                : _likedSongs.isEmpty
                    ? Center(child: Text('NO LIKED SONGS', style: AppTheme.retroStyle(color: AppTheme.primaryTeal)))
                    : ListView.builder(
                        itemCount: _likedSongs.length,
                        itemBuilder: (context, index) {
                          final song = _likedSongs[index];
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
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.borderGrey,
                                    border: Border.all(color: AppTheme.shadowGrey, width: 2),
                                  ),
                                  child: const Icon(LucideIcons.music, color: AppTheme.primaryTeal, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.retroStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        song.artist.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.primaryTeal),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, color: AppTheme.accentOrange, size: 18),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _removeSong(song);
                                  },
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
  }
}
