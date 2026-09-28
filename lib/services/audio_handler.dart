import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
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

  static const _loadTimeout = Duration(seconds: 20);

  // Bumped by pause/stop and each new load, so a load that finishes after the user
  // paused or switched channel does not start playing.
  int _loadGeneration = 0;

  MyAudioHandler() {
    _player.playbackEventStream.listen(
      (event) => playbackState.add(_transformEvent(event)),
      // A dropped stream leaves just_audio "playing" with nothing loaded, which shows
      // as playing but silent. Stop so the UI falls back to the Play state.
      onError: (Object e, StackTrace _) => _fail(e),
    );
    _listenForInterruptions();
  }

  Future<void> _fail(Object e) async {
    _loadGeneration++;
    _shouldResumeAfterInterruption = false;
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.error,
      playing: false,
      errorMessage: e.toString(),
    ));
  }

  // Reactivate/resume playback when an iOS/Android audio interruption ends
  // (phone call, Siri, another app's audio, or the OS suspending the
  // session after the app has been backgrounded for a while). Without this,
  // the AVAudioSession can stay inactive even though just_audio reports
  // "playing", so pressing Play again silently produces no sound until the
  // app is force-closed and reopened.
  void _listenForInterruptions() async {
    final session = await AudioSession.instance;
    session.interruptionEventStream.listen((event) async {
      if (event.begin) {
        if (event.type == AudioInterruptionType.pause ||
            event.type == AudioInterruptionType.unknown) {
          await _player.pause();
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            // Interruption ended and we were playing before it started:
            // reactivate the session and resume.
            if (playbackState.value.playing == false && _shouldResumeAfterInterruption) {
              await session.setActive(true);
              await _player.play();
            }
            break;
          case AudioInterruptionType.duck:
            break;
        }
      }
    });
  }

  bool _shouldResumeAfterInterruption = false;

  // Every play path (app button, lock screen, headphones) must re-arm auto-resume and
  // reactivate the session, since iOS may have deactivated it while idle or interrupted.
  @override
  Future<void> play() async {
    _shouldResumeAfterInterruption = true;
    final session = await AudioSession.instance;
    await session.setActive(true);
    await _player.play();
  }

  @override
  Future<void> pause() {
    _loadGeneration++;
    _shouldResumeAfterInterruption = false;
    return _player.pause();
  }

  @override
  Future<void> stop() {
    _loadGeneration++;
    _shouldResumeAfterInterruption = false;
    return _player.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  /// Loads [uri] and starts playback. Returns once the stream is loaded and playback
  /// has started, or false if a pause, stop or newer load superseded this one.
  @override
  Future<bool> playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
    final generation = ++_loadGeneration;
    final headers = extras?['headers'] as Map<String, String>? ?? {};
    try {
      await _player
          .setAudioSource(AudioSource.uri(uri, headers: headers))
          .timeout(_loadTimeout);
    } on PlayerInterruptedException {
      return false;
    } catch (e) {
      if (generation == _loadGeneration) await _fail(e);
      rethrow;
    }
    if (generation != _loadGeneration) return false;
    // just_audio's play() future only completes when playback later pauses or stops.
    unawaited(play());
    return true;
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
