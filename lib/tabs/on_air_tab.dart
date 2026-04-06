import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../bloc/playback_bloc.dart';
import '../models/radio_channel.dart';

enum Day { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class Program {
  final String startTime; // HH:mm
  final String endTime;   // HH:mm
  final List<Day> days;
  final String show;
  final String host;
  final String genre;
  final int priority;

  const Program({
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.show,
    required this.host,
    required this.genre,
    this.priority = 0,
  });

  bool isActive(DateTime now) {
    final day = getDayFromDateTime(now);
    if (!days.contains(day)) return false;

    final currentTime = now.hour * 60 + now.minute;
    // Support both . and : separators
    final startH = int.parse(startTime.split(RegExp(r'[.:]'))[0]);
    final startM = int.parse(startTime.split(RegExp(r'[.:]'))[1]);
    final endH = int.parse(endTime.split(RegExp(r'[.:]'))[0]);
    final endM = int.parse(endTime.split(RegExp(r'[.:]'))[1]);

    final startMinutes = startH * 60 + startM;
    var endMinutes = endH * 60 + endM;
    
    // Handle midnight (24.00)
    if (endH == 0 && endMinutes == 0) endMinutes = 24 * 60;
    if (endH == 24) endMinutes = 24 * 60;

    return currentTime >= startMinutes && currentTime < endMinutes;
  }

  String get timeRangeText => '$startTime - $endTime WIB';

  int get startMinutes {
    final startH = int.parse(startTime.split(RegExp(r'[.:]'))[0]);
    final startM = int.parse(startTime.split(RegExp(r'[.:]'))[1]);
    return startH * 60 + startM;
  }
}

Day getDayFromDateTime(DateTime dt) {
  switch (dt.weekday) {
    case DateTime.monday: return Day.monday;
    case DateTime.tuesday: return Day.tuesday;
    case DateTime.wednesday: return Day.wednesday;
    case DateTime.thursday: return Day.thursday;
    case DateTime.friday: return Day.friday;
    case DateTime.saturday: return Day.saturday;
    case DateTime.sunday: return Day.sunday;
    default: return Day.monday;
  }
}

class OnAirTab extends StatefulWidget {
  const OnAirTab({super.key});

  @override
  State<OnAirTab> createState() => _OnAirTabState();
}

class _OnAirTabState extends State<OnAirTab> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  static const List<Program> programs = [
    // Senin - Jumat
    Program(
      startTime: '06.00',
      endTime: '09.00',
      days: [Day.monday, Day.tuesday, Day.wednesday, Day.thursday, Day.friday],
      show: 'GASS! PAGI',
      host: 'LIVE ON AIR',
      genre: 'POP, POP ROCK, RNB, DANCE, RAP',
    ),
    Program(
      startTime: '09.00',
      endTime: '11.00',
      days: [Day.monday, Day.tuesday, Day.wednesday, Day.thursday, Day.friday],
      show: 'MARA MUSIC ADDICT INDONESIA',
      host: 'LIVE ON AIR',
      genre: 'POP, POP ROCK, RNB',
    ),
    Program(
      startTime: '11.00',
      endTime: '15.00',
      days: [Day.monday, Day.tuesday, Day.wednesday, Day.thursday, Day.friday],
      show: 'MARA MUSIC ADDICT',
      host: 'LIVE ON AIR',
      genre: 'POP, POP ROCK, RNB',
    ),
    Program(
      startTime: '15.00',
      endTime: '18.00',
      days: [Day.monday, Day.tuesday, Day.wednesday, Day.thursday, Day.friday],
      show: 'SHIFT SORE',
      host: 'LIVE ON AIR',
      genre: 'POP, POP ROCK, RNB, DANCE',
    ),
    Program(
      startTime: '18.00',
      endTime: '22.00',
      days: [Day.monday, Day.tuesday, Day.wednesday, Day.thursday, Day.friday],
      show: 'MARA MUSIC ADDICT',
      host: 'LIVE ON AIR',
      genre: 'POP, POP ROCK, RNB',
      priority: 0, // Lower priority than special shows
    ),
    // Senin - Sabtu
    Program(
      startTime: '22.00',
      endTime: '24.00',
      days: [Day.monday, Day.tuesday, Day.wednesday, Day.thursday, Day.friday, Day.saturday],
      show: '100% LOVE SONGS',
      host: 'LIVE ON AIR',
      genre: 'POP, RNB, FOLK POP',
    ),
    // Jumat Special
    Program(
      startTime: '19.00',
      endTime: '22.00',
      days: [Day.friday],
      show: 'WE LOVE THE 90s',
      host: 'SPECIAL SHOW',
      genre: 'POP, POP ROCK, RNB, DANCE',
      priority: 1, // Higher priority than generic addict show
    ),
    // Sabtu
    Program(
      startTime: '06.00',
      endTime: '09.00',
      days: [Day.saturday, Day.sunday],
      show: 'SATURDAY ROCKS',
      host: 'LIVE ON AIR',
      genre: 'ROCK, POP ROCK',
    ),
    Program(
      startTime: '09.00',
      endTime: '19.00',
      days: [Day.saturday, Day.sunday],
      show: 'MARA MUSIC ADDICT',
      host: 'LIVE ON AIR',
      genre: 'POP, POP ROCK, RNB',
    ),
    Program(
      startTime: '19.00',
      endTime: '22.00',
      days: [Day.saturday],
      show: 'WE LOVE THE 80s',
      host: 'SPECIAL SHOW',
      genre: 'CLASSIC DISCO, POP',
    ),
    // Minggu
    Program(
      startTime: '18.00',
      endTime: '24.00',
      days: [Day.sunday],
      show: 'SUNDAY SLOWER',
      host: 'LIVE ON AIR',
      genre: 'POP, POP ROCK & RNB',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine active program(s) and filter by highest priority if overlapping
    final activePrograms = programs.where((p) => p.isActive(_now)).toList();
    Program? currentProgram;
    if (activePrograms.isNotEmpty) {
      activePrograms.sort((a, b) => b.priority.compareTo(a.priority));
      currentProgram = activePrograms.first;
    }

    final currentDay = getDayFromDateTime(_now);
    final filteredPrograms = programs
        .where((p) => p.days.contains(currentDay))
        .toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    return BlocBuilder<PlaybackBloc, PlaybackState>(
      builder: (context, state) {
        final currentChannel = state.currentChannel;
        final isMara = currentChannel.name == 'MARA FM';

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Text(
              currentChannel.name.toUpperCase(),
              style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.accentOrange),
            ),
            const SizedBox(height: 12),

            // Channel Info
            _buildChannelInfo(currentChannel),

            if (isMara) ...[
              const SizedBox(height: 16),
              Text(
                'TODAYS PROGRAMS',
                style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.primaryTeal),
              ),
              const SizedBox(height: 12),
              ...filteredPrograms.map((p) => _buildProgramCard(p, p == currentProgram)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildChannelInfo(RadioChannel channel) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        border: Border.all(color: AppTheme.borderGrey, width: 4),
        boxShadow: const [AppTheme.arcadeShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('STATION', channel.name),
          if (channel.name == 'MARA FM') ...[
            const SizedBox(height: 8),
            _buildInfoRow('FREQ', '106.7 FM'),
          ],
          const SizedBox(height: 8),
          _buildInfoRow('GENRE', channel.genre),
          const SizedBox(height: 8),
          if (channel.website.isNotEmpty) ...[
            _buildInfoRow('WEBSITE', channel.website),
            const SizedBox(height: 8),
          ],
          _buildInfoRow('ABOUT', channel.description),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyStyle(fontSize: 11, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildProgramCard(Program program, bool isLive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLive ? AppTheme.accentOrange : AppTheme.cardGrey,
        border: Border.all(
          color: isLive ? AppTheme.shadowOrange : AppTheme.borderGrey,
          width: 4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isLive ? Colors.black : AppTheme.borderGrey,
                border: Border.all(
                  color: isLive ? AppTheme.highlightOrange : AppTheme.cardGrey,
                  width: 2,
                ),
              ),
              child: Icon(
                LucideIcons.clock,
                color: isLive ? AppTheme.accentOrange : AppTheme.primaryTeal,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        program.timeRangeText,
                        style: AppTheme.retroStyle(
                          fontSize: 10,
                          color: isLive ? Colors.black : AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isLive) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: AppTheme.shadowOrange, width: 2),
                          ),
                          child: Text(
                            'LIVE',
                            style: AppTheme.retroStyle(fontSize: 9, color: AppTheme.accentOrange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    program.show,
                    style: AppTheme.retroStyle(
                      fontSize: 11,
                      color: isLive ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    program.host,
                    style: AppTheme.retroStyle(
                      fontSize: 10,
                      color: isLive ? Colors.black : AppTheme.primaryTeal,
                    ),
                  ),
                  Text(
                    program.genre,
                    style: AppTheme.retroStyle(
                      fontSize: 9,
                      color: isLive ? Colors.black : AppTheme.accentOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
