import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../bloc/playback_bloc.dart';
import '../bloc/config_bloc.dart';
import '../models/program.dart';
import '../models/radio_channel.dart';

class OnAirTab extends StatefulWidget {
  const OnAirTab({super.key});

  @override
  State<OnAirTab> createState() => _OnAirTabState();
}

class _OnAirTabState extends State<OnAirTab> {
  late Timer _timer;
  DateTime _now = DateTime.now();

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
    return BlocBuilder<ConfigBloc, ConfigState>(
      builder: (context, configState) {
        final programs = configState.config.programs;
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
