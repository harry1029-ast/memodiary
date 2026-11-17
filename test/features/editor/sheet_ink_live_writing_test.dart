import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_config.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';

import '../../helpers/editor_test_harness.dart';
import '../../helpers/sheet_ink_test_helpers.dart';

const _entryId = 'sheet_ink_live_entry';
const _viewport = Size(360.0, 780.0);

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;
  late FakeAudioSanctumService audio;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('sheet_ink_live_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
    audio = FakeAudioSanctumService();
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  Future<SheetInkRobot> openEditor(
    WidgetTester tester, {
    InkDeliveryMode mode = InkDeliveryMode.singleFluent,
    String text = '',
  }) async {
    await seedInkEntry(database, entryId: _entryId, text: text);
    await pumpEntryEditorScreen(
      tester,
      database: database,
      mediaSandboxService: sandboxService,
      entryId: _entryId,
      audioSanctumService: audio,
      inkDeliveryMode: mode,
      viewportSize: _viewport,
    );
    return SheetInkRobot(tester);
  }

  double rowStride(WidgetTester tester) =>
      tester.widget<TemplateCanvasContainer>(find.byType(TemplateCanvasContainer).first).layoutMetrics!.lineStridePx;

  group('a short committed insertion', () {
    testWidgets('is masked on its glyph and ruled row, written out, then settled; the Delta never changes',
        (tester) async {
      final robot = await openEditor(tester, text: '山');
      await robot.focus();

      await robot.type('高水');
      final typedDelta = robot.savedDelta;
      expect(typedDelta, '[{"insert":"山高水\\n"}]');

      // Masked in the very frame the glyphs appear.
      expect(robot.slotted(), '高水');
      expect(robot.stage().isAnimating, isTrue);
      for (final (slotIndex, offset) in [(0, 1), (1, 2)]) {
        final glyph = robot.glyphOnScreen(offset);
        final mask = robot.maskOnScreen(slotIndex);
        expect(mask.left, moreOrLessEquals(glyph.left, epsilon: 0.01));
        expect(mask.width, moreOrLessEquals(glyph.width, epsilon: 0.01));
        expect(mask.height, moreOrLessEquals(rowStride(tester), epsilon: 0.01));
        expect(mask.center.dy, moreOrLessEquals(glyph.centerY, epsilon: 0.01), reason: 'the glyph\'s ruled row');
      }

      await robot.pumpFrames(3);
      expect(robot.ink().slots.first.isWriting, isTrue);
      expect(robot.ink().slots.last.isQueued, isTrue);
      expect(robot.ink().brushPoses(), hasLength(1));

      await robot.pumpUntilSettled();
      expect(robot.ink().slots, isEmpty);
      expect(robot.ink().brushPoses(), isEmpty);
      expect(audio.brushStrokesPlayed, greaterThan(0));
      expect(robot.savedDelta, typedDelta);
      expect(robot.text(), '山高水');
    });

    testWidgets('masks rows on the sheet ruling: every mask starts a whole number of rows below the first',
        (tester) async {
      final robot = await openEditor(tester);
      await robot.focus();
      await robot.type('山\n高\n水');

      final stride = rowStride(tester);
      final firstTop = robot.maskOnScreen(0).top;
      expect(robot.maskOnScreen(1).top - firstTop, moreOrLessEquals(stride, epsilon: 0.01));
      expect(robot.maskOnScreen(2).top - firstTop, moreOrLessEquals(2 * stride, epsilon: 0.01));
    });

    testWidgets('in off appears at once with nothing animating', (tester) async {
      final robot = await openEditor(tester, mode: InkDeliveryMode.off);
      await robot.focus();
      await robot.type('山高');

      expect(robot.ink().slots, isEmpty);
      expect(robot.stage().isAnimating, isFalse);
    });

    testWidgets('switching to off while characters are in flight reveals them at once', (tester) async {
      final robot = await openEditor(tester);
      await robot.focus();
      await robot.type('山高');
      await robot.pumpFrames(3);

      robot.preferences.setDeliveryMode(InkDeliveryMode.off);

      expect(robot.ink().slots, isEmpty);
      await tester.pump(kInkTestFrame);
      expect(robot.stage().isAnimating, isFalse);
    });

    testWidgets('in Concurrent Multi-Brush every character is written at once with its own brush', (tester) async {
      final robot = await openEditor(tester, mode: InkDeliveryMode.multiConcurrent);
      await robot.focus();
      await robot.type('山高');
      await robot.pumpFrames(3);

      expect(robot.ink().slots.every((slot) => slot.isWriting), isTrue);
      expect(robot.ink().brushPoses(), hasLength(2));
      await robot.pumpUntilSettled();
    });

    testWidgets('in Ink-Only Bloom every character is written at once with no brush', (tester) async {
      final robot = await openEditor(tester, mode: InkDeliveryMode.inkOnly);
      await robot.focus();
      await robot.type('山高');
      await robot.pumpFrames(3);

      expect(robot.ink().slots.every((slot) => slot.isWriting), isTrue);
      expect(robot.ink().brushPoses(), isEmpty);
      await robot.pumpUntilSettled();
    });
  });

  group('IME composition', () {
    testWidgets('composing text is not animated until the candidate is committed', (tester) async {
      final robot = await openEditor(tester);
      await robot.focus();

      robot.keyboard('n', composing: const TextRange(start: 0, end: 1));
      await tester.pump();
      robot.keyboard('ni', composing: const TextRange(start: 0, end: 2));
      await tester.pump();
      expect(robot.text(), 'ni');
      expect(robot.ink().slots, isEmpty);
      expect(robot.stage().isAnimating, isFalse);

      robot.keyboard('你');
      await tester.pump();
      expect(robot.slotted(), '你');
      expect(robot.stage().isAnimating, isTrue);
      await robot.pumpUntilSettled();
      expect(robot.savedDelta, '[{"insert":"你\\n"}]');
    });

    testWidgets('a word the keyboard holds in its composing region is written whole when it commits',
        (tester) async {
      final robot = await openEditor(tester);
      await robot.focus();

      for (var length = 1; length <= 3; length++) {
        robot.keyboard('ink'.substring(0, length), composing: TextRange(start: 0, end: length));
        await tester.pump();
      }
      expect(robot.ink().slots, isEmpty);

      // The keyboard commits by clearing the composing range, text unchanged.
      robot.keyboard('ink');
      await tester.pump();
      expect(robot.slotted(), 'ink');
      await robot.pumpUntilSettled();
    });
  });

  group('edits around characters in flight', () {
    testWidgets('typing before queued characters keeps every slot on its own glyph', (tester) async {
      final robot = await openEditor(tester);
      await robot.focus();
      await robot.type('山高水长');
      await robot.pumpFrames(3);

      robot.keyboard('云山高水长', caret: 1);
      await tester.pump();

      expect(robot.text(), '云山高水长');
      final slots = robot.ink().slots;
      expect(robot.slotted(), '山高水长云');
      for (var slotIndex = 0; slotIndex < slots.length; slotIndex++) {
        final slot = slots[slotIndex];
        expect(robot.text()[slot.offset], slot.character);
        final glyph = robot.glyphOnScreen(slot.offset);
        expect(robot.maskOnScreen(slotIndex).left, moreOrLessEquals(glyph.left, epsilon: 0.01));
      }
      await robot.pumpUntilSettled();
    });

    testWidgets('deleting a character in flight drops its slot and keeps the rest', (tester) async {
      final robot = await openEditor(tester);
      await robot.focus();
      await robot.type('山高水');
      await robot.pumpFrames(2);

      robot.keyboard('山高');
      await tester.pump();

      expect(robot.slotted(), '山高');
      await robot.pumpUntilSettled();
      expect(robot.text(), '山高');
    });
  });
}
