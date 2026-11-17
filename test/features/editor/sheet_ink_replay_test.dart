import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_config.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_timeline.dart';
import 'package:memodiary/features/editor/services/editor_settings_service.dart';

import '../../helpers/editor_test_harness.dart';
import '../../helpers/sheet_ink_test_helpers.dart';

const _entryId = 'sheet_ink_replay_entry';
const _viewport = Size(360.0, 780.0);

/// Twelve one-row lines: nine fill the opening sheet of lined paper, three
/// continue on a second sheet.
final String _twoSheets = [for (var line = 1; line <= 12; line++) '第$line行'].join('\n');

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;
  late EditorSettingsService settings;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('sheet_ink_replay_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  Future<SheetInkRobot> openEditor(
    WidgetTester tester, {
    required InkDeliveryMode mode,
    String text = '山高 a\n水长',
  }) async {
    await seedInkEntry(database, entryId: _entryId, text: text);
    settings = await seededEditorSettings(inkDeliveryMode: mode);
    await pumpEntryEditorScreen(
      tester,
      database: database,
      mediaSandboxService: sandboxService,
      entryId: _entryId,
      audioSanctumService: FakeAudioSanctumService(),
      editorSettings: settings,
      inkDeliveryMode: null,
      viewportSize: _viewport,
    );
    return SheetInkRobot(tester);
  }

  /// Requests 全页挥毫 the way the Twin Bamboo Brushes compartment does, and
  /// pumps the frame that masks the sheet.
  Future<void> replay(SheetInkRobot robot) async {
    robot.preferences.requestSheetReplay();
    await robot.tester.pump();
  }

  testWidgets('replays every character with strokes in document order as a boosted Single Fluent Brush',
      (tester) async {
    final robot = await openEditor(tester, mode: InkDeliveryMode.multiConcurrent);

    await replay(robot);
    expect(robot.slotted(), '山高a水长');
    expect(robot.ink().isReplaying, isTrue);
    expect(robot.ink().slots.every((slot) => slot.geometry != null), isTrue, reason: 'the whole sheet is masked');

    await robot.pumpFrames(3);
    final slots = robot.ink().slots;
    expect(slots.first.isWriting, isTrue);
    expect(slots.skip(1).every((slot) => slot.isQueued), isTrue);
    expect(robot.ink().brushPoses(), hasLength(1));
    expect(
      slots.first.performance!.timeline.strokeDuration,
      InkChoreographyTimeline.strokeDuration(
        isCjk: true,
        speedMultiplier: 1.0,
        catchupMult: 1.9,
        replayBoost: InkChoreographyTimeline.replayBoost,
      ),
    );

    final savedBefore = robot.savedDelta;
    await robot.pumpUntilSettled();
    expect(robot.ink().isReplaying, isFalse);
    expect(robot.savedDelta, savedBefore);
  });

  testWidgets('a replay in off still writes the sheet out and leaves off saved', (tester) async {
    final robot = await openEditor(tester, mode: InkDeliveryMode.off);

    await replay(robot);
    await robot.pumpFrames(3);

    expect(robot.ink().slots.first.isWriting, isTrue);
    expect(robot.ink().slots.every((slot) => slot.delivery == InkDeliveryMode.singleFluent), isTrue);
    expect(robot.preferences.config.deliveryMode, InkDeliveryMode.off);
    expect((await settings.getInkChoreographyConfig()).deliveryMode, InkDeliveryMode.off);

    await robot.pumpUntilSettled();
    expect(robot.preferences.config.deliveryMode, InkDeliveryMode.off);
  });

  testWidgets('a tap on the sheet ends the replay in one frame', (tester) async {
    final robot = await openEditor(tester, mode: InkDeliveryMode.singleFluent);
    await replay(robot);
    await robot.pumpFrames(3);

    await tester.tapAt(tester.getCenter(robot.stageFinder()));
    expect(robot.ink().slots, isEmpty);

    await tester.pump(kInkTestFrame);
    expect(robot.stage().isAnimating, isFalse);
    expect(robot.ink().brushPoses(), isEmpty);
  });

  testWidgets('a keystroke ends the replay and is itself written under the saved mode', (tester) async {
    final robot = await openEditor(tester, mode: InkDeliveryMode.inkOnly);
    await robot.focus();
    await replay(robot);
    await robot.pumpFrames(3);
    expect(robot.ink().isReplaying, isTrue);

    await robot.type('云');

    expect(robot.slotted(), '云');
    expect(robot.ink().isReplaying, isFalse);
    expect(robot.ink().slots.single.delivery, InkDeliveryMode.inkOnly);
    await robot.pumpUntilSettled();
  });

  testWidgets('a keystroke in off ends the replay and nothing more is written', (tester) async {
    final robot = await openEditor(tester, mode: InkDeliveryMode.off);
    await robot.focus();
    await replay(robot);
    await robot.pumpFrames(3);

    await robot.type('云');

    expect(robot.ink().slots, isEmpty);
    await tester.pump(kInkTestFrame);
    expect(robot.stage().isAnimating, isFalse);
  });

  testWidgets('a page turn ends the replay in one frame; only the active sheet is replayed', (tester) async {
    final robot = await openEditor(tester, mode: InkDeliveryMode.singleFluent, text: _twoSheets);
    expect(robot.coordinator.totalSheets, 2);

    await replay(robot);
    await robot.pumpFrames(3);
    expect(robot.ink(0).slots, hasLength(27), reason: 'the nine rows of the opening sheet only');

    await tester.tap(find.byKey(const Key('editor_page_corner_next')));
    await tester.pump();
    expect(robot.ink(0).slots, isEmpty);
    expect(robot.stage(0).isAnimating, isFalse);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(robot.ink(1).slots, isEmpty, reason: 'the sheet turned to is not replayed');
  });
}
