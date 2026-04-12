import 'dart:async';
import 'package:flutter/foundation.dart'; // Added to support kIsWeb
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart' as audio;
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import '../services/metadata_service.dart';
import '../models/station_metadata.dart';
import '../models/radio_channel.dart';
import '../services/audio_handler.dart';
import '../services/listener_session_service.dart';

// Events
abstract class PlaybackEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PlayRequested extends PlaybackEvent {
  final bool isSwitch;
  PlayRequested({this.isSwitch = false});
  @override
  List<Object?> get props => [isSwitch];
}
class PauseRequested extends PlaybackEvent {}
class StopRequested extends PlaybackEvent {}
class ToggleVideoRequested extends PlaybackEvent {}
class RefreshMetadataRequested extends PlaybackEvent {}

class _IcyMetadataUpdated extends PlaybackEvent {
  final IcyMetadata? metadata;
  _IcyMetadataUpdated(this.metadata);

  @override
  List<Object?> get props => [metadata];
}

class ChannelSelected extends PlaybackEvent {
  final RadioChannel channel;
  ChannelSelected(this.channel);
  @override
  List<Object?> get props => [channel];
}

// State
class PlaybackState extends Equatable {
  final bool isPlaying;
  final bool isPaused;
  final bool isVideoOn;
  final StationMetadata? metadata;
  final bool isLoading;
  final RadioChannel currentChannel;
  final String activeStreamUrl;

  const PlaybackState({
    this.isPlaying = false,
    this.isPaused = false,
    this.isVideoOn = false,
    this.metadata,
    this.isLoading = false,
    this.currentChannel = RadioChannel.maraFM,
    this.activeStreamUrl = '', // Default to empty
  });

  PlaybackState copyWith({
    bool? isPlaying,
    bool? isPaused,
    bool? isVideoOn,
    StationMetadata? metadata,
    bool? isLoading,
    RadioChannel? currentChannel,
    String? activeStreamUrl,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      isVideoOn: isVideoOn ?? this.isVideoOn,
      metadata: metadata ?? this.metadata,
      isLoading: isLoading ?? this.isLoading,
      currentChannel: currentChannel ?? this.currentChannel,
      activeStreamUrl: activeStreamUrl ?? this.activeStreamUrl,
    );
  }

  @override
  List<Object?> get props => [isPlaying, isPaused, isVideoOn, metadata, isLoading, currentChannel, activeStreamUrl];
}

// BLoC
class PlaybackBloc extends Bloc<PlaybackEvent, PlaybackState> {
  final MyAudioHandler _audioHandler;
  final MetadataService _metadataService = MetadataService();
  Timer? _metadataTimer;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _icyMetadataSubscription;

  PlaybackBloc(this._audioHandler) : super(const PlaybackState()) {
    on<PlayRequested>(_onPlay);
    on<PauseRequested>(_onPause);
    on<StopRequested>(_onStop);
    on<ToggleVideoRequested>(_onToggleVideo);
    on<RefreshMetadataRequested>(_onRefreshMetadata);
    on<ChannelSelected>(_onChannelSelected);

    _playerStateSubscription = _audioHandler.playbackState.listen((state) {
      add(_StateUpdateRequested(state));
    });

    _icyMetadataSubscription = _audioHandler.icyMetadataStream.listen((metadata) {
      add(_IcyMetadataUpdated(metadata));
    });

    on<_IcyMetadataUpdated>((event, emit) {
      // Only process ICY metadata for channels that don't have a dedicated metadata API.
      if (state.currentChannel.metadataUrl != null) return;
      
      // Prevent stale ICY metadata from the previous stream leaking during transitions
      if (state.isLoading) return;
      
      // Strict verification: only accept ICY metadata if the AudioPlayer 
      // is genuinely actively streaming this exact channel.
      if (state.activeStreamUrl != state.currentChannel.streamUrl) return;

      final info = event.metadata?.info;
      if (info != null && info.title != null && info.title!.isNotEmpty) {
        final icyTitle = info.title!;
        String title;
        String artist;
        if (icyTitle.contains('-')) {
          final parts = icyTitle.split('-');
          artist = parts[0].trim();
          title = parts.sublist(1).join('-').trim();
        } else {
          title = icyTitle;
          artist = 'Live Stream';
        }
        
        final newMetadata = StationMetadata(
          title: title,
          artist: artist,
          artUrl: '',
          history: const [],
        );
        
        emit(state.copyWith(metadata: newMetadata));
        
        // Also update lock screen with ICY metadata
        _audioHandler.updateMetadata(audio.MediaItem(
          id: state.currentChannel.streamUrl,
          album: 'Radio',
          title: title,
          artist: artist,
          artUri: kIsWeb ? null : Uri.parse('https://marafm.com/logo.png'), 
        ));
      } else {
        // Fallback: clear the metadata
        final emptyMetadata = StationMetadata(
          title: '',
          artist: '',
          artUrl: '',
          history: const [],
        );
        
        emit(state.copyWith(metadata: emptyMetadata));
        
        _audioHandler.updateMetadata(audio.MediaItem(
          id: state.currentChannel.streamUrl,
          album: 'Radio',
          title: state.currentChannel.name,
          artist: 'Live Stream',
          artUri: kIsWeb ? null : Uri.parse('https://marafm.com/logo.png'), 
        ));
      }
    });

    on<_StateUpdateRequested>((event, emit) {
      final isBuffering = event.state.processingState == audio.AudioProcessingState.buffering || 
                          event.state.processingState == audio.AudioProcessingState.loading;
      final isError = event.state.processingState == audio.AudioProcessingState.error;
      final isPlaying = event.state.playing;
      
      emit(state.copyWith(
        isPlaying: isPlaying,
        isPaused: !isPlaying && 
                  event.state.processingState != audio.AudioProcessingState.idle && 
                  !isError,
        isLoading: isPlaying && isBuffering,
      ));
    });

    // Start metadata fetching immediately on initialization
    _startMetadataTimer();
  }

  void _startMetadataTimer() {
    _metadataTimer?.cancel();
    _metadataTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      add(RefreshMetadataRequested());
    });
    add(RefreshMetadataRequested());
  }

  void _stopMetadataTimer() {
    _metadataTimer?.cancel();
    _metadataTimer = null;
  }

  Future<void> _onPlay(PlayRequested event, Emitter<PlaybackState> emit) async {
    try {
      emit(state.copyWith(isLoading: true, isPaused: false));
      final streamUrl = state.currentChannel.streamUrl;
      await _audioHandler.playFromUri(Uri.parse(streamUrl));
      
      emit(state.copyWith(activeStreamUrl: streamUrl));
      
      // Start session tracking if not already switched
      if (!event.isSwitch) {
        ListenerSessionService.instance.startSession(state.currentChannel.name, 'radio');
      }
      
      add(RefreshMetadataRequested());
    } catch (e) {
      emit(state.copyWith(isLoading: false, isPlaying: false));
    }
  }

  Future<void> _onChannelSelected(ChannelSelected event, Emitter<PlaybackState> emit) async {
    if (state.currentChannel == event.channel) return;
    
    StationMetadata newMetadata = StationMetadata(
      title: '',
      artist: '',
      artUrl: '',
      history: const [],
    );

    emit(state.copyWith(
      currentChannel: event.channel,
      metadata: newMetadata, // Clear old metadata explicitly
    ));

    if (state.isPlaying) {
      ListenerSessionService.instance.switchChannel(event.channel.name, 'radio');
      add(PlayRequested(isSwitch: true)); // Restart playback with new URL
    } else {
      add(RefreshMetadataRequested());
    }
  }

  Future<void> _onPause(PauseRequested event, Emitter<PlaybackState> emit) async {
    await ListenerSessionService.instance.endSession();
    await _audioHandler.pause();
    emit(state.copyWith(isPlaying: false, isPaused: true));
  }

  Future<void> _onStop(StopRequested event, Emitter<PlaybackState> emit) async {
    await ListenerSessionService.instance.endSession();
    await _audioHandler.stop();
    emit(state.copyWith(isPlaying: false, isPaused: false));
  }

  void _onToggleVideo(ToggleVideoRequested event, Emitter<PlaybackState> emit) {
    emit(state.copyWith(isVideoOn: !state.isVideoOn));
  }

  Future<void> _onRefreshMetadata(RefreshMetadataRequested event, Emitter<PlaybackState> emit) async {
    final currentChannel = state.currentChannel;
    
    if (currentChannel.metadataUrl == null) {
      _audioHandler.updateMetadata(audio.MediaItem(
        id: currentChannel.streamUrl,
        album: 'Radio',
        title: currentChannel.name,
        artist: 'Live Stream',
        artUri: kIsWeb ? null : Uri.parse('https://marafm.com/logo.png'), 
      ));
      return;
    }

    try {
      final metadata = await _metadataService.fetchMetadata(currentChannel.metadataUrl!);
      
      // Prevent fetched metadata from bleeding onto a newly selected channel
      if (state.currentChannel != currentChannel) return;

      emit(state.copyWith(metadata: metadata));

      if (metadata != null) {
        _audioHandler.updateMetadata(audio.MediaItem(
          id: state.currentChannel.streamUrl,
          album: currentChannel.name,
          title: metadata.title,
          artist: metadata.artist,
          artUri: kIsWeb ? null : (metadata.artUrl.isNotEmpty ? Uri.parse(metadata.artUrl) : Uri.parse('https://marafm.com/logo.png')), 
        ));
      }
    } catch (e) {
      // Log or handle error
    }
  }

  @override
  Future<void> close() {
    _metadataTimer?.cancel();
    _playerStateSubscription?.cancel();
    _icyMetadataSubscription?.cancel();
    return super.close();
  }
}

class _StateUpdateRequested extends PlaybackEvent {
  final audio.PlaybackState state;
  _StateUpdateRequested(this.state);

  @override
  List<Object?> get props => [state];
}
