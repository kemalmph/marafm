import '../models/radio_channel.dart';
import '../models/program.dart';
import 'supabase_service.dart';

class AppConfig {
  final List<RadioChannel> channels;
  final List<Program> programs;
  final Map<String, String> appInfo;
  final Map<String, String> stationInfo;
  final Map<String, String> contactInfo;
  final String youtubeApiKey;
  final String youtubePlaylistId;
  final String shareMessageTemplate;

  AppConfig({
    required this.channels,
    required this.programs,
    required this.appInfo,
    required this.stationInfo,
    this.contactInfo = const {},
    this.youtubeApiKey = '',
    this.youtubePlaylistId = '',
    this.shareMessageTemplate = 'I love this song! Now playing on Mara FM{channel}: {title} - {artist} [https://marafm.com]',
  });
}


class ConfigService {
  static final AppConfig defaultConfig = AppConfig(
    channels: [
      const RadioChannel(
        name: 'MARA FM',
        streamUrl: 'https://s1.gntr.net/listen/marafm/marafm',
        metadataUrl: 'https://s1.gntr.net/api/nowplaying/marafm',
        genre: 'Pop, Rock, Soul',
        description: 'Bandung\'s go-to station for the best in Contemporary Hit Radio, both International and Indonesian songs. Mara FM spins a carefully curated mix of today\'s hottest tracks alongside timeless hits spanning from the 80s to now.',
        website: 'marafm.com',
        channelType: 'internal',
      ),
      const RadioChannel(
        name: 'Lofi Radio',
        streamUrl: 'https://play.streamafrica.net/lofiradio',
        metadataUrl: 'https://api.streamafrica.net/metadata/70a198a4-c4eb-4f17-82c9-db07cd0361af',
        genre: 'Lo-Fi / Chill',
        description: 'Listen to Lofi Radio, streaming Chill music 24/7. High-quality radio streaming from Box Radio.',
        website: 'boxradio.net',
      ),
      const RadioChannel(
        name: 'Nightwave Plaza',
        streamUrl: 'https://radio.plaza.one/mp3',
        metadataUrl: 'https://api.plaza.one/status',
        genre: 'Vaporwave, Future Funk, Synthwave',
        description: 'An advertisement-free 24/7 radio station dedicated to Vaporwave, bringing aesthetics and dream-like music to your device wherever you have internet connectivity.',
        website: 'plaza.one',
      ),
      const RadioChannel(
        name: 'Spirit Radio',
        streamUrl: 'https://play.streamafrica.net/spiritrnb',
        metadataUrl: 'https://api.streamafrica.net/metadata/d9f04811-577e-4c80-8004-f73bc8ff5659',
        genre: 'R&B',
        description: 'Spirit Radio is a 24/7 internet radio station operated by the Box Radio network, featuring curated R&B music without commercial interruptions or DJ talk.',
        website: 'boxradio.net',
      ),
      const RadioChannel(
        name: 'Folk Forward',
        streamUrl: 'https://ice1.somafm.com/folkfwd-128-mp3',
        metadataUrl: 'https://somafm.com/songs/folkfwd.json',
        genre: 'Indie Folk, Alternative Folk, and Classic Folk',
        description: 'Contemporary indie folk music. Sometimes softer, sometimes a little harder, but always authentic.',
        website: 'somafm.com',
      ),
      const RadioChannel(
        name: 'Indie Pop Rocks!',
        streamUrl: 'https://ice2.somafm.com/indiepop-128-mp3',
        metadataUrl: 'https://somafm.com/songs/indiepop.json',
        genre: 'Indie Pop, Alternative, Electro-pop, Folk',
        description: 'Features the latest unsigned bands to the hottest new independent pop and rock artists from around the globe.',
        website: 'somafm.com',
      ),
    ],
    programs: [
      const Program(
        startTime: '06.00', endTime: '09.00',
        days: [Day.monday, Day.tuesday, Day.wednesday, Day.thursday, Day.friday],
        show: 'GASS! PAGI', host: 'LIVE ON AIR', genre: 'POP, POP ROCK, RNB, DANCE, RAP',
      ),
      const Program(
        startTime: '09.00', endTime: '11.00',
        days: [Day.monday, Day.tuesday, Day.wednesday, Day.thursday, Day.friday],
        show: 'MARA MUSIC ADDICT INDONESIA', host: 'LIVE ON AIR', genre: 'POP, POP ROCK, RNB',
      ),
      const Program(
        startTime: '11.00', endTime: '15.00',
        days: [Day.monday, Day.tuesday, Day.wednesday, Day.thursday, Day.friday],
        show: 'MARA MUSIC ADDICT', host: 'LIVE ON AIR', genre: 'POP, POP ROCK, RNB',
      ),
      const Program(
        startTime: '15.00', endTime: '18.00',
        days: [Day.monday, Day.tuesday, Day.wednesday, Day.thursday, Day.friday],
        show: 'SHIFT SORE', host: 'LIVE ON AIR', genre: 'POP, POP ROCK, RNB, DANCE',
      ),
      const Program(
        startTime: '18.00', endTime: '22.00',
        days: [Day.monday, Day.tuesday, Day.wednesday, Day.thursday, Day.friday],
        show: 'MARA MUSIC ADDICT', host: 'LIVE ON AIR', genre: 'POP, POP ROCK, RNB', priority: 0,
      ),
      const Program(
        startTime: '22.00', endTime: '24.00',
        days: [Day.monday, Day.tuesday, Day.wednesday, Day.thursday, Day.friday, Day.saturday],
        show: '100% LOVE SONGS', host: 'LIVE ON AIR', genre: 'POP, RNB, FOLK POP',
      ),
      const Program(
        startTime: '19.00', endTime: '22.00',
        days: [Day.friday],
        show: 'WE LOVE THE 90s', host: 'SPECIAL SHOW', genre: 'POP, POP ROCK, RNB, DANCE', priority: 1,
      ),
      const Program(
        startTime: '06.00', endTime: '09.00',
        days: [Day.saturday, Day.sunday],
        show: 'SATURDAY ROCKS', host: 'LIVE ON AIR', genre: 'ROCK, POP ROCK',
      ),
      const Program(
        startTime: '09.00', endTime: '19.00',
        days: [Day.saturday, Day.sunday],
        show: 'MARA MUSIC ADDICT', host: 'LIVE ON AIR', genre: 'POP, POP ROCK, RNB',
      ),
      const Program(
        startTime: '19.00', endTime: '22.00',
        days: [Day.saturday],
        show: 'WE LOVE THE 80s', host: 'SPECIAL SHOW', genre: 'CLASSIC DISCO, POP',
      ),
      const Program(
        startTime: '18.00', endTime: '24.00',
        days: [Day.sunday],
        show: 'SUNDAY SLOWER', host: 'LIVE ON AIR', genre: 'POP, POP ROCK & RNB',
      ),
    ],
    appInfo: {
      'VERSION': 'v1.0.8',
      'DEVELOPER': 'INITIA',
      'RELEASE': '2026',
    },
    stationInfo: {
      'NAME': 'MARA FM',
      'FREQ': '106.7 FM',
      'GENRE': 'HOT AC, POP, ROCK, SOUL',
    },
    contactInfo: {
      'WEBSITE':   'marafm.vercel.app',
      'EMAIL':     'maramedia.id@gmail.com',
      'INSTAGRAM': 'marfmbdg',
      'TIKTOK':    'marafmbdg',
      'FACEBOOK':  'Mara FM Bandung',
    },
    youtubeApiKey: 'AIzaSyAhnU8eT-ig6z5GDUsGAZLLRKG2AcDEawM',
    youtubePlaylistId: 'PL0D016RZTNd9Gbr8Ma96MdrqoD0KwVYLq',
    shareMessageTemplate: 'I love this song! Now playing on Mara FM{channel}: {title} - {artist} [https://marafm.com]',
  );

  Future<AppConfig> fetchConfig() async {
    try {
      final results = await Future.wait([
        SupabaseService.instance.getChannels(),
        SupabaseService.instance.getPrograms(),
        SupabaseService.instance.getSiteConfig(),
      ]);

      final channelRows = results[0] as List<Map<String, dynamic>>;
      final programRows = results[1] as List<Map<String, dynamic>>;
      final siteConfig  = results[2] as Map<String, String>;

      final channels = channelRows.isNotEmpty
          ? channelRows.map((r) => RadioChannel(
                name:        (r['name']         as String?) ?? '',
                streamUrl:   (r['stream_url']   as String?) ?? '',
                metadataUrl: (r['metadata_url'] as String?),
                genre:       (r['genre']        as String?) ?? '',
                description: (r['description']  as String?) ?? '',
                website:     (r['website']      as String?) ?? '',
                channelType: (r['channel_type'] as String?) ?? 'external',
              )).toList()
          : defaultConfig.channels;

      final programs = programRows.isNotEmpty
          ? programRows.map((r) {
              final rawDays = (r['days'] as List<dynamic>?) ?? [];
              final days = rawDays
                  .map((d) => Day.values.firstWhere(
                        (v) => v.toString().split('.').last == d.toString(),
                        orElse: () => Day.monday,
                      ))
                  .toList();
              return Program(
                startTime: (r['start_time'] as String?) ?? '00.00',
                endTime:   (r['end_time']   as String?) ?? '00.00',
                days:      days,
                show:      (r['show']       as String?) ?? '',
                host:      (r['host']       as String?) ?? '',
                genre:     (r['genre']      as String?) ?? '',
                priority:  (r['priority']   as int?)    ?? 0,
              );
            }).toList()
          : defaultConfig.programs;

      final appInfo = {
        'VERSION':   siteConfig['app_version']  ?? defaultConfig.appInfo['VERSION']!,
        'DEVELOPER': siteConfig['developer']    ?? defaultConfig.appInfo['DEVELOPER']!,
        'RELEASE':   siteConfig['release_year'] ?? defaultConfig.appInfo['RELEASE']!,
      };

      final stationInfo = {
        'NAME':  siteConfig['station_name']  ?? defaultConfig.stationInfo['NAME']!,
        'FREQ':  siteConfig['station_freq']  ?? defaultConfig.stationInfo['FREQ']!,
        'GENRE': siteConfig['station_genre'] ?? defaultConfig.stationInfo['GENRE']!,
      };

      final contactInfo = {
        'WEBSITE':   siteConfig['contact_website']   ?? defaultConfig.contactInfo['WEBSITE']!,
        'EMAIL':     siteConfig['contact_email']     ?? defaultConfig.contactInfo['EMAIL']!,
        'INSTAGRAM': siteConfig['contact_instagram'] ?? defaultConfig.contactInfo['INSTAGRAM']!,
        'TIKTOK':    siteConfig['contact_tiktok']    ?? defaultConfig.contactInfo['TIKTOK']!,
        'FACEBOOK':  siteConfig['contact_facebook']  ?? defaultConfig.contactInfo['FACEBOOK']!,
      };

      return AppConfig(
        channels:    channels,
        programs:    programs,
        appInfo:     appInfo,
        stationInfo: stationInfo,
        contactInfo: contactInfo,
        youtubeApiKey: siteConfig['youtube_api_key'] ?? defaultConfig.youtubeApiKey,
        youtubePlaylistId: siteConfig['youtube_playlist_id'] ?? defaultConfig.youtubePlaylistId,
        shareMessageTemplate: siteConfig['share_message_template'] ?? defaultConfig.shareMessageTemplate,
      );
    } catch (_) {
      // Supabase tidak tersedia — pakai hardcoded default
      return defaultConfig;
    }
  }
}
