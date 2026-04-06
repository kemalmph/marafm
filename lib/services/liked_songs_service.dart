import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LikedSong {
  final String title;
  final String artist;
  final DateTime likedAt;

  LikedSong({
    required this.title,
    required this.artist,
    required this.likedAt,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'likedAt': likedAt.toIso8601String(),
  };

  factory LikedSong.fromJson(Map<String, dynamic> json) => LikedSong(
    title: json['title'],
    artist: json['artist'],
    likedAt: DateTime.parse(json['likedAt']),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LikedSong &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          artist == other.artist;

  @override
  int get hashCode => title.hashCode ^ artist.hashCode;
}

class LikedSongsService {
  static const String _key = 'liked_songs';

  Future<void> addLikedSong(String title, String artist) async {
    final prefs = await SharedPreferences.getInstance();
    final songs = await getLikedSongs();
    final newSong = LikedSong(
      title: title,
      artist: artist,
      likedAt: DateTime.now(),
    );

    if (!songs.contains(newSong)) {
      songs.add(newSong);
      await _saveSongs(prefs, songs);
    }
  }

  Future<void> removeLikedSong(String title, String artist) async {
    final prefs = await SharedPreferences.getInstance();
    final songs = await getLikedSongs();
    songs.removeWhere((s) => s.title == title && s.artist == artist);
    await _saveSongs(prefs, songs);
  }

  Future<List<LikedSong>> getLikedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? songsJson = prefs.getString(_key);
    if (songsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(songsJson);
    return decoded.map((item) => LikedSong.fromJson(item)).toList();
  }

  Future<bool> isLiked(String title, String artist) async {
    final songs = await getLikedSongs();
    return songs.any((s) => s.title == title && s.artist == artist);
  }

  Future<void> _saveSongs(SharedPreferences prefs, List<LikedSong> songs) async {
    final encoded = jsonEncode(songs.map((s) => s.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
