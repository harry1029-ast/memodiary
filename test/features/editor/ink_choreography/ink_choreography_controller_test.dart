import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_config.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_controller.dart';
import 'package:memodiary/features/editor/services/editor_settings_service.dart';

import '../../../helpers/mock_secure_storage.dart';

void main() {
  late MockSecureStorage storage;
  late EditorSettingsService settings;
  late InkChoreographyController controller;
  late int notifications;

  setUp(() {
    storage = MockSecureStorage();
    settings = EditorSettingsService(storage: storage);
    controller = InkChoreographyController(settings: settings);
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  test('starts on the default config', () {
    expect(controller.config, const InkChoreographyConfig());
  });

  group('changing a preference', () {
    test('updates the live config and notifies once', () {
      controller.setDeliveryMode(InkDeliveryMode.multiConcurrent);

      expect(controller.config.deliveryMode, InkDeliveryMode.multiConcurrent);
      expect(notifications, 1);
    });

    test('re-selecting the current value does not notify', () {
      controller.setBristleStiffness(BristleStiffness.mixed);
      controller.setCadence(WritingCadence.standard);
      controller.setSoundEnabled(true);

      expect(notifications, 0);
    });

    test('writes every change through to the settings store', () async {
      controller.setDeliveryMode(InkDeliveryMode.inkOnly);
      controller.setBristleStiffness(BristleStiffness.wolf);
      controller.setCadence(WritingCadence.slow);
      controller.setSoundEnabled(false);
      await pumpEventQueue();

      expect(
        await EditorSettingsService(storage: storage).getInkChoreographyConfig(),
        const InkChoreographyConfig(
          deliveryMode: InkDeliveryMode.inkOnly,
          bristleStiffness: BristleStiffness.wolf,
          cadence: WritingCadence.slow,
          soundEnabled: false,
        ),
      );
    });

    test('a memory-only controller still holds the choice', () {
      final memoryOnly = InkChoreographyController();
      addTearDown(memoryOnly.dispose);

      memoryOnly.setCadence(WritingCadence.swift);

      expect(memoryOnly.config.cadence, WritingCadence.swift);
    });
  });

  group('restorePreferences', () {
    setUp(() async {
      await settings.setInkDeliveryMode(InkDeliveryMode.off);
      await settings.setBristleStiffness(BristleStiffness.goat);
      await settings.setWritingCadence(WritingCadence.swift);
      await settings.setBrushSoundEnabled(false);
    });

    test('applies the stored preferences and notifies', () async {
      await controller.restorePreferences();

      expect(
        controller.config,
        const InkChoreographyConfig(
          deliveryMode: InkDeliveryMode.off,
          bristleStiffness: BristleStiffness.goat,
          cadence: WritingCadence.swift,
          soundEnabled: false,
        ),
      );
      expect(notifications, 1);
    });

    test('never overwrites a choice made in this session while the store was loading', () async {
      final restore = controller.restorePreferences();
      controller.setDeliveryMode(InkDeliveryMode.multiConcurrent);
      controller.setSoundEnabled(true);
      await restore;

      expect(controller.config.deliveryMode, InkDeliveryMode.multiConcurrent);
      expect(controller.config.soundEnabled, isTrue, reason: 're-affirming the default is still a choice');
      expect(controller.config.bristleStiffness, BristleStiffness.goat, reason: 'untouched fields still restore');
      expect(controller.config.cadence, WritingCadence.swift);
    });

    test('stays quiet when the store already matches', () async {
      final fresh = InkChoreographyController(settings: EditorSettingsService(storage: MockSecureStorage()));
      addTearDown(fresh.dispose);
      var freshNotifications = 0;
      fresh.addListener(() => freshNotifications++);

      await fresh.restorePreferences();

      expect(freshNotifications, 0);
    });

    test('is safe after dispose', () async {
      final shortLived = InkChoreographyController(settings: settings);
      final restore = shortLived.restorePreferences();
      shortLived.dispose();

      await expectLater(restore, completes);
    });
  });

  group('requestSheetReplay', () {
    test('signals the replay listenable on every request without touching the config', () {
      var replays = 0;
      controller.sheetReplayRequests.addListener(() => replays++);

      controller.requestSheetReplay();
      controller.requestSheetReplay();

      expect(replays, 2);
      expect(controller.sheetReplayRequests.value, 2);
      expect(notifications, 0);
      expect(controller.config, const InkChoreographyConfig());
    });

    test('a replay requested while Off leaves the saved mode Off', () async {
      controller.setDeliveryMode(InkDeliveryMode.off);
      controller.requestSheetReplay();
      await pumpEventQueue();

      expect(controller.config.deliveryMode, InkDeliveryMode.off);
      expect((await settings.getInkChoreographyConfig()).deliveryMode, InkDeliveryMode.off);
    });
  });
}
