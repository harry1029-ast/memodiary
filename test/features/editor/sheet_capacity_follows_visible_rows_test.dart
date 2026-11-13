import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/services/editor_pagination_coordinator.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/tucked_prints_test_helpers.dart';

const _entryId = 'sheet_capacity_entry';
const _viewport = Size(360.0, 780.0);

/// The rows ruled inside each template's Paper Heart at the reference phone
/// size: lined paper's 29px rows fit 13 into the card, minimalist white's
/// 24px rows fill all 14.
const _visibleRowsByTemplate = {
  'template_lined_paper': 13,
  'template_minimalist_white': 14,
};

/// The Journal Letterhead's rows at the top of the opening sheet.
const _letterheadRows = 4;

/// [count] short one-row lines, numbered from [first].
String _lines(int count, {int first = 1}) =>
    [for (var line = first; line < first + count; line++) '第$line行\n'].join();

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('sheet_capacity_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  Future<void> seedEntry({required String templateId, String? text, Delta? delta}) async {
    final content = delta ?? (Delta()..insert(text!));
    await database.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: _entryId,
            notebookId: 'notebook_default',
            templateId: templateId,
            title: const Value('西湖夜泊'),
            contentDelta: jsonEncode(content.toJson()),
            plainText: '',
            entryDate: DateTime(2026, 11, 11, 21),
          ),
        );
  }

  /// Attaches a photo per id (in order) to the seeded entry.
  Future<void> seedPhotos(List<String> mediaIds) async {
    for (final mediaId in mediaIds) {
      File('${tempDirectory.path}/media/$mediaId.webp')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);
      await database.mediaOcrDao.attachMediaToEntry(
        id: mediaId,
        entryId: _entryId,
        relativePath: 'media/$mediaId.webp',
      );
    }
  }

  Future<void> openEditor(WidgetTester tester) => pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: _entryId,
        viewportSize: _viewport,
      );

  List<TextStationerySheet> textSheets(WidgetTester tester) => tester
      .widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas))
      .coordinator
      .sheets
      .whereType<TextStationerySheet>()
      .toList();

  /// Rows ruled inside the active sheet's Paper Heart.
  int visibleRows(WidgetTester tester) =>
      tester.widget<TemplateCanvasContainer>(find.byType(TemplateCanvasContainer).first).layoutMetrics!.rowCount;

  /// Rows of text on [sheet] (each seeded line is one row).
  int rowsOn(TextStationerySheet sheet) => sheet.document.toPlainText().split('\n').length - 1;

  double rowStride(WidgetTester tester) =>
      tester.widget<TemplateCanvasContainer>(find.byType(TemplateCanvasContainer).first).layoutMetrics!.lineStridePx;

  Future<void> turnToNextSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('editor_page_corner_next')));
    await tester.pumpAndSettle();
  }

  /// Types [text] at the end of [sheet] the way the keyboard does. With
  /// [whileComposing], Auto-Spill is deferred as it is during IME composition.
  Future<void> typeAtEnd(
    WidgetTester tester,
    TextStationerySheet sheet,
    String text, {
    EditorPaginationCoordinator? whileComposing,
  }) async {
    sheet.focusNode.requestFocus();
    await tester.pump();
    final end = sheet.document.length - 1;
    sheet.controller.updateSelection(TextSelection.collapsed(offset: end), ChangeSource.local);
    await tester.pump();
    whileComposing?.isImeComposing = true;
    sheet.controller.replaceText(end, 0, text, TextSelection.collapsed(offset: end + text.length));
    await tester.pumpAndSettle();
  }

  Finder activeEditor(WidgetTester tester, TextStationerySheet sheet) =>
      find.byWidgetPredicate((widget) => widget is QuillEditor && identical(widget.controller, sheet.controller));

  /// Rows the active [sheet]'s text occupies on screen (wrapped lines included).
  int renderedRows(WidgetTester tester, TextStationerySheet sheet) =>
      (tester.getSize(activeEditor(tester, sheet)).height / rowStride(tester)).round();

  Rect paperHeartOf(WidgetTester tester, Finder editor) => tester.getRect(
        find.ancestor(of: editor, matching: find.byKey(const Key('editor_paper_heart_viewport_clip'))),
      );

  /// Expects [sheet]'s text rows to start on a ruled row (beneath the
  /// letterhead on the opening sheet) and to end inside the Paper Heart.
  void expectRowsOnRuling(WidgetTester tester, TextStationerySheet sheet) {
    final editor = activeEditor(tester, sheet);
    final paperHeart = paperHeartOf(tester, editor);
    final firstRowTop = paperHeart.top + (sheet is OpeningSheet ? _letterheadRows * rowStride(tester) : 0.0);
    expect(tester.getTopLeft(editor).dy, moreOrLessEquals(firstRowTop), reason: 'text starts off the ruled rows');
    expect(tester.getBottomLeft(editor).dy, lessThanOrEqualTo(paperHeart.bottom + 0.01),
        reason: 'the last text row is cut off by the Paper Heart');
  }

  /// Expects [sheet]'s rows on the ruling, then drags the text up and down,
  /// expecting nothing on the sheet to move.
  Future<void> expectSheetContentFixedUnderDrag(WidgetTester tester, TextStationerySheet sheet) async {
    expectRowsOnRuling(tester, sheet);
    final editor = activeEditor(tester, sheet);
    final hasLetterhead = sheet is OpeningSheet;
    final editorBefore = tester.getTopLeft(editor);
    final letterheadBefore = hasLetterhead ? tester.getTopLeft(find.byType(JournalLetterhead)) : null;
    for (final drag in const [Offset(0, -150), Offset(0, 150)]) {
      await tester.drag(editor, drag, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(editor), editorBefore, reason: 'text rows moved under a $drag drag');
      if (hasLetterhead) {
        expect(tester.getTopLeft(find.byType(JournalLetterhead)), letterheadBefore,
            reason: 'the letterhead moved under a $drag drag');
      }
    }
  }

  for (final MapEntry(key: templateId, value: rows) in _visibleRowsByTemplate.entries) {
    testWidgets('on $templateId a full opening and a full continuation sheet hold their visible rows and stay put',
        (tester) async {
      final openingRows = rows - _letterheadRows;
      await seedEntry(templateId: templateId, text: _lines(openingRows + rows));
      await openEditor(tester);

      expect(visibleRows(tester), rows);
      final sheets = textSheets(tester);
      expect(sheets, hasLength(2));
      expect(rowsOn(sheets[0]), openingRows);
      expect(sheets[1].plainText, startsWith('第${openingRows + 1}行'));
      expect(rowsOn(sheets[1]), rows);

      await expectSheetContentFixedUnderDrag(tester, sheets[0]);
      await turnToNextSheet(tester);
      await expectSheetContentFixedUnderDrag(tester, textSheets(tester)[1]);
    });
  }

  // The editor's typography (13–28sp at 1.2–2.4 line spacing) and its
  // 380–420px card rule between 5 and 14 rows. A 16sp template with each line
  // spacing below rules one of those counts in the reference phone's card.
  const lineSpacingByVisibleRows = {
    14: 1.5,
    13: 1.8,
    12: 1.9,
    11: 2.1,
    10: 2.3,
    9: 2.6,
    8: 2.9,
    7: 3.3,
    6: 3.8,
    5: 4.4,
  };
  for (final MapEntry(key: rows, value: lineSpacing) in lineSpacingByVisibleRows.entries) {
    testWidgets('with $rows ruled rows, Auto-Spill moves text on exactly when the last ruled row is full',
        (tester) async {
      final templateId = 'template_rows_$rows';
      await database.templatesDao.createCustomTemplate(
        id: templateId,
        name: '$rows 行笺',
        backgroundType: 'color',
        backgroundValue: '#FFFFFF',
        lineSpacing: lineSpacing,
        marginHorizontal: 20.0,
      );
      final openingRows = rows - _letterheadRows;
      await seedEntry(templateId: templateId, text: _lines(openingRows + rows - 1));
      await openEditor(tester);
      expect(visibleRows(tester), rows);

      // Loaded: a full opening sheet, and Sheet 2 one row short of full.
      var sheets = textSheets(tester);
      expect(sheets, hasLength(2));
      expect(rowsOn(sheets[0]), openingRows);
      expect(rowsOn(sheets[1]), rows - 1);
      expectRowsOnRuling(tester, sheets[0]);

      // A row past the full opening sheet moves on and fills Sheet 2's last row.
      await typeAtEnd(tester, sheets[0], '\n首溢');
      sheets = textSheets(tester);
      expect(sheets, hasLength(2));
      expect(rowsOn(sheets[0]), openingRows);
      expect(sheets[1].plainText, startsWith('首溢\n第${openingRows + 1}行'));
      expect(rowsOn(sheets[1]), rows);
      expectRowsOnRuling(tester, sheets[1]);

      // A row past the full Sheet 2 starts Sheet 3.
      await typeAtEnd(tester, sheets[1], '\n末溢');
      sheets = textSheets(tester);
      expect(sheets, hasLength(3));
      expect(rowsOn(sheets[1]), rows);
      expect(sheets[2].plainText, startsWith('末溢\n'));
    });
  }

  group('sheets rebuilt from the saved Delta', () {
    // Short lines, a paragraph wrapping across the opening sheet's last row,
    // then enough lines for a third sheet.
    final text = '${_lines(7)}${'湖光山色' * 30}\n${_lines(16, first: 8)}';

    List<String> sheetTexts(WidgetTester tester) => [for (final sheet in textSheets(tester)) sheet.plainText];

    Future<void> saveAndReopen(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('editor_seal_done_btn')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await openEditor(tester);
    }

    Future<String> savedDelta() async => (await database.entriesDao.getEntryById(_entryId))!.contentDelta;

    testWidgets('are the same every time the entry opens at the same layout', (tester) async {
      await seedEntry(templateId: 'template_lined_paper', text: text);
      final seeded = await savedDelta();
      await openEditor(tester);
      final firstOpening = sheetTexts(tester);
      expect(firstOpening.length, greaterThanOrEqualTo(3));
      expect(firstOpening[0], contains('湖光'));
      expect(firstOpening[1], isNot(startsWith('第8行')), reason: 'the paragraph should wrap onto Sheet 2');

      for (var visit = 0; visit < 2; visit++) {
        await saveAndReopen(tester);
        expect(sheetTexts(tester), firstOpening);
        expect(jsonDecode(await savedDelta()), jsonDecode(seeded));
      }
    });

    testWidgets('re-split on a layout with fewer rows without changing the saved entry', (tester) async {
      await seedEntry(templateId: 'template_minimalist_white', text: text);
      final seeded = await savedDelta();
      await openEditor(tester);
      final fourteenRowSheets = sheetTexts(tester);
      expect(renderedRows(tester, textSheets(tester)[0]), 10);

      await database.entriesDao.updateEntryTemplate(_entryId, 'template_lined_paper');
      await saveAndReopen(tester);
      final thirteenRowSheets = sheetTexts(tester);
      expect(visibleRows(tester), 13);
      expect(renderedRows(tester, textSheets(tester)[0]), 9);
      expectRowsOnRuling(tester, textSheets(tester)[0]);
      expect(thirteenRowSheets, isNot(fourteenRowSheets));
      final coordinator = tester.widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas)).coordinator;
      expect(jsonDecode(coordinator.reSynthesize().$1), jsonDecode(seeded), reason: 'no text is lost or added');
      expect(jsonDecode(await savedDelta()), jsonDecode(seeded));
    });
  });

  testWidgets('a mounted item follows its passage to the sheet the ruled rows put it on', (tester) async {
    // Lined paper rules 13 rows: 9 body rows beneath the letterhead, so the
    // tenth line (and the item mounted beside it) opens Sheet 2.
    await seedEntry(
      templateId: 'template_lined_paper',
      delta: Delta()
        ..insert(_lines(8))
        ..insert('第9行')
        ..insert({'mount': 'ninth'})
        ..insert('\n第10行')
        ..insert({'mount': 'tenth'})
        ..insert('\n'),
    );
    await seedPhotos(['ninth', 'tenth']);
    await openEditor(tester);

    final sheets = textSheets(tester);
    expect(sheets, hasLength(2));
    expect(sheets[0].mediaAttachments.map((item) => item.id), ['ninth']);
    expect(tuckedPrint('ninth'), findsOneWidget);
    expect(tuckedPrint('tenth'), findsNothing);
    expectRowsOnRuling(tester, sheets[0]);

    await turnToNextSheet(tester);
    expect(tuckedPrint('tenth'), findsOneWidget);
    expect(tuckedPrint('ninth'), findsNothing);
    expect(textSheets(tester)[1].plainText, startsWith('第10行'));
  });

  testWidgets('a sheet holding a row more than it shows (Auto-Spill deferred while composing) still cannot be dragged',
      (tester) async {
    const rows = 13;
    await seedEntry(templateId: 'template_lined_paper', text: _lines(rows - _letterheadRows));
    await openEditor(tester);
    final coordinator = tester.widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas)).coordinator;
    final opening = textSheets(tester).single;
    final editor = activeEditor(tester, opening);
    final letterheadBefore = tester.getTopLeft(find.byType(JournalLetterhead));
    final editorBefore = tester.getTopLeft(editor);

    await typeAtEnd(tester, opening, '\n第十行', whileComposing: coordinator);
    expect(textSheets(tester), hasLength(1));
    expect(rowsOn(opening), rows - _letterheadRows + 1);
    expect(tester.getBottomLeft(editor).dy, greaterThan(paperHeartOf(tester, editor).bottom),
        reason: 'a row should hang below the Paper Heart');

    for (final drag in const [Offset(0, -150), Offset(0, 150)]) {
      await tester.drag(editor, drag, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(editor), editorBefore, reason: 'text rows moved under a $drag drag');
      expect(tester.getTopLeft(find.byType(JournalLetterhead)), letterheadBefore);
    }
  });
}
