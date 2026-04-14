class RadioChannel {
  final String name;
  final String streamUrl;
  final String? metadataUrl;
  final String genre;
  final String description;
  final String website;
  final String channelType;

  const RadioChannel({
    required this.name,
    required this.streamUrl,
    this.metadataUrl,
    this.genre = '',
    this.description = '',
    this.website = '',
    this.channelType = 'external',
  });

  factory RadioChannel.fromJson(Map<String, dynamic> json) {
    return RadioChannel(
      name: json['name'] as String,
      streamUrl: json['streamUrl'] as String,
      metadataUrl: json['metadataUrl'] as String?,
      genre: json['genre'] as String? ?? '',
      description: json['description'] as String? ?? '',
      website: json['website'] as String? ?? '',
      channelType: json['channelType'] ?? json['channel_type'] ?? 'external',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'streamUrl': streamUrl,
      'metadataUrl': metadataUrl,
      'genre': genre,
      'description': description,
      'website': website,
      'channelType': channelType,
    };
  }

  static const RadioChannel maraFM = RadioChannel(
    name: 'MARA FM',
    streamUrl: 'https://s1.gntr.net/listen/marafm/marafm',
    metadataUrl: 'https://s1.gntr.net/api/nowplaying/marafm',
    genre: 'Pop, Rock, Soul',
    description: 'Bandung\'s go-to station for the best in Contemporary Hit Radio, both International and Indonesian songs. Mara FM spins a carefully curated mix of today\'s hottest tracks alongside timeless hits spanning from the 80s to now.',
    website: 'marafm.com',
    channelType: 'internal',
  );
}
