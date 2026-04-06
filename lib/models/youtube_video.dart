import 'package:equatable/equatable.dart';

class YouTubeVideo extends Equatable {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String? duration;
  final String channelTitle;
  final DateTime publishedAt;

  const YouTubeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.duration,
    required this.channelTitle,
    required this.publishedAt,
  });

  String get videoUrl => 'https://www.youtube.com/watch?v=$id';

  @override
  List<Object?> get props => [id, title, description, thumbnailUrl, duration, channelTitle, publishedAt];
}
