import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_config.dart';
import 'package:memodiary/features/editor/ink_choreography/hanzi_stroke_table.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_controller.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/editor/services/editor_settings_service.dart';
import 'package:memodiary/features/editor/widgets/scholar_chest/scholar_chest_drawer.dart';

import '../../../helpers/mock_secure_storage.dart';
import '../../../helpers/recording_audio_player.dart';

void main() {
  late AppDatabase db;
  late AudioSanctumService audio;
  late MockSecureStorage storage;
  late InkChoreographyController controller;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    audio = AudioSanctumService(enablePlatformAudio: false);
    storage = MockSecureStorage();
    controller = InkChoreographyController(settings: EditorSettingsService(storage: storage));
  });

  tearDown(() async {
    controller.dispose();
    audio.dispose();
    await db.close();
  });

  Future<void> pumpDrawer(
    WidgetTester tester, {
    ScholarArtifactType? initialArtifact = ScholarArtifactType.twinBrushes,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScholarChestDrawer(
            database: db,
            activeTemplateId: 'template_blank_white',
            typography: const TypographySettings(fontSize: 16.0),
            audioSanctumService: audio,
            inkChoreography: controller,
            initialArtifact: initialArtifact,
            onSelectTemplate: (template) {},
            onTypographyChanged: (typography) {},
            onLockChanged: (lock) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('Twin Bamboo Brushes artifact badge', () {
    testWidgets('shows the live mode badge and semantics, never a placeholder', (tester) async {
      await pumpDrawer(tester, initialArtifact: null);

      const expectations = {
        InkDeliveryMode.singleFluent: ('双管 · 单笔', '单笔连绵'),
        InkDeliveryMode.multiConcurrent: ('双管 · 并笔', '并笔齐书'),
        InkDeliveryMode.inkOnly: ('双管 · 纯墨', '见墨不见笔'),
        InkDeliveryMode.off: ('双管 · 静书', '敛锋静书'),
      };
      for (final MapEntry(key: mode, value: (badge, name)) in expectations.entries) {
        controller.setDeliveryMode(mode);
        await tester.pump();
        expect(find.text(badge), findsOneWidget, reason: '$mode badge');
        expect(find.bySemanticsLabel('双管毛笔: 挥毫落墨 · $name'), findsOneWidget, reason: '$mode semantics');
      }
      expect(find.textContaining('敬请期待'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('敬请期待')), findsNothing);
    });
  });

  group('Ink Choreography selectors', () {
    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('each selector highlights in the open drawer, persists, and reloads in a fresh drawer',
        (tester) async {
      await pumpDrawer(tester);
      expect(find.text('挥毫落墨 · 双管笔意'), findsOneWidget);

      // Defaults are highlighted.
      expect(tester.getSemantics(find.byKey(const Key('chest_ink_mode_card_singleFluent'))),
          isSemantics(isSelected: true));
      expect(tester.getSemantics(find.byKey(const Key('chest_ink_stiffness_pill_mixed'))),
          isSemantics(isSelected: true));
      expect(tester.getSemantics(find.byKey(const Key('chest_ink_cadence_pill_standard'))),
          isSemantics(isSelected: true));

      await tapVisible(tester, find.byKey(const Key('chest_ink_mode_card_inkOnly')));
      await tapVisible(tester, find.byKey(const Key('chest_ink_stiffness_pill_goat')));
      await tapVisible(tester, find.byKey(const Key('chest_ink_cadence_pill_swift')));

      // The drawer is still open and shows the new choices.
      expect(find.byKey(const Key('chest_subpanel_twin_brushes')), findsOneWidget);
      expect(tester.getSemantics(find.byKey(const Key('chest_ink_mode_card_inkOnly'))),
          isSemantics(isSelected: true));
      expect(tester.getSemantics(find.byKey(const Key('chest_ink_mode_card_singleFluent'))),
          isSemantics(isSelected: false));
      expect(tester.getSemantics(find.byKey(const Key('chest_ink_stiffness_pill_goat'))),
          isSemantics(isSelected: true));
      expect(tester.getSemantics(find.byKey(const Key('chest_ink_cadence_pill_swift'))),
          isSemantics(isSelected: true));
      expect(find.text('双管 · 纯墨'), findsOneWidget);

      // A fresh controller over the same store reloads them into a new drawer.
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      controller = InkChoreographyController(settings: EditorSettingsService(storage: storage));
      await controller.restorePreferences();
      await pumpDrawer(tester);
      expect(tester.getSemantics(find.byKey(const Key('chest_ink_mode_card_inkOnly'))),
          isSemantics(isSelected: true));
      expect(tester.getSemantics(find.byKey(const Key('chest_ink_stiffness_pill_goat'))),
          isSemantics(isSelected: true));
      expect(tester.getSemantics(find.byKey(const Key('chest_ink_cadence_pill_swift'))),
          isSemantics(isSelected: true));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the brush sound toggle flips its label and persists', (tester) async {
      await pumpDrawer(tester);
      final toggle = find.byKey(const Key('chest_ink_sound_toggle'));
      expect(find.descendant(of: toggle, matching: find.text('🔊 运笔声效')), findsOneWidget);

      await tapVisible(tester, toggle);
      expect(find.descendant(of: toggle, matching: find.text('🔇 运笔声效')), findsOneWidget);
      expect(tester.getSemantics(toggle), isSemantics(isToggled: false));

      final reloaded = InkChoreographyController(settings: EditorSettingsService(storage: storage));
      addTearDown(reloaded.dispose);
      await reloaded.restorePreferences();
      expect(reloaded.config.soundEnabled, isFalse);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('全页挥毫 sheet replay', () {
    Future<void> openFromRoute(WidgetTester tester, {bool isEphemeraSheetActive = false}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ScholarChestDrawer.show(
                  context: context,
                  database: db,
                  activeTemplateId: 'template_blank_white',
                  typography: const TypographySettings(fontSize: 16.0),
                  audioSanctumService: audio,
                  inkChoreography: controller,
                  isEphemeraSheetActive: isEphemeraSheetActive,
                  initialArtifact: ScholarArtifactType.twinBrushes,
                  onSelectTemplate: (template) {},
                  onTypographyChanged: (typography) {},
                  onLockChanged: (lock) {},
                ),
                child: const Text('Open Chest'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Chest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('requests a sheet replay and puts the drawer away', (tester) async {
      await openFromRoute(tester);
      final replay = find.byKey(const Key('chest_ink_sheet_replay_button'));
      await tester.ensureVisible(replay);
      await tester.pump();
      await tester.tap(replay);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(controller.sheetReplayRequests.value, 1);
      expect(find.byKey(const Key('scholar_chest_drawer')), findsNothing);
      expect(controller.config.deliveryMode, InkDeliveryMode.singleFluent, reason: 'the saved mode is untouched');
    });

    testWidgets('is disabled on an ephemera sheet', (tester) async {
      await openFromRoute(tester, isEphemeraSheetActive: true);
      final replay = find.byKey(const Key('chest_ink_sheet_replay_button'));
      await tester.ensureVisible(replay);
      await tester.pump();
      expect(tester.getSemantics(replay), isSemantics(isEnabled: false));
      await tester.tap(replay, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      expect(controller.sheetReplayRequests.value, 0);
      expect(find.byKey(const Key('scholar_chest_drawer')), findsOneWidget);
    });
  });

  group('Trial Rice-Grid', () {
    final caption = find.byKey(const Key('chest_trial_grid_caption'));

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 16));
    }

    /// Pumps 60 Hz frames until the grid settles, up to [limit].
    Future<void> pumpUntilSettled(WidgetTester tester, {Duration limit = const Duration(seconds: 6)}) async {
      var waited = Duration.zero;
      while (tester.binding.hasScheduledFrame && waited < limit) {
        await tester.pump(const Duration(milliseconds: 16));
        waited += const Duration(milliseconds: 16);
      }
    }

    String captionText(WidgetTester tester) => tester.widget<Text>(caption).data!;

    testWidgets('a sample chip animates its character, then settles and stops ticking', (tester) async {
      await pumpDrawer(tester);
      await pumpUntilSettled(tester);
      expect(captionText(tester), '「永」落墨已成');

      await tapVisible(tester, find.byKey(const Key('chest_trial_grid_chip_墨')));
      expect(captionText(tester), '「墨」挥毫中');
      await tester.pump(const Duration(milliseconds: 300));
      expect(captionText(tester), '「墨」挥毫中', reason: 'still writing after 300ms');

      await pumpUntilSettled(tester);
      expect(captionText(tester), '「墨」落墨已成');
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'the ticker stops once settled');
      expect(find.byKey(const Key('chest_subpanel_twin_brushes')), findsOneWidget);
    });

    testWidgets('重演 and each selector replay the current sample', (tester) async {
      await pumpDrawer(tester);
      await pumpUntilSettled(tester);

      for (final key in [
        'chest_trial_grid_replay_button',
        'chest_ink_mode_card_multiConcurrent',
        'chest_ink_stiffness_pill_wolf',
        'chest_ink_cadence_pill_slow',
      ]) {
        await tapVisible(tester, find.byKey(Key(key)));
        expect(captionText(tester), '「永」挥毫中', reason: '$key replays');
        await pumpUntilSettled(tester, limit: const Duration(seconds: 10));
        expect(captionText(tester), '「永」落墨已成', reason: '$key settles');
      }
    });

    testWidgets('in off mode the grid still previews without changing the saved mode', (tester) async {
      controller.setDeliveryMode(InkDeliveryMode.off);
      await pumpDrawer(tester);
      await pumpUntilSettled(tester);

      await tapVisible(tester, find.byKey(const Key('chest_trial_grid_chip_E')));
      expect(captionText(tester), '「E」挥毫中');
      await pumpUntilSettled(tester);
      expect(captionText(tester), '「E」落墨已成');
      expect(controller.config.deliveryMode, InkDeliveryMode.off);
    });

    testWidgets('rustles once per stroke start, and stays silent with brush sound off', (tester) async {
      final player = RecordingAudioPlayer();
      var now = DateTime(2026);
      audio.dispose();
      audio = AudioSanctumService(
        brushStrokePlayerFactory: () => player,
        clock: () => now = now.add(const Duration(seconds: 1)),
      );
      await pumpDrawer(tester);
      await pumpUntilSettled(tester);
      player.played.clear();

      await tapVisible(tester, find.byKey(const Key('chest_trial_grid_chip_E')));
      await pumpUntilSettled(tester);
      expect(player.played, hasLength(HanziStrokeTable.instance.strokesFor('E')!.strokes.length));

      player.played.clear();
      await tapVisible(tester, find.byKey(const Key('chest_ink_sound_toggle')));
      await tapVisible(tester, find.byKey(const Key('chest_trial_grid_replay_button')));
      await pumpUntilSettled(tester);
      expect(player.played, isEmpty);
    });

    testWidgets('closing the drawer mid-stroke stops the ticker cleanly', (tester) async {
      await pumpDrawer(tester);
      await tester.pump(const Duration(milliseconds: 120));
      expect(captionText(tester), '「永」挥毫中');
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull, reason: 'no active ticker at dispose');
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'nothing keeps ticking');
    });
  });

  group('Compartment layout', () {
    testWidgets('fits a 320dp phone at text scale 1.3 and every control stays reachable', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: ScholarChestDrawer(
                  database: db,
                  activeTemplateId: 'template_blank_white',
                  typography: const TypographySettings(fontSize: 16.0),
                  audioSanctumService: audio,
                  inkChoreography: controller,
                  initialArtifact: ScholarArtifactType.twinBrushes,
                  onSelectTemplate: (template) {},
                  onTypographyChanged: (typography) {},
                  onLockChanged: (lock) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');

      for (final key in [
        'chest_ink_sound_toggle',
        'chest_ink_sheet_replay_button',
        'chest_trial_grid_replay_button',
        'chest_trial_grid_chip_A',
        'chest_ink_mode_card_off',
        'chest_ink_stiffness_pill_goat',
        'chest_ink_cadence_pill_swift',
      ]) {
        final finder = find.byKey(Key(key));
        await tester.ensureVisible(finder);
        await tester.pump(const Duration(milliseconds: 16));
        final rect = tester.getRect(finder);
        expect(rect.left, greaterThanOrEqualTo(0), reason: key);
        expect(rect.right, lessThanOrEqualTo(320), reason: key);
      }
      await tester.tap(find.byKey(const Key('chest_ink_cadence_pill_swift')));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getSemantics(find.byKey(const Key('chest_ink_cadence_pill_swift'))), isSemantics(isSelected: true));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
