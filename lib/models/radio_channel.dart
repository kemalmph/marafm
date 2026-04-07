class RadioChannel {
  final String name;
  final String streamUrl;
  final String? metadataUrl;
  final String genre;
  final String description;
  final String website;

  const RadioChannel({
    required this.name,
    required this.streamUrl,
    this.metadataUrl,
    this.genre = '',
    this.description = '',
    this.website = '',
  });

  static const RadioChannel maraFM = RadioChannel(
    name: 'MARA FM',
    streamUrl: 'https://s1.gntr.net/listen/marafm/marafm',
    metadataUrl: 'https://s1.gntr.net/api/nowplaying/marafm',
    genre: 'Pop, Rock, Soul',
    description: 'Bandung\'s go-to station for the best in Contemporary Hit Radio, both International and Indonesian songs. Mara FM spins a carefully curated mix of today\'s hottest tracks alongside timeless hits spanning from the 80s to now.',
    website: 'marafm.com',
  );

  static const List<RadioChannel> all = [
    maraFM,
    RadioChannel(
      name: 'Lofi Radio',
      streamUrl: 'https://play.streamafrica.net/lofiradio',
      metadataUrl: 'https://api.streamafrica.net/metadata/70a198a4-c4eb-4f17-82c9-db07cd0361af',
      genre: 'Lo-Fi / Chill',
      description: 'Listen to Lofi Radio, streaming Chill music 24/7. High-quality radio streaming from Box Radio.',
      website: 'boxradio.net',
    ),
    RadioChannel(
      name: 'Nightwave Plaza',
      streamUrl: 'https://radio.plaza.one/mp3',
      metadataUrl: 'https://api.plaza.one/status',
      genre: 'Vaporwave, Future Funk, Synthwave',
      description: 'An advertisement-free 24/7 radio station dedicated to Vaporwave, bringing aesthetics and dream-like music to your device wherever you have internet connectivity. Plaza Featuring a constantly updated database of Vaporwave artists across the globe, the station prides itself on having no after-track advertisements and full support for all artists and producers trying to find an audience.',
      website: 'plaza.one',
    ),/*
    RadioChannel(
      name: 'Bossa Beyond',
      streamUrl: 'https://ice5.somafm.com/bossa-256-mp3',
      metadataUrl: 'https://somafm.com/songs/bossa.json',
      genre: 'Bossa Nova, Samba, Brazilian Lounge',
      description: 'Bossa Nova is sensuously rhythmic and melodically smooth — a cool way to feel the heat of the moment. Perfect with a Mojito or Caipirinha, or just some iced coconut water. TuneIn Silky-smooth, laid-back Brazilian-style rhythms of Bossa Nova, Samba, and beyond. Repla\nAbout SomaFM: Over 30 unique channels of commercial-free, listener-supported radio, with all music hand-picked by SomaFM\'s award-winning DJs and music directors. SomaFM',
      website: 'somafm.com/bossa',
    ),
    RadioChannel(
      name: 'The In-Sound',
      streamUrl: 'https://ice5.somafm.com/insound-256-mp3',
      metadataUrl: 'https://somafm.com/songs/insound.json',
      genre: '60s/70s Avant-Garde, Psychedelic Pop',
      description: 'The sounds of continental avant-garde and psychedelic pop, made to dance to — all while wearing slim-fitted suits and trousers, turtlenecks, miniskirts, go-go boots, and loud colorful patterns. A countercultural experience. Only from SomaFM.',
      website: 'somafm.com/insound',
    ),*/
    RadioChannel(
      name: 'Spirit Radio',
      streamUrl: 'https://play.streamafrica.net/spiritrnb',
      metadataUrl: 'https://api.streamafrica.net/metadata/d9f04811-577e-4c80-8004-f73bc8ff5659',
      genre: 'R&B',
      description: 'Spirit Radio is a 24/7 internet radio station operated by the Box Radio network, featuring curated R&B music without commercial interruptions or DJ talk. The station provides a continuous, human-curated audio experience designed to create a sophisticated atmosphere for listeners worldwide.',
      website: 'boxradio.net',
    ),
    RadioChannel(
      name: 'Folk Forward',
      streamUrl: 'https://ice1.somafm.com/folkfwd-128-mp3',
      metadataUrl: 'https://somafm.com/songs/folkfwd.json',
      genre: 'Indie Folk, Alternative Folk, and Classic Folk',
      description: 'Contemporary indie folk music. Sometimes softer, sometimes a little harder, but always authentic. It features a modern take on folk music, with occasional appearances by the masters of the genre.',
      website: 'somafm.com',
    ),
    RadioChannel(
      name: 'Indie Pop Rocks!',
      streamUrl: 'https://ice2.somafm.com/indiepop-128-mp3',
      metadataUrl: 'https://somafm.com/songs/indiepop.json',
      genre: 'Indie Pop, Alternative, Electro-pop, Folk',
      description: 'Features the latest unsigned bands to the hottest new independent pop and rock artists from around the globe, with a liberal sprinkling of classic indie tunes, electro-pop, and folk.',
      website: 'somafm.com',
    ),
  ];
}
