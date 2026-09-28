class StationMetadata {
  final String title;
  final String artist;
  final String artUrl;
  final List<HistoryItem> history;
  final bool isOnline;

  StationMetadata({
    required this.title,
    required this.artist,
    required this.artUrl,
    required this.history,
    this.isOnline = true,
  });

  factory StationMetadata.fromJson(Map<String, dynamic> json) {
    String title = 'Unknown Title';
    String artist = 'Unknown Artist';
    String artUrl = '';
    List<HistoryItem> history = [];
    bool isOnline = true;

    if (json.containsKey('now_playing')) {
      // Mara FM format. AzuraCast keeps reporting the last song after the
      // encoder disconnects, so is_online is the only reliable off-air signal.
      isOnline = json['is_online'] != false;
      final nowPlaying = json['now_playing'];
      final song = nowPlaying['song'];
      title = song['title'] ?? title;
      artist = song['artist'] ?? artist;
      artUrl = song['art'] ?? artUrl;
      
      final historyJson = json['song_history'] as List? ?? [];
      history = historyJson.map((item) => HistoryItem.fromJson(item)).toList();
    } else if (json.containsKey('song')) {
      final songData = json['song'];
      if (songData is Map) {
        // Nightwave Plaza status API format
        title = songData['title'] ?? title;
        artist = songData['artist'] ?? artist;
        artUrl = songData['artwork_src'] ?? songData['art'] ?? artUrl;
      } else if (songData is String) {
        // StreamAfrica (Lofi) format - song is the title string
        title = songData;
        artist = json['artist'] ?? artist;
        artUrl = json['artwork'] ?? artUrl;
      }
    } else if (json.containsKey('songs') && json['songs'] is List && (json['songs'] as List).isNotEmpty) {
      // SomaFM format
      final firstSong = (json['songs'] as List).first;
      title = firstSong['title'] ?? title;
      artist = firstSong['artist'] ?? artist;
      artUrl = firstSong['albumArt'] ?? artUrl;
    }

    return StationMetadata(
      title: title,
      artist: artist,
      artUrl: artUrl,
      history: history,
      isOnline: isOnline,
    );
  }
}

class HistoryItem {
  final String title;
  final String artist;
  final String artUrl;
  final int playedAt;

  HistoryItem({
    required this.title,
    required this.artist,
    required this.artUrl,
    required this.playedAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final song = json['song'];
    return HistoryItem(
      title: song['title'] ?? 'Unknown Title',
      artist: song['artist'] ?? 'Unknown Artist',
      artUrl: song['art'] ?? '',
      playedAt: json['played_at'] ?? 0,
    );
  }
}
