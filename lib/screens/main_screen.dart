import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/config_bloc.dart';
import '../bloc/playback_bloc.dart';
import '../tabs/player_tab.dart';
import '../tabs/on_air_tab.dart';
import '../tabs/podcast_tab.dart';
import '../tabs/news_tab.dart';
import '../modals/settings_modal.dart';
import '../widgets/native_airplay_button.dart';
import '../main.dart'; // For CrtOverlay
import '../widgets/tactile_container.dart';
import '../services/audio_handler.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<String> _tabs = ['Player', 'On Air', 'Podcast', 'News'];

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = (context.findAncestorWidgetOfExactType<MaraFMApp>()?.audioHandler as MyAudioHandler);
    return BlocProvider(
      create: (context) => PlaybackBloc(audioHandler),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Container(
              color: AppTheme.backgroundDarkGrey,
              child: CrtOverlay(
                child: Column(
                  children: [
                    // Status Bar Placeholder (Respects Safe Area)
                    Container(
                      height: MediaQuery.of(context).padding.top > 0 
                          ? MediaQuery.of(context).padding.top - 2
                          : 18, 
                      color: AppTheme.surfaceGrey,
                    ),
                    const Divider(height: 4, thickness: 4, color: AppTheme.highlightGrey),

                    // Header
                    _buildHeader(),

                    // Content
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: const [
                          PlayerTab(),
                          OnAirTab(),
                          PodcastTab(),
                          NewsTab(),
                        ],
                      ),
                    ),

                    // Footer / Controls
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Builder(builder: (context) {
      return Container(
        color: AppTheme.surfaceGrey,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildArcadeHeaderButton(LucideIcons.user, () {
              final authBloc = context.read<AuthBloc>();
              final configBloc = context.read<ConfigBloc>();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (modalContext) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: authBloc),
                    BlocProvider.value(value: configBloc),
                  ],
                  child: const SettingsModal(),
                ),
              );
            }),
            Column(
              children: [
                Text(
                  'MARA',
                  style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.primaryTeal),
                ),
                const SizedBox(height: 1),
                Text(
                  'FM',
                  style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange),
                ),
              ],
            ),
            const NativeAudioSelector(),
          ],
        ),
      );
    });
  }

  Widget _buildArcadeHeaderButton(IconData icon, VoidCallback onTap) {
    return TactileContainer(
      onTap: onTap,
      builder: (context, isPressed) => Container(
        width: 40,
        height: 40,
        decoration: AppTheme.arcadeButtonDecoration(isPressed: isPressed),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildFooter() {
    return BlocBuilder<PlaybackBloc, PlaybackState>(
      builder: (context, state) {
        return Container(
          color: AppTheme.cardGrey,
          child: Column(
            children: [
              // Playback Controls Row
              Container(
                height: 65, 
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderGrey, width: 4)),
                ),
                child: Row(
                  children: [
                    _buildPlaybackButton(
                      context: context,
                      icon: LucideIcons.play,
                      isActive: state.isPlaying || (state.isLoading && !state.isPaused),
                      activeColor: AppTheme.accentOrange,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.read<PlaybackBloc>().add(PlayRequested());
                      },
                    ),
                    _buildPlaybackButton(
                      context: context,
                      icon: LucideIcons.pause,
                      isActive: state.isPaused,
                      activeColor: AppTheme.accentOrange,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.read<PlaybackBloc>().add(PauseRequested());
                      },
                    ),
                    _buildPlaybackButton(
                      context: context,
                      icon: LucideIcons.square,
                      isActive: false,
                      activeColor: AppTheme.primaryTeal,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.read<PlaybackBloc>().add(StopRequested());
                      },
                    ),
                    _buildPlaybackButton(
                      context: context,
                      text: "LIVE/\nCOLOUR",
                      isActive: state.isVideoOn,
                      activeColor: AppTheme.primaryTeal,
                      highlightColor: AppTheme.tealHighlight,
                      shadowColor: AppTheme.tealShadow,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<PlaybackBloc>().add(ToggleVideoRequested());
                      },
                    ),
                  ],
                ),
              ),
              // Navigation Bar (Respects Bottom Safe Area)
              Container(
                padding: EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom > 0 
                      ? MediaQuery.of(context).padding.bottom + 8 
                      : 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderGrey, width: 4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_tabs.length, (index) {
                    final isSelected = _currentIndex == index;
                    return _buildNavButton(_tabs[index], isSelected, index);
                  }),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildPlaybackButton({
    required BuildContext context,
    IconData? icon,
    String? text,
    required bool isActive,
    required Color activeColor,
    Color? highlightColor,
    Color? shadowColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: TactileContainer(
        onTap: onTap,
        builder: (context, isPressed) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: AppTheme.controlButtonDecoration(
            color: isActive ? activeColor : AppTheme.borderGrey,
            isActive: isActive,
            isPressed: isPressed,
            highlightColor: isActive ? highlightColor : null,
            shadowColor: isActive ? shadowColor : null,
          ),
          child: Center(
            child: text != null
                ? Text(
                    text,
                    textAlign: TextAlign.center,
                    style: AppTheme.retroStyle(
                      fontSize: 8,
                      color: isActive ? Colors.black : AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Icon(
                    icon!,
                    color: isActive ? Colors.black : AppTheme.primaryTeal,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(String label, bool isSelected, int index) {
    return TactileContainer(
      onTap: () => _onTabTapped(index),
      builder: (context, isPressed) => Container(
        constraints: const BoxConstraints(minWidth: 60),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentOrange : AppTheme.borderGrey,
          border: Border.all(
            color: isSelected ? AppTheme.shadowOrange : AppTheme.cardGrey,
            width: 4,
          ),
          boxShadow: (isSelected || isPressed)
              ? []
              : [const BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTheme.retroStyle(
            fontSize: 8,
            color: isSelected ? Colors.black : AppTheme.primaryTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

