import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';

import '../../../helpers/recording_audio_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('brush-stroke buffer', () {
    final wav = ProceduralAudioSynthesizer.generateChimeBuffer(ScholarTactileChime.brushStroke);
    final header = ByteData.sublistView(wav);
    final sampleCount = (wav.length - 44) ~/ 2;
    double sampleAt(int index) => header.getInt16(44 + index * 2, Endian.little) / 32768.0;

    test('is a valid 22,050 Hz 16-bit mono WAV', () {
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
      expect(header.getUint32(4, Endian.little), wav.length - 8);
      expect(header.getUint16(20, Endian.little), 1, reason: 'PCM');
      expect(header.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(header.getUint32(24, Endian.little), 22050);
      expect(header.getUint16(34, Endian.little), 16);
      expect(header.getUint32(40, Endian.little), wav.length - 44);
    });

    test('lasts about 140ms', () {
      expect(sampleCount / 22050 * 1000, closeTo(140, 1));
    });

    test('swells and dies away under a sine envelope, starting and ending in silence', () {
      double rms(int from, int to) {
        var sum = 0.0;
        for (var index = from; index < to; index++) {
          sum += sampleAt(index) * sampleAt(index);
        }
        return math.sqrt(sum / (to - from));
      }

      final tenth = sampleCount ~/ 10;
      final opening = rms(0, tenth);
      final middle = rms(4 * tenth, 6 * tenth);
      final closing = rms(9 * tenth, sampleCount);

      expect(sampleAt(0).abs(), lessThan(0.005));
      expect(sampleAt(sampleCount - 1).abs(), lessThan(0.02));
      expect(middle, greaterThan(opening * 2));
      expect(middle, greaterThan(closing * 2));
      expect(middle, inInclusiveRange(0.01, 0.2), reason: 'a soft rustle, not a hiss');
    });

    test('is band-passed around 920 Hz: most of its energy sits between 500 and 1700 Hz', () {
      // Goertzel-style band energy from a plain DFT over the buffer.
      double bandEnergy(double fromHz, double toHz) {
        var energy = 0.0;
        for (var hz = fromHz; hz < toHz; hz += 50) {
          var real = 0.0;
          var imaginary = 0.0;
          for (var index = 0; index < sampleCount; index++) {
            final phase = 2 * math.pi * hz * index / 22050;
            real += sampleAt(index) * math.cos(phase);
            imaginary -= sampleAt(index) * math.sin(phase);
          }
          energy += real * real + imaginary * imaginary;
        }
        return energy;
      }

      final inBand = bandEnergy(500, 1700);
      final total = bandEnergy(50, 11000);

      expect(inBand / total, greaterThan(0.5));
      expect(bandEnergy(4000, 11000) / total, lessThan(0.15));
    });

    test('is synthesized once and cached', () {
      expect(
        identical(ProceduralAudioSynthesizer.generateChimeBuffer(ScholarTactileChime.brushStroke), wav),
        isTrue,
      );
    });

    test('every tactile chime still synthesizes a WAV', () {
      for (final chime in ScholarTactileChime.values) {
        final buffer = ProceduralAudioSynthesizer.generateChimeBuffer(chime);
        expect(String.fromCharCodes(buffer.sublist(0, 4)), 'RIFF', reason: chime.name);
      }
    });
  });

  group('AudioSanctumService.playBrushStroke', () {
    late RecordingAudioPlayer player;
    late int playersCreated;
    late DateTime now;

    AudioSanctumService buildService({bool enablePlatformAudio = true}) {
      final service = AudioSanctumService(
        enablePlatformAudio: enablePlatformAudio,
        brushStrokePlayerFactory: () {
          playersCreated++;
          return player;
        },
        clock: () => now,
      );
      addTearDown(service.dispose);
      return service;
    }

    void advance(int milliseconds) => now = now.add(Duration(milliseconds: milliseconds));

    setUp(() {
      player = RecordingAudioPlayer();
      playersCreated = 0;
      now = DateTime(2026, 11, 16, 9);
    });

    test('plays the brush-stroke rustle at the chime volume', () async {
      final service = buildService();

      await service.playBrushStroke(soundEnabled: true);

      expect(player.played.length, 1);
      expect(
        (player.played.single as BytesSource).bytes,
        ProceduralAudioSynthesizer.generateChimeBuffer(ScholarTactileChime.brushStroke),
      );
      expect(player.lastVolume, closeTo(0.3, 1e-9), reason: '60% of the default 0.5 sanctum volume');
    });

    test('drops triggers arriving within 110ms of the last one played', () async {
      final service = buildService();

      await service.playBrushStroke(soundEnabled: true);
      advance(50);
      await service.playBrushStroke(soundEnabled: true);
      advance(59);
      await service.playBrushStroke(soundEnabled: true);
      expect(player.played.length, 1, reason: '50ms and 109ms after the first are both dropped');

      advance(1);
      await service.playBrushStroke(soundEnabled: true);
      expect(player.played.length, 2, reason: '110ms after the first plays again');

      advance(109);
      await service.playBrushStroke(soundEnabled: true);
      expect(player.played.length, 2);
      advance(1);
      await service.playBrushStroke(soundEnabled: true);
      expect(player.played.length, 3);
    });

    test('reuses one player and one buffer however many strokes are written', () async {
      final service = buildService();

      for (var stroke = 0; stroke < 40; stroke++) {
        await service.playBrushStroke(soundEnabled: true);
        advance(110);
      }

      expect(player.played.length, 40);
      expect(playersCreated, 1);
      expect(player.played.toSet().length, 1, reason: 'the same cached source every time');
    });

    test('loads the rustle into the player once and replays it from the start', () async {
      final service = buildService();

      for (var stroke = 0; stroke < 40; stroke++) {
        await service.playBrushStroke(soundEnabled: true);
        advance(110);
      }

      expect(player.played.length, 40);
      expect(player.sourcesLoaded, 1, reason: 'reloading re-prepares the platform player on every stroke (replay lag)');
      expect(player.requestedReleaseMode, ReleaseMode.stop, reason: 'the rustle must stay loaded after it plays');
    });

    test('drops a stroke while the previous rustle is still starting, so calls never pile up', () async {
      final service = buildService();
      final gate = Completer<void>();
      player.resumeGate = gate;

      final first = service.playBrushStroke(soundEnabled: true);
      for (var stroke = 0; stroke < 5; stroke++) {
        advance(110);
        await service.playBrushStroke(soundEnabled: true);
      }
      expect(player.played.length, 1, reason: 'strokes arriving while the player is busy are dropped');

      gate.complete();
      await first;
      advance(110);
      await service.playBrushStroke(soundEnabled: true);
      expect(player.played.length, 2);
    });

    test('is silent when brush sound is off, without starting the rate window', () async {
      final service = buildService();

      await service.playBrushStroke(soundEnabled: false);
      expect(player.played, isEmpty);
      expect(playersCreated, 0);

      await service.playBrushStroke(soundEnabled: true);
      expect(player.played.length, 1);
    });

    test('is silent when the sanctum volume is 0', () async {
      final service = buildService();
      await service.setVolume(0.0);

      await service.playBrushStroke(soundEnabled: true);

      expect(player.played, isEmpty);
    });

    test('is silent when platform audio is disabled', () async {
      final service = buildService(enablePlatformAudio: false);

      await service.playBrushStroke(soundEnabled: true);

      expect(player.played, isEmpty);
      expect(playersCreated, 0);
    });

    test('follows the sanctum volume', () async {
      final service = buildService();
      await service.setVolume(1.0);

      await service.playBrushStroke(soundEnabled: true);

      expect(player.lastVolume, closeTo(0.6, 1e-9));
    });

    test('disposing the service releases the brush-stroke player and silences later strokes', () async {
      final service = AudioSanctumService(brushStrokePlayerFactory: () => player, clock: () => now);
      await service.playBrushStroke(soundEnabled: true);

      service.dispose();
      advance(500);
      await service.playBrushStroke(soundEnabled: true);

      expect(player.isDisposed, isTrue);
      expect(player.played.length, 1);
    });
  });
}
