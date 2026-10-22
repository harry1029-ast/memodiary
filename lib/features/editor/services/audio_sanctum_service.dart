import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Available offline procedural soundscape presets for the Writing Sanctum.
enum SoundscapePreset {
  gentleRain(
    id: 'gentle_rain',
    label: 'Gentle Rain',
    subtitle: 'Soft filtered pink-noise rainfall',
  ),
  vintageLibrary(
    id: 'vintage_library',
    label: 'Vintage Library',
    subtitle: 'Warm brown-noise room tone & quiet hearth',
  ),
  mechanicalKeyboard(
    id: 'mechanical_keyboard',
    label: 'Mechanical Study',
    subtitle: 'Subtle study room ambience with soft rhythmic ticks',
  ),
  bambooBreeze(
    id: 'bamboo_breeze',
    label: 'Bamboo Breeze',
    subtitle: 'Gentle mountain wind swaying through pine and bamboo',
  );

  final String id;
  final String label;
  final String subtitle;

  const SoundscapePreset({
    required this.id,
    required this.label,
    required this.subtitle,
  });
}

/// Synthesizes 16-bit mono PCM WAV audio buffers in memory with zero external
/// asset bloat and a 50ms linear seam crossfade for click-free gapless looping.
class ProceduralAudioSynthesizer {
  static const int sampleRate = 22050;
  static const int bitsPerSample = 16;
  static const int numChannels = 1;
  static const int defaultDurationSeconds = 4; // 3-5s loop duration per safeguard
  static const int fadeDurationMs = 50; // 50ms linear fade-in/out per safeguard

  static final Map<SoundscapePreset, Uint8List> _cache = {};

  /// Returns a cached or freshly synthesized WAV byte buffer for [preset].
  static Uint8List generateWavBuffer(
    SoundscapePreset preset, {
    int durationSeconds = defaultDurationSeconds,
  }) {
    if (durationSeconds == defaultDurationSeconds && _cache.containsKey(preset)) {
      return _cache[preset]!;
    }

    final totalSamples = sampleRate * durationSeconds;
    final fadeSamples = (sampleRate * fadeDurationMs) ~/ 1000;
    final pcmSamples = Int16List(totalSamples);
    final rng = Random(preset.index + 1337);

    double lpState1 = 0.0;
    double lpState2 = 0.0;
    double brownState = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final white = rng.nextDouble() * 2.0 - 1.0;
      double sample = 0.0;

      switch (preset) {
        case SoundscapePreset.gentleRain:
          // Filtered pink-ish rainfall noise + soft droplet modulation
          lpState1 = 0.82 * lpState1 + 0.18 * white;
          lpState2 = 0.70 * lpState2 + 0.30 * lpState1;
          final slowWave = 0.85 + 0.15 * sin(2 * pi * i / (sampleRate * 2.0));
          sample = lpState2 * 0.38 * slowWave;
          break;

        case SoundscapePreset.vintageLibrary:
          // Warm deep brownian room tone
          brownState = (brownState + 0.03 * white).clamp(-1.0, 1.0);
          brownState *= 0.995;
          lpState1 = 0.92 * lpState1 + 0.08 * brownState;
          sample = lpState1 * 0.45;
          break;

        case SoundscapePreset.mechanicalKeyboard:
          // Soft ambient room tone + subtle periodic tactile study clicks
          lpState1 = 0.90 * lpState1 + 0.10 * white;
          double click = 0.0;
          final tickInterval = sampleRate ~/ 4; // 4 soft ticks per second
          final posInTick = i % tickInterval;
          if (posInTick < 140) {
            final decay = exp(-posInTick / 28.0);
            click = white * decay * 0.28;
          }
          sample = lpState1 * 0.16 + click;
          break;

        case SoundscapePreset.bambooBreeze:
          // Gentle modulated wind noise through bamboo grove
          lpState1 = 0.94 * lpState1 + 0.06 * white;
          final windWave = 0.65 + 0.35 * sin(2 * pi * i / (sampleRate * 3.5));
          sample = lpState1 * 0.36 * windWave;
          break;
      }

      // Apply 50ms linear fade-in at start and 50ms linear fade-out at end
      double envelope = 1.0;
      if (i < fadeSamples && fadeSamples > 0) {
        envelope = i / fadeSamples;
      } else if (i >= totalSamples - fadeSamples && fadeSamples > 0) {
        envelope = (totalSamples - 1 - i) / fadeSamples;
      }

      final scaled = (sample * envelope * 32767.0).round().clamp(-32768, 32767);
      pcmSamples[i] = scaled;
    }

    final wavBytes = _encodeWavHeaderAndPcm(pcmSamples, sampleRate);
    if (durationSeconds == defaultDurationSeconds) {
      _cache[preset] = wavBytes;
    }
    return wavBytes;
  }

  static Uint8List _encodeWavHeaderAndPcm(Int16List samples, int sampleRate) {
    final dataByteLength = samples.length * 2;
    final fileSize = 44 + dataByteLength;
    final byteData = ByteData(fileSize);

    // RIFF header
    _writeAscii(byteData, 0, 'RIFF');
    byteData.setUint32(4, fileSize - 8, Endian.little);
    _writeAscii(byteData, 8, 'WAVE');

    // fmt subchunk
    _writeAscii(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    byteData.setUint32(28, byteRate, Endian.little);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    byteData.setUint16(32, blockAlign, Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);

    // data subchunk
    _writeAscii(byteData, 36, 'data');
    byteData.setUint32(40, dataByteLength, Endian.little);

    int offset = 44;
    for (int i = 0; i < samples.length; i++) {
      byteData.setInt16(offset, samples[i], Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  static void _writeAscii(ByteData data, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}

/// Service managing offline background soundscape playback in the Writing Sanctum.
class AudioSanctumService extends ChangeNotifier {
  final AudioPlayer? _audioPlayer;
  final bool _enablePlatformAudio;
  AudioPlayer? _lazyPlayer;
  SoundscapePreset? _activePreset;
  bool _isPlaying = false;
  double _volume = 0.5;
  bool _isDisposed = false;

  AudioSanctumService({
    AudioPlayer? audioPlayer,
    bool enablePlatformAudio = true,
  })  : _audioPlayer = audioPlayer,
        _enablePlatformAudio = enablePlatformAudio;

  AudioPlayer? _getOrCreatePlayer() {
    if (!_enablePlatformAudio) return null;
    return _lazyPlayer ??= (_audioPlayer ?? AudioPlayer());
  }

  SoundscapePreset? get activePreset => _activePreset;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  /// Plays or switches to [preset].
  Future<void> play(SoundscapePreset preset) => selectPreset(preset);

  /// Starts or switches to [preset] in seamless loop mode.
  Future<void> selectPreset(SoundscapePreset? preset) async {
    if (_isDisposed) return;

    if (preset == null) {
      await stop();
      return;
    }

    _activePreset = preset;
    _isPlaying = true;
    notifyListeners();

    final player = _getOrCreatePlayer();
    if (player == null) return;

    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_volume);
      final wavBytes = ProceduralAudioSynthesizer.generateWavBuffer(preset);
      await player.play(BytesSource(wavBytes));
    } catch (e) {
      // Gracefully absorb platform channel errors in headless test environments
      debugPrint('AudioSanctumService playback fallback: $e');
    }
  }

  /// Updates the soundscape volume in [0.0, 1.0].
  Future<void> setVolume(double newVolume) async {
    if (_isDisposed) return;
    _volume = newVolume.clamp(0.0, 1.0);
    notifyListeners();

    final player = _lazyPlayer ?? _audioPlayer;
    if (player != null) {
      try {
        await player.setVolume(_volume);
      } catch (_) {}
    }
  }

  /// Stops ambient soundscape playback.
  Future<void> stop() async {
    if (_isDisposed) return;
    _activePreset = null;
    _isPlaying = false;
    notifyListeners();

    final player = _lazyPlayer ?? _audioPlayer;
    if (player != null) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    final player = _lazyPlayer ?? _audioPlayer;
    if (player != null) {
      try {
        player.stop();
        player.dispose();
      } catch (_) {}
    }
    super.dispose();
  }
}
