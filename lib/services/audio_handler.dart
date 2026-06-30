import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer(
    audioLoadConfiguration: kIsWeb
        ? null
        : const AudioLoadConfiguration(
            darwinLoadControl: DarwinLoadControl(
              // Small buffer prevents AVPlayer from seeking to "live edge" after buffering
              preferredForwardBufferDuration: Duration(seconds: 3),
              automaticallyWaitsToMinimizeStalling: false,
            ),
          ),
  );

  Stream<IcyMetadata?> get icyMetadataStream => _player.icyMetadataStream;

  MyAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
    try {
      final headers = extras?['headers'] as Map<String, String>? ?? {};
      await _player.setAudioSource(AudioSource.uri(uri, headers: headers));
      return play();
    } catch (e) {
      // Broadcast error through playback state
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.pause,
        MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // Helper method to update metadata from the BLoC or Service
  void updateMetadata(MediaItem item) {
    mediaItem.add(item);
  }
}
