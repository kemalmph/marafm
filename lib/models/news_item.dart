import 'package:equatable/equatable.dart';

class NewsItem extends Equatable {
  final String igId;
  final String? caption;
  final String? mediaUrl;
  final String mediaType;
  final DateTime? timestamp;
  final String? permalink;

  const NewsItem({
    required this.igId,
    this.caption,
    this.mediaUrl,
    required this.mediaType,
    this.timestamp,
    this.permalink,
  });

  /// Convenience: the first line of caption as the "title"
  String get title {
    if (caption == null || caption!.isEmpty) return '';
    final firstLine = caption!.split('\n').first.trim();
    return firstLine.length > 80 ? '${firstLine.substring(0, 80)}…' : firstLine;
  }

  /// Everything after the first line as the body
  String get body {
    if (caption == null || caption!.isEmpty) return '';
    final lines = caption!.split('\n');
    if (lines.length <= 1) return '';
    return lines.skip(1).join('\n').trim();
  }

  /// Official link to the Instagram post
  String get instagramUrl => permalink ?? 'https://www.instagram.com/reels/$igId/';

  factory NewsItem.fromMap(Map<String, dynamic> map) {
    return NewsItem(
      igId: map['ig_id'] as String,
      caption: map['caption'] as String?,
      mediaUrl: map['media_url'] as String?,
      mediaType: (map['media_type'] as String?) ?? 'IMAGE',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString())
          : null,
      permalink: map['permalink'] as String?,
    );
  }

  @override
  List<Object?> get props => [igId, caption, mediaUrl, mediaType, timestamp, permalink];
}
