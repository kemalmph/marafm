import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer(
    // By default headers are sent through a localhost proxy server inside the app. iOS
    // reclaims its listening socket while the app is backgrounded (phone call, long
    // lock), after which every load fails with -1004 until the app restarts. Send the
    // headers directly via AVURLAsset instead.
    useProxyForRequestHeaders: false,
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
  // While offline a load hangs rather than failing, so reconnect attempts use a shorter
  // timeout and capped backoff to keep retrying for ~2.5 minutes in total.
  static const _reconnectLoadTimeout = Duration(seconds: 10);
  static const _maxReconnectDelay = Duration(seconds: 5);
  static const _maxReconnectAttempts = 10;
  static const _stallCheckInterval = Duration(seconds: 2);
  static const _stallTimeout = Duration(seconds: 10);

  Duration _lastBuffered = Duration.zero;
  DateTime _lastProgressAt = DateTime.now();

  // Bumped by pause/stop and each new load, so a load that finishes after the user
  // paused or switched channel does not start playing.
  int _loadGeneration = 0;

  // Last stream the user asked for, so a dropped connection can be re-opened.
  Uri? _currentUri;
  Map<String, String> _currentHeaders = const {};
  int _reconnectAttempts = 0;
  int _activeLoads = 0;
  bool _reconnecting = false;

  MyAudioHandler() {
    _player.playbackEventStream.listen(
      (event) => playbackState.add(_transformEvent(event)),
      onError: (Object e, StackTrace _) {
        // iOS broadcasts "abort" whenever a new load replaces a pending one; that is not
        // a dropped stream. Treating it as one killed the new load on every Play press.
        if (e is PlatformException && e.code == 'abort') return;
        // A failing load reports through its own future; don't handle it twice.
        if (_activeLoads > 0) return;
        _reconnectOrFail(e);
      },
    );
    // A live stream never ends on its own; "completed" means the server closed it.
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && _wantsPlayback) {
        _reconnectOrFail('Stream ended');
      }
    });
    _listenForInterruptions();
    Timer.periodic(_stallCheckInterval, (_) => _checkForStall());
  }

  // With automaticallyWaitsToMinimizeStalling off, AVPlayer that loses its connection
  // keeps reporting "ready, playing" and never errors, and just_audio extrapolates
  // position from the clock, so it keeps advancing too. The buffered position comes
  // from AVPlayer's loaded ranges, so it stops growing when no data arrives.
  void _checkForStall() {
    final buffered = _player.bufferedPosition;
    final now = DateTime.now();
    final active = _wantsPlayback && _player.playing && _activeLoads == 0 && !_reconnecting;
    if (!active || buffered != _lastBuffered) {
      // Only new data proves the stream recovered; a "ready, playing" event does not,
      // since a dead stream reports exactly that.
      if (active) _reconnectAttempts = 0;
      _lastBuffered = buffered;
      _lastProgressAt = now;
      return;
    }
    if (now.difference(_lastProgressAt) >= _stallTimeout) {
      _lastProgressAt = now;
      _reconnectOrFail('Stream stalled');
    }
  }

  // Unlike Android's ExoPlayer, iOS AVPlayer never retries a dropped live stream (weak
  // signal, Wi-Fi/cellular handover, server closing a long-lived connection), so
  // reconnect with backoff before giving up.
  Future<void> _reconnectOrFail(Object error) async {
    final uri = _currentUri;
    if (!_wantsPlayback || uri == null || _reconnectAttempts >= _maxReconnectAttempts) {
      await _fail(error);
      return;
    }
    final backoff = Duration(seconds: 1 << _reconnectAttempts.clamp(0, 3));
    final delay = backoff > _maxReconnectDelay ? _maxReconnectDelay : backoff;
    _reconnectAttempts++;
    _reconnecting = true;
    final generation = ++_loadGeneration;
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.buffering,
      playing: true,
    ));
    await Future.delayed(delay);
    if (generation != _loadGeneration) return;
    // Setting playing first keeps the player "playing" through the reload, so the UI
    // shows loading rather than paused; playback resumes once the source is ready.
    unawaited(_player.play());
    try {
      await _load(uri, _currentHeaders, timeout: _reconnectLoadTimeout);
      if (generation == _loadGeneration) _reconnecting = false;
    } on PlayerInterruptedException {
      return;
    } catch (e) {
      if (generation == _loadGeneration) await _reconnectOrFail(e);
    }
  }

  Future<void> _load(Uri uri, Map<String, String> headers,
      {Duration timeout = _loadTimeout}) async {
    _activeLoads++;
    try {
      await _player
          .setAudioSource(AudioSource.uri(uri, headers: headers.isEmpty ? null : headers))
          .timeout(timeout);
    } finally {
      _activeLoads--;
    }
  }

  Future<void> _fail(Object e) async {
    _loadGeneration++;
    _wantsPlayback = false;
    _reconnecting = false;
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
            if (playbackState.value.playing == false && _wantsPlayback) {
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

  // True while the user wants audio: drives auto-resume after interruptions and
  // reconnecting after stream drops.
  bool _wantsPlayback = false;

  // Every play path (app button, lock screen, headphones) must re-arm auto-resume and
  // reactivate the session, since iOS may have deactivated it while idle or interrupted.
  @override
  Future<void> play() async {
    _wantsPlayback = true;
    final session = await AudioSession.instance;
    await session.setActive(true);
    await _player.play();
  }

  @override
  Future<void> pause() {
    _loadGeneration++;
    _wantsPlayback = false;
    _reconnecting = false;
    return _player.pause();
  }

  @override
  Future<void> stop() {
    _loadGeneration++;
    _wantsPlayback = false;
    _reconnecting = false;
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
    _currentUri = uri;
    _currentHeaders = headers;
    _reconnectAttempts = 0;
    _reconnecting = false;
    try {
      await _load(uri, headers);
    } on PlayerInterruptedException {
      return false;
    } catch (e) {
      if (generation == _loadGeneration) await _fail(e);
      rethrow;
    }
    if (generation != _loadGeneration) return false;
    // just_audio's play() future only completes when playback later pauses or stops.
    unawaited(play().catchError((Object e) => debugPrint('play() failed: $e')));
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
