import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/editor/widgets/soundscape_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProceduralAudioSynthesizer & AudioSanctumService Tests', () {
    test('Synthesizes valid 4-second 22,050Hz 16-bit mono WAV buffer with 50ms linear fade-in/out', () {
      for (final preset in SoundscapePreset.values) {
        final wavBytes = ProceduralAudioSynthesizer.generateWavBuffer(preset);

        // Expected size: 44-byte WAV header + (22050 samples/sec * 4 sec * 2 bytes/sample) = 176,444 bytes
        const expectedSamples = 22050 * 4;
        const expectedByteLength = 44 + expectedSamples * 2;
        expect(wavBytes.length, equals(expectedByteLength));

        // Check RIFF & WAVE ASCII signatures
        final headerAscii = String.fromCharCodes(wavBytes.sublist(0, 4));
        final waveAscii = String.fromCharCodes(wavBytes.sublist(8, 12));
        expect(headerAscii, equals('RIFF'));
        expect(waveAscii, equals('WAVE'));

        final byteData = ByteData.sublistView(wavBytes);
        expect(byteData.getUint32(24, Endian.little), equals(22050)); // Sample rate
        expect(byteData.getUint16(34, Endian.little), equals(16)); // 16-bit PCM

        // Verify 50ms linear fade-in/out: first and last PCM samples must be 0 (click-free loop boundary)
        final firstSample = byteData.getInt16(44, Endian.little);
        final lastSample =
            byteData.getInt16(44 + (expectedSamples - 1) * 2, Endian.little);
        expect(firstSample, equals(0));
        expect(lastSample, equals(0));
      }
    });

    test('AudioSanctumService switches presets, clamps volume, and stops cleanly', () async {
      final service = AudioSanctumService(enablePlatformAudio: false);
      addTearDown(() => service.dispose());

      expect(service.isPlaying, isFalse);
      expect(service.activePreset, isNull);

      await service.selectPreset(SoundscapePreset.gentleRain);
      expect(service.isPlaying, isTrue);
      expect(service.activePreset, equals(SoundscapePreset.gentleRain));

      await service.setVolume(0.8);
      expect(service.volume, closeTo(0.8, 0.001));

      await service.setVolume(1.5);
      expect(service.volume, equals(1.0));

      await service.stop();
      expect(service.isPlaying, isFalse);
      expect(service.activePreset, isNull);
    });

    testWidgets('SoundscapeModal allows selecting soundscape preset and stopping playback', (tester) async {
      final service = AudioSanctumService(enablePlatformAudio: false);
      addTearDown(() => service.dispose());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoundscapeModal(sanctumService: service),
          ),
        ),
      );

      expect(find.text('Writing Sanctum Soundscapes'), findsOneWidget);
      expect(find.text('Gentle Rain'), findsOneWidget);
      expect(find.text('Vintage Library'), findsOneWidget);
      expect(find.text('Mechanical Study'), findsOneWidget);

      await tester.tap(find.byKey(const Key('soundscape_preset_vintage_library')));
      await tester.pumpAndSettle();

      expect(service.isPlaying, isTrue);
      expect(service.activePreset, equals(SoundscapePreset.vintageLibrary));

      await tester.tap(find.byKey(const Key('soundscape_stop_btn')));
      await tester.pumpAndSettle();

      expect(service.isPlaying, isFalse);
      expect(service.activePreset, isNull);
    });
  });
}
