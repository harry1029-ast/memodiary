import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Records what a service asks an [AudioPlayer] to do, without a platform
/// audio engine.
///
/// [played] lists every sound actually started, whether through [play] or by
/// [resume]-ing the loaded source. [sourcesLoaded] counts how often a source
/// was handed to the player (each load re-prepares a real platform player).
class RecordingAudioPlayer implements AudioPlayer {
  final List<Source> played = [];
  int sourcesLoaded = 0;
  double? lastVolume;
  ReleaseMode? requestedReleaseMode;
  bool isDisposed = false;

  /// When set, [resume] waits for it, as a platform player still starting
  /// a sound does.
  Completer<void>? resumeGate;

  Source? _loaded;

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    if (volume != null) lastVolume = volume;
    await setSource(source);
    await resume();
  }

  @override
  Future<void> setSource(Source source) async {
    sourcesLoaded++;
    _loaded = source;
  }

  @override
  Future<void> setVolume(double volume) async => lastVolume = volume;

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async =>
      requestedReleaseMode = releaseMode;

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> resume() async {
    final loaded = _loaded;
    if (loaded != null) played.add(loaded);
    await resumeGate?.future;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async => isDisposed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
