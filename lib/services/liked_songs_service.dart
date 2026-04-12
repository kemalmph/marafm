import 'package:supabase_flutter/supabase_flutter.dart';

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
    title: json['title'] as String? ?? 'Unknown',
    artist: json['artist'] as String? ?? 'Unknown Artist',
    likedAt: DateTime.parse(json['liked_at'] ?? json['likedAt'] ?? DateTime.now().toIso8601String()),
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
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> addLikedSong(String title, String artist) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _supabase.from('liked_songs').upsert({
        'user_id': userId,
        'title': title,
        'artist': artist,
        'liked_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Return gracefully on error
    }
  }

  Future<void> removeLikedSong(String title, String artist) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _supabase.from('liked_songs').delete().match({
        'user_id': userId,
        'title': title,
        'artist': artist,
      });
    } catch (e) {
      // Return gracefully on error
    }
  }

  Future<List<LikedSong>> getLikedSongs() async {
    final userId = _userId;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('liked_songs')
          .select()
          .eq('user_id', userId)
          .order('liked_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => LikedSong.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> isLiked(String title, String artist) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('liked_songs')
          .select('id')
          .match({
            'user_id': userId,
            'title': title,
            'artist': artist,
          })
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}
