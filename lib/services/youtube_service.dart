import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

class YouTubeService {
  final String apiKey;
  final String baseUrl = 'https://www.googleapis.com/youtube/v3';

  YouTubeService({required this.apiKey});

  Future<List<YouTubeVideo>> fetchPlaylistVideos(String playlistId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/playlistItems?part=snippet&maxResults=50&playlistId=$playlistId&key=$apiKey'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch playlist items: ${response.body}');
    }

    final data = json.decode(response.body);
    final items = data['items'] as List;

    final videos = items.map((item) {
      final snippet = item['snippet'];
      return YouTubeVideo(
        id: snippet['resourceId']['videoId'],
        title: snippet['title'],
        description: snippet['description'],
        thumbnailUrl: snippet['thumbnails']['high']?['url'] ?? snippet['thumbnails']['default']?['url'] ?? '',
        channelTitle: snippet['channelTitle'],
        publishedAt: DateTime.parse(snippet['publishedAt']),
      );
    }).toList();

    // Fetch durations for these videos
    if (videos.isNotEmpty) {
      final videoIds = videos.map((v) => v.id).join(',');
      final durationResponse = await http.get(
        Uri.parse('$baseUrl/videos?part=contentDetails&id=$videoIds&key=$apiKey'),
      );

      if (durationResponse.statusCode == 200) {
        final durationData = json.decode(durationResponse.body);
        final durationItems = durationData['items'] as List;
        
        final durationMap = {
          for (var item in durationItems)
            item['id']: _parseDuration(item['contentDetails']['duration'])
        };

        return videos.map((v) {
          return YouTubeVideo(
            id: v.id,
            title: v.title,
            description: v.description,
            thumbnailUrl: v.thumbnailUrl,
            channelTitle: v.channelTitle,
            publishedAt: v.publishedAt,
            duration: durationMap[v.id],
          );
        }).toList();
      }
    }

    return videos;
  }

  String _parseDuration(String isoDuration) {
    // Basic ISO 8601 duration parser for PT#M#S
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(isoDuration);
    if (match == null) return '00:00';

    final hours = match.group(1);
    final minutes = match.group(2) ?? '0';
    final seconds = match.group(3) ?? '0';

    if (hours != null) {
      return '${hours.padLeft(2, '0')}:${minutes.padLeft(2, '0')}:${seconds.padLeft(2, '0')}';
    } else {
      return '${minutes.padLeft(2, '0')}:${seconds.padLeft(2, '0')}';
    }
  }
}
