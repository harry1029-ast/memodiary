import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_config.dart';
import 'package:memodiary/features/editor/services/editor_settings_service.dart';

import '../../../helpers/mock_secure_storage.dart';

class _BrokenStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) =>
      Future.error(StateError('keystore unavailable'));

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) =>
      Future.error(StateError('keystore unavailable'));
}

void main() {
  group('Ink Choreography preferences', () {
    late MockSecureStorage storage;
    late EditorSettingsService settings;

    setUp(() {
      storage = MockSecureStorage();
      settings = EditorSettingsService(storage: storage);
    });

    test('an untouched store reads back the spec defaults', () async {
      final config = await settings.getInkChoreographyConfig();

      expect(config.deliveryMode, InkDeliveryMode.singleFluent);
      expect(config.bristleStiffness, BristleStiffness.mixed);
      expect(config.cadence, WritingCadence.standard);
      expect(config.soundEnabled, isTrue);
      expect(config, const InkChoreographyConfig());
    });

    test('each field round-trips through a fresh service on the same store', () async {
      await settings.setInkDeliveryMode(InkDeliveryMode.inkOnly);
      await settings.setBristleStiffness(BristleStiffness.goat);
      await settings.setWritingCadence(WritingCadence.swift);
      await settings.setBrushSoundEnabled(false);

      final reloaded = await EditorSettingsService(storage: storage).getInkChoreographyConfig();

      expect(
        reloaded,
        const InkChoreographyConfig(
          deliveryMode: InkDeliveryMode.inkOnly,
          bristleStiffness: BristleStiffness.goat,
          cadence: WritingCadence.swift,
          soundEnabled: false,
        ),
      );
    });

    test('every delivery mode, stiffness and cadence survives a round trip', () async {
      for (final mode in InkDeliveryMode.values) {
        await settings.setInkDeliveryMode(mode);
        expect((await settings.getInkChoreographyConfig()).deliveryMode, mode);
      }
      for (final stiffness in BristleStiffness.values) {
        await settings.setBristleStiffness(stiffness);
        expect((await settings.getInkChoreographyConfig()).bristleStiffness, stiffness);
      }
      for (final cadence in WritingCadence.values) {
        await settings.setWritingCadence(cadence);
        expect((await settings.getInkChoreographyConfig()).cadence, cadence);
      }
    });

    test('unknown stored values fall back to the defaults', () async {
      await settings.setInkDeliveryMode(InkDeliveryMode.off);
      await settings.setBristleStiffness(BristleStiffness.wolf);
      await settings.setWritingCadence(WritingCadence.slow);
      await settings.setBrushSoundEnabled(false);
      for (final key in storage.data.keys.toList()) {
        storage.data[key] = 'a-value-from-a-future-version';
      }

      expect(await settings.getInkChoreographyConfig(), const InkChoreographyConfig());
    });

    test('the preferences never disturb the Writing Dock preference', () async {
      await settings.setIsWritingDockHidden(true);
      await settings.setInkDeliveryMode(InkDeliveryMode.multiConcurrent);

      expect(await settings.getIsWritingDockHidden(), isTrue);
      expect((await settings.getInkChoreographyConfig()).deliveryMode, InkDeliveryMode.multiConcurrent);
    });

    test('storage errors are absorbed: reads give defaults and writes complete', () async {
      final broken = EditorSettingsService(storage: _BrokenStorage());

      await broken.setInkDeliveryMode(InkDeliveryMode.off);
      await broken.setBristleStiffness(BristleStiffness.goat);
      await broken.setWritingCadence(WritingCadence.swift);
      await broken.setBrushSoundEnabled(false);

      expect(await broken.getInkChoreographyConfig(), const InkChoreographyConfig());
    });
  });

  group('InkChoreographyConfig', () {
    test('presets carry the spec lag factors and speed multipliers', () {
      expect(BristleStiffness.wolf.lagFactor, 0.28);
      expect(BristleStiffness.mixed.lagFactor, 0.18);
      expect(BristleStiffness.goat.lagFactor, 0.11);
      expect(WritingCadence.slow.speedMultiplier, 0.55);
      expect(WritingCadence.standard.speedMultiplier, 1.0);
      expect(WritingCadence.swift.speedMultiplier, 1.8);
    });

    test('only the two brush modes show a bamboo brush', () {
      expect(InkDeliveryMode.singleFluent.showsBrush, isTrue);
      expect(InkDeliveryMode.multiConcurrent.showsBrush, isTrue);
      expect(InkDeliveryMode.inkOnly.showsBrush, isFalse);
      expect(InkDeliveryMode.off.showsBrush, isFalse);
    });

    test('copyWith changes one field and keeps value equality', () {
      const config = InkChoreographyConfig();
      final swift = config.copyWith(cadence: WritingCadence.swift);

      expect(swift.cadence, WritingCadence.swift);
      expect(swift.deliveryMode, config.deliveryMode);
      expect(swift == config, isFalse);
      expect(swift.copyWith(cadence: WritingCadence.standard), config);
    });
  });
}
