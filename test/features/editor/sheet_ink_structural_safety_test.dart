import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_config.dart';
import 'package:memodiary/features/editor/models/mount_marker.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/widgets/page_corner.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';

import '../../helpers/editor_test_harness.dart';
import '../../helpers/sheet_ink_test_helpers.dart';
import '../../helpers/tucked_prints_test_helpers.dart';

const _entryId = 'sheet_ink_safety_entry';
const _viewport = Size(360.0, 780.0);

/// Lined paper rules 13 rows at the reference phone size; the Journal
/// Letterhead takes 4, so the opening sheet is full at 9 one-row lines.
const _rowsOnOpeningSheet = 9;

/// [count] short one-row lines, the last one left open.
String _lines(int count) => [for (var line = 1; line <= count; line++) '第$line行'].join('\n');

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('sheet_ink_safety_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  Future<SheetInkRobot> openSeeded(WidgetTester tester, {InkDeliveryMode mode = InkDeliveryMode.singleFluent}) async {
    await pumpEntryEditorScreen(
      tester,
      database: database,
      mediaSandboxService: sandboxService,
      entryId: _entryId,
      audioSanctumService: FakeAudioSanctumService(),
      inkDeliveryMode: mode,
      viewportSize: _viewport,
    );
    return SheetInkRobot(tester);
  }

  Future<SheetInkRobot> openEditor(
    WidgetTester tester, {
    InkDeliveryMode mode = InkDeliveryMode.singleFluent,
    String text = '',
  }) async {
    await seedInkEntry(database, entryId: _entryId, text: text);
    return openSeeded(tester, mode: mode);
  }

  double rowStride(WidgetTester tester) =>
      tester.widget<TemplateCanvasContainer>(find.byType(TemplateCanvasContainer).first).layoutMetrics!.lineStridePx;

  group('structural operations appear at once', () {
    testWidgets('opening an existing entry animates nothing', (tester) async {
      final robot = await openEditor(tester, text: '山高水长');

      expect(robot.ink().slots, isEmpty);
      expect(robot.stage().isAnimating, isFalse);
    });

    testWidgets('a paste over twenty characters is not animated and settles characters in flight', (tester) async {
      final robot = await openEditor(tester);
      await robot.focus();
      await robot.type('山高');
      expect(robot.slotted(), '山高');

      await robot.type('a' * 21);

      expect(robot.ink().slots, isEmpty);
      await tester.pump(kInkTestFrame);
      expect(robot.stage().isAnimating, isFalse);
      expect(robot.text(), '山高${'a' * 21}');
    });

    testWidgets('undo and redo are not animated and settle characters in flight', (tester) async {
      final robot = await openEditor(tester);
      await robot.focus();
      await robot.type('山高');
      await robot.pumpFrames(2);

      robot.sheet().controller.undo();
      expect(robot.ink().slots, isEmpty);
      await tester.pump(kInkTestFrame);
      expect(robot.stage().isAnimating, isFalse);
      expect(robot.text(), '');

      robot.sheet().controller.redo();
      await tester.pump(kInkTestFrame);
      expect(robot.ink().slots, isEmpty);
      expect(robot.text(), '山高');
    });

    testWidgets('an Auto-Spill settles characters in flight and animates nothing it moves', (tester) async {
      final robot = await openEditor(tester, text: _lines(_rowsOnOpeningSheet));
      await robot.focus();
      await robot.type('永');
      expect(robot.slotted(), '永');

      await robot.type('\n');
      expect(robot.coordinator.totalSheets, 2);
      expect(robot.ink(0).slots, isEmpty);
      expect(robot.text(0), '${_lines(_rowsOnOpeningSheet)}永');

      // The page turns to the sheet the caret spilled onto.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(robot.ink(1).slots, isEmpty);
      expect(robot.stage(1).isAnimating, isFalse);
    });

    testWidgets('after an Auto-Spill re-indexes the sheets, the sheet the caret stayed on is still written on',
        (tester) async {
      final robot = await openEditor(tester, text: _lines(_rowsOnOpeningSheet));
      await robot.focus();

      // Enter after the first line pushes the last row onto a new sheet; the caret stays.
      robot.keyboard(robot.text().replaceRange(3, 3, '\n'), caret: 4);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(robot.coordinator.totalSheets, 2);
      expect(robot.coordinator.activeSheetIndex, 0);

      robot.keyboard(robot.text().replaceRange(4, 4, '永'), caret: 5);
      await tester.pump();

      expect(robot.slotted(), '永');
      expect(robot.ink().slots.single.geometry, isNotNull, reason: 'located on the re-indexed sheet');
      await robot.pumpUntilSettled();
    });

    testWidgets('re-laying the sheets for new typography settles characters in flight; writing goes on after',
        (tester) async {
      final robot = await openEditor(tester);
      await robot.focus();
      await robot.type('山高');
      await robot.pumpFrames(2);

      robot.coordinator.updateTypography(const TypographySettings(fontSize: 18));
      await tester.pump();
      expect(robot.ink().slots, isEmpty);
      expect(robot.text(), '山高');

      await robot.focus();
      await robot.type('水');
      expect(robot.slotted(), '水');
      await robot.pumpUntilSettled();
    });
  });

  group('IME composition and pagination', () {
    testWidgets('Auto-Spill waits while the IME composes and runs when the composition commits', (tester) async {
      final robot = await openEditor(tester, mode: InkDeliveryMode.off, text: _lines(_rowsOnOpeningSheet));
      await robot.focus();
      final before = robot.text();
      final composed = 'a' * 60;

      // Sixty composing letters wrap onto rows the sheet does not have.
      robot.keyboard('$before$composed', composing: TextRange(start: before.length, end: before.length + 60));
      await tester.pump();
      expect(robot.coordinator.isImeComposing, isTrue);
      expect(robot.coordinator.totalSheets, 1);

      // The keyboard commits by clearing the composing range, text unchanged.
      robot.keyboard('$before$composed');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(robot.coordinator.isImeComposing, isFalse);
      expect(robot.coordinator.totalSheets, 2);
      expect('${robot.text(0)}${robot.text(1)}', '$before$composed');
    });
  });

  group('the editor underneath is untouched', () {
    testWidgets('mount markers stay put and the text stays on whole ruled rows while characters are written',
        (tester) async {
      await seedMountedEntry(database, tempDirectory, entryId: _entryId, mounted: 1);
      final robot = await openSeeded(tester);
      await robot.focus();

      final editor = find.byWidgetPredicate(
        (widget) => widget is QuillEditor && identical(widget.controller, robot.sheet().controller),
      );
      final stride = rowStride(tester);
      final editorRect = tester.getRect(editor);

      /// The ruled row (0-based, fractional) the glyph at [offset] is centred on.
      double rowOf(int offset) => (robot.glyphOnScreen(offset).centerY - editorRect.top) / stride;

      await robot.type('夜\n雨');
      await robot.pumpFrames(4);

      expect(robot.slotted(), '夜雨');
      expect(MountMarker.mediaIdsIn(robot.sheet().delta), ['print_0']);
      expect(tester.getRect(editor), editorRect);
      expect(rowOf(4), moreOrLessEquals(0.5, epsilon: 0.01));
      expect(rowOf(6), moreOrLessEquals(1.5, epsilon: 0.01));

      await robot.pumpUntilSettled();
      expect(MountMarker.mediaIdsIn(robot.sheet().delta), ['print_0']);
      expect(tester.getRect(editor), editorRect);
      expect(rowOf(6), moreOrLessEquals(1.5, epsilon: 0.01));
      expect(tuckedPrint('print_0'), findsOneWidget);
      expect(
        robot.savedDelta,
        '[{"insert":"雨巷。"},{"insert":{"mount":"print_0"}},{"insert":"夜\\n雨\\n"}]',
      );
    });

    testWidgets('the overlay never takes a pointer: a tap on a character being written places the caret',
        (tester) async {
      final robot = await openEditor(tester);
      await robot.focus();
      await robot.type('山高水长');
      await robot.pumpFrames(3);
      expect(robot.sheet().controller.selection.baseOffset, 4);

      final glyph = robot.glyphOnScreen(1);
      await tester.tapAt(Offset(glyph.left + 1, glyph.centerY));
      await tester.pump();

      expect(robot.sheet().controller.selection.baseOffset, 1);
      expect(robot.sheet().focusNode.hasFocus, isTrue);
      expect(robot.slotted(), '山高水长', reason: 'a tap ends a replay, not live writing');
      await robot.pumpUntilSettled();
    });

    testWidgets('the mask sits in the card between the sheet body and the Page Corner folds; the brush is unclipped',
        (tester) async {
      final robot = await openEditor(tester);
      final maskLayer = find.descendant(
        of: robot.stageFinder(),
        matching: find.byKey(const Key('editor_ink_mask_layer')),
      );
      final brushLayer = find.descendant(
        of: robot.stageFinder(),
        matching: find.byKey(const Key('editor_ink_brush_layer')),
      );
      Finder clipsAround(Finder layer) => find.descendant(
            of: robot.stageFinder(),
            matching: find.ancestor(
              of: layer,
              matching: find.byWidgetPredicate((widget) => widget is ClipRRect || widget is ClipRect),
            ),
          );

      expect(clipsAround(maskLayer), findsOneWidget, reason: 'the card clip only');
      expect(
        find.ancestor(of: maskLayer, matching: find.byKey(const Key('editor_paper_heart_viewport_clip'))),
        findsNothing,
      );
      expect(clipsAround(brushLayer), findsNothing);

      final cardLayers = tester.widget<Stack>(find.ancestor(of: maskLayer, matching: find.byType(Stack)).first);
      final maskIndex = cardLayers.children.indexWhere((child) => child.key == const Key('editor_ink_mask_layer'));
      expect(cardLayers.children[maskIndex - 1], isA<Theme>(), reason: 'above the sheet body');
      expect(cardLayers.children[maskIndex + 1], isA<PageCornerFolds>());
    });
  });
}
