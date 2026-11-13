import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/soft_keyboard_test_helpers.dart';

const _entryId = 'desk_keyboard_entry';
const _phoneViewport = Size(360.0, 780.0);

/// The desk around the sheet and the software keyboard: where the page
/// indicator sits, that opening the keyboard never reflows or moves the sheet,
/// that the desk lifts the whole sheet above the accessory row on the
/// reference phone (or, when it cannot fit, keeps the caret and the last row
/// above it), and that page turns keep the keyboard steady.
void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('desk_keyboard_layout_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);

    // A full opening sheet (10 body rows), a full continuation sheet (14 rows)
    // and two rows on a third sheet.
    final delta = Delta();
    for (int lineIndex = 1; lineIndex <= 26; lineIndex++) {
      delta.insert('第${lineIndex.toString().padLeft(2, '0')}行砚池墨痕\n');
    }
    await database.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: _entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('案头'),
            contentDelta: jsonEncode(delta.toJson()),
            plainText: '砚池墨痕',
            entryDate: DateTime(2026, 11, 10, 20),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> openEditor(WidgetTester tester) async {
    simulatePhoneSystemBars(tester);
    await pumpEntryEditorScreen(
      tester,
      database: database,
      mediaSandboxService: sandboxService,
      entryId: _entryId,
      viewportSize: _phoneViewport,
    );
  }

  final accessoryRow = find.byKey(const Key('keyboard_accessory_row'));
  Rect canvasRect(WidgetTester tester) => tester.getRect(find.byType(EditorPaperCanvas));
  Rect activeCardRect(WidgetTester tester) => tester.getRect(find.byType(TemplateCanvasContainer).first);
  Rect activeClipRect(WidgetTester tester) =>
      tester.getRect(find.byKey(const Key('editor_paper_heart_viewport_clip')).first);
  double rowStride(WidgetTester tester) =>
      tester.widget<TemplateCanvasContainer>(find.byType(TemplateCanvasContainer).first).layoutMetrics!.lineStridePx;

  // Rects read through the lift's fractional translation differ in the last bits.
  void expectSameSize(Size actual, Size expected) {
    expect(actual.width, closeTo(expected.width, 0.01));
    expect(actual.height, closeTo(expected.height, 0.01));
  }

  /// Where the active sheet rests on the desk, independent of the chrome above it.
  double sheetOffsetOnDesk(WidgetTester tester) => activeCardRect(tester).top - canvasRect(tester).top;

  Future<void> goToSheet(WidgetTester tester, int sheetNumber) async {
    for (var turn = 1; turn < sheetNumber; turn++) {
      await tester.tap(find.byKey(const Key('editor_page_corner_next')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> collapseWorkstation(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('workstation_pull_tab')));
    await tester.pumpAndSettle();
  }

  /// Writes near the top of [sheet] and checks the whole sheet, every row of
  /// it, sits on the visible desk above the accessory row, unclipped.
  Future<void> expectWholeSheetVisibleWhileWriting(WidgetTester tester, TextStationerySheet sheet) async {
    await startWritingOn(tester, sheet, offset: 0);
    await openSoftKeyboard(tester);

    final accessoryTop = tester.getRect(accessoryRow).top;
    final deskTop = canvasRect(tester).top;
    final card = activeCardRect(tester);
    final rows = activeClipRect(tester);
    expect(rows.bottom, lessThanOrEqualTo(accessoryTop), reason: 'the last row is fully above the accessory row');
    expect(card.bottom, lessThanOrEqualTo(accessoryTop), reason: 'and so is the sheet\'s bottom edge');
    expect(card.top, greaterThanOrEqualTo(deskTop), reason: 'the sheet is not lifted off the top of the desk');
    expect(caretRectOf(sheet).top, greaterThanOrEqualTo(deskTop));
    expect(tester.getRect(find.byType(PageView)).bottom, greaterThanOrEqualTo(accessoryTop));
  }

  /// Writes at the end of [sheet]'s last row and checks that row, and the
  /// caret on it, sit fully above the accessory row, unclipped.
  Future<void> expectLastRowVisibleWhileWriting(WidgetTester tester, TextStationerySheet sheet,
      {double keyboardInset = kPhoneKeyboardInset}) async {
    await startWritingOn(tester, sheet);
    await openSoftKeyboard(tester, inset: keyboardInset);

    final accessoryTop = tester.getRect(accessoryRow).top;
    final lastRowBottom = activeClipRect(tester).bottom;
    final caret = caretRectOf(sheet);
    expect(caret.bottom, greaterThan(lastRowBottom - rowStride(tester)), reason: 'the caret is on the last row');
    expect(lastRowBottom, lessThanOrEqualTo(accessoryTop), reason: 'the last row is fully above the accessory row');
    expect(caret.bottom, lessThanOrEqualTo(accessoryTop));
    expect(caret.top, greaterThanOrEqualTo(canvasRect(tester).top), reason: 'and not lifted off the top of the desk');
    // Not merely positioned there: nothing between the row and the accessory row clips it.
    expect(tester.getRect(find.byType(PageView)).bottom, greaterThanOrEqualTo(accessoryTop));
    // The lift may carry the header band off the top, but never the save dot standing in for the app bar.
    final saveDot = tester.getRect(find.byKey(const Key('editor_save_state_dot')));
    expect(saveDot.top, greaterThanOrEqualTo(canvasRect(tester).top), reason: 'the save dot stays on the visible desk');
    // Above a keyboard too tall for the whole sheet, the top rows leave the desk and the dot rests over them.
    if (keyboardInset == kPhoneKeyboardInset) {
      expect(saveDot.bottom, lessThanOrEqualTo(activeClipRect(tester).top), reason: 'above the Paper Heart\'s rows');
    }
  }

  group('Walnut desk layout', () {
    testWidgets('the walnut desk spans the canvas and the page indicator rests at the left of the header band above the sheet', (tester) async {
      await openEditor(tester);

      expect(editorTextSheets(tester), hasLength(3));
      final canvasRect = tester.getRect(find.byType(EditorPaperCanvas));
      expect(tester.getRect(find.byKey(const Key('editor_scholar_desk'))), canvasRect);

      final cardRect = activeCardRect(tester);
      final indicatorRect = tester.getRect(find.byKey(const Key('editor_sheet_indicator')));
      final workstationRect = tester.getRect(find.byKey(const Key('desk_workstation')));

      expect(indicatorRect.top, greaterThanOrEqualTo(canvasRect.top));
      expect(indicatorRect.bottom, lessThanOrEqualTo(cardRect.top));
      expect(workstationRect.top, greaterThanOrEqualTo(cardRect.bottom));

      // The indicator sits at the left, leaving the band's right side free.
      expect(indicatorRect.right, lessThan(canvasRect.center.dx));
      expect(indicatorRect.left, lessThanOrEqualTo(canvasRect.left + 24.0));
      expect(find.text('文房书案'), findsNothing, reason: 'the desk engraving is gone');

      // The next Page Corner rests at the foot of the sheet, not mid-sheet.
      final cornerRect = tester.getRect(find.byKey(const Key('editor_page_corner_next')));
      expect(cornerRect.right, closeTo(canvasRect.right, 1.0));
      expect(cornerRect.top, lessThan(cardRect.bottom));
      expect(cornerRect.bottom, greaterThan(cardRect.bottom));
    });
  });

  group('Software keyboard', () {
    testWidgets('opening the keyboard leaves the sheet\'s size, ruling and clip unchanged', (tester) async {
      await openEditor(tester);
      final restingSize = activeCardRect(tester).size;
      final restingMetrics = tester.widget<TemplateCanvasContainer>(find.byType(TemplateCanvasContainer).first).layoutMetrics;
      final restingClip = activeClipRect(tester);
      final restingClipOffset = restingClip.top - activeCardRect(tester).top;

      await startWritingOn(tester, editorTextSheets(tester).first);
      await openSoftKeyboard(tester);

      expectSameSize(activeCardRect(tester).size, restingSize);
      expect(tester.widget<TemplateCanvasContainer>(find.byType(TemplateCanvasContainer).first).layoutMetrics, restingMetrics);
      final clip = activeClipRect(tester);
      expect(clip.top - activeCardRect(tester).top, closeTo(restingClipOffset, 0.01));
      expectSameSize(clip.size, restingClip.size);
    });

    testWidgets('writing on the last row of a full opening sheet keeps that row above the accessory row', (tester) async {
      await openEditor(tester);
      await expectLastRowVisibleWhileWriting(tester, editorTextSheets(tester).first);
    });

    testWidgets('writing on the last row of a full continuation sheet keeps that row above the accessory row', (tester) async {
      await openEditor(tester);
      await goToSheet(tester, 2);
      await expectLastRowVisibleWhileWriting(tester, editorTextSheets(tester)[1]);
    });

    testWidgets('the desk settles back where it rests when the keyboard closes', (tester) async {
      await openEditor(tester);
      final restingTop = activeCardRect(tester).top;

      await startWritingOn(tester, editorTextSheets(tester).first);
      await openSoftKeyboard(tester);
      expect(activeCardRect(tester).top, lessThan(restingTop));

      await closeSoftKeyboard(tester);
      expect(activeCardRect(tester).top, closeTo(restingTop, 0.5));
    });
  });

  // Whenever the whole sheet fits on the desk left above the keyboard and the
  // accessory row, the desk lifts so all of it shows, wherever the caret is.
  group('Whole-sheet lift', () {
    testWidgets('with the workstation put away and the caret on a high row, every row of a full opening sheet shows', (tester) async {
      await openEditor(tester);
      await collapseWorkstation(tester);
      await expectWholeSheetVisibleWhileWriting(tester, editorTextSheets(tester).first);
    });

    testWidgets('with the workstation put away and the caret on a high row, every row of a full continuation sheet shows', (tester) async {
      await openEditor(tester);
      await collapseWorkstation(tester);
      await goToSheet(tester, 2);
      await expectWholeSheetVisibleWhileWriting(tester, editorTextSheets(tester)[1]);
    });

    testWidgets('with the workstation docked and the caret on a high row, every row of the opening and continuation sheets shows', (tester) async {
      await openEditor(tester);
      await expectWholeSheetVisibleWhileWriting(tester, editorTextSheets(tester).first);
      await closeSoftKeyboard(tester);
      await goToSheet(tester, 2);
      await expectWholeSheetVisibleWhileWriting(tester, editorTextSheets(tester)[1]);
    });

    testWidgets('the lifted sheet keeps its size, ruling and clip', (tester) async {
      await openEditor(tester);
      await collapseWorkstation(tester);
      final restingSize = activeCardRect(tester).size;
      final restingMetrics = tester.widget<TemplateCanvasContainer>(find.byType(TemplateCanvasContainer).first).layoutMetrics;
      final restingClipSize = activeClipRect(tester).size;

      await expectWholeSheetVisibleWhileWriting(tester, editorTextSheets(tester).first);

      expectSameSize(activeCardRect(tester).size, restingSize);
      expect(tester.widget<TemplateCanvasContainer>(find.byType(TemplateCanvasContainer).first).layoutMetrics, restingMetrics);
      expectSameSize(activeClipRect(tester).size, restingClipSize);
    });
  });

  // A keyboard tall enough that the whole sheet cannot fit above it: the
  // two-rows-clear caret rule applies, clamped so the sheet's bottom edge can
  // always be reached.
  group('Caret lift when the sheet cannot fit', () {
    const tallKeyboardInset = 380.0;

    testWidgets('the sheet cannot fit above this keyboard', (tester) async {
      await openEditor(tester);
      final cardHeight = activeCardRect(tester).height;
      await startWritingOn(tester, editorTextSheets(tester).first, offset: 0);
      await openSoftKeyboard(tester, inset: tallKeyboardInset);
      expect(tester.getRect(accessoryRow).top - canvasRect(tester).top, lessThan(cardHeight));
    });

    testWidgets('writing on the last row of a full opening sheet keeps that row above the accessory row', (tester) async {
      await openEditor(tester);
      await expectLastRowVisibleWhileWriting(tester, editorTextSheets(tester).first, keyboardInset: tallKeyboardInset);
    });

    testWidgets('writing on the last row of a full continuation sheet keeps that row above the accessory row', (tester) async {
      await openEditor(tester);
      await collapseWorkstation(tester);
      await goToSheet(tester, 2);
      await expectLastRowVisibleWhileWriting(tester, editorTextSheets(tester)[1], keyboardInset: tallKeyboardInset);
    });

    testWidgets('the caret stays two rows above the accessory row, lifting no higher than it needs', (tester) async {
      await openEditor(tester);
      await goToSheet(tester, 2);
      final continuationSheet = editorTextSheets(tester)[1];
      // The end of the continuation sheet's 12th row (the 22nd line).
      const line = '第22行砚池墨痕';
      final restingOffset = sheetOffsetOnDesk(tester);

      await startWritingOn(tester, continuationSheet,
          offset: continuationSheet.controller.document.toPlainText().indexOf(line) + line.length);
      await openSoftKeyboard(tester, inset: tallKeyboardInset);

      final clearance = tester.getRect(accessoryRow).top - caretRectOf(continuationSheet).bottom;
      expect(clearance, closeTo(2 * rowStride(tester), 0.5));
      expect(sheetOffsetOnDesk(tester), lessThan(restingOffset), reason: 'the desk lifted to keep the rows clear');
    });

    testWidgets('a caret near the top keeps the centred sheet in place, even while the app bar slides back', (tester) async {
      await openEditor(tester);
      await collapseWorkstation(tester);
      final restingOffset = sheetOffsetOnDesk(tester);

      await startWritingOn(tester, editorTextSheets(tester).first, offset: 0);
      await openSoftKeyboard(tester, inset: tallKeyboardInset);
      expect(sheetOffsetOnDesk(tester), closeTo(restingOffset, 0.5));

      await closeSoftKeyboard(tester, settle: false);
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 40));
        expect(sheetOffsetOnDesk(tester), closeTo(restingOffset, 0.5), reason: 'frame $frame of the app bar\'s return');
      }
      await tester.pumpAndSettle();
      expect(sheetOffsetOnDesk(tester), closeTo(restingOffset, 0.5));
    });
  });

  group('Page turns while writing', () {
    testWidgets('tapping the next Page Corner carries focus to the next sheet without hiding the keyboard', (tester) async {
      await openEditor(tester);
      final sheets = editorTextSheets(tester);
      await startWritingOn(tester, sheets.first);
      await openSoftKeyboard(tester);
      expect(tester.testTextInput.isVisible, isTrue);
      tester.testTextInput.log.clear();

      await tester.tap(find.byKey(const Key('editor_page_corner_next')));
      await tester.pumpAndSettle();

      expect(find.text('第 2 / 3 页'), findsOneWidget);
      expect(sheets[1].focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      // The next sheet's editor takes over the input connection (and re-asserts
      // the keyboard), but the keyboard is never hidden in between.
      expect(
        tester.testTextInput.log.map((call) => call.method),
        isNot(contains('TextInput.hide')),
        reason: 'the keyboard must not drop and pop back up on a page turn',
      );
    });

    testWidgets('turning pages with the keyboard closed does not summon it', (tester) async {
      await openEditor(tester);

      await tester.tap(find.byKey(const Key('editor_page_corner_next')));
      await tester.pumpAndSettle();

      expect(find.text('第 2 / 3 页'), findsOneWidget);
      expect(editorTextSheets(tester).any((sheet) => sheet.focusNode.hasFocus), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    });
  });
}
