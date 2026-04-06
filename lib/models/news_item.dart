import 'package:equatable/equatable.dart';

class NewsItem extends Equatable {
  final String title;
  final String description;
  final String imageUrl;
  final String link;
  final DateTime pubDate;

  const NewsItem({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.link,
    required this.pubDate,
  });

  @override
  List<Object?> get props => [title, description, imageUrl, link, pubDate];
}
