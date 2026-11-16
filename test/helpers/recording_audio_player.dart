import 'package:audioplayers/audioplayers.dart';

/// Records what a service asks an [AudioPlayer] to do, without a platform
/// audio engine.
class RecordingAudioPlayer implements AudioPlayer {
  final List<Source> played = [];
  double? lastVolume;
  bool isDisposed = false;

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    played.add(source);
    lastVolume = volume;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async => isDisposed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
