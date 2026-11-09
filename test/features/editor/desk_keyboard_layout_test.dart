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
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import 'package:memodiary/features/editor/widgets/writing_dock.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../helpers/editor_test_harness.dart';

const _entryId = 'desk_keyboard_entry';
const _phoneViewport = Size(360.0, 780.0);
const _keyboardInset = FakeViewPadding(bottom: 300.0);

/// The desk around the sheet and the software keyboard: where the page
/// indicator sits, that opening the keyboard never reflows the sheet, that the
/// caret stays above the keyboard, and that page turns keep the keyboard steady.
void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('desk_keyboard_layout_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);

    // Ten full rows on the opening sheet, the rest spilling onto a second sheet.
    final delta = Delta();
    for (int lineIndex = 1; lineIndex <= 14; lineIndex++) {
      delta.insert('第${lineIndex.toString().padLeft(2, '0')}行砚池墨痕\n');
    }
    await database.into(database.entries).insert(
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

  Future<void> openEditor(WidgetTester tester) => pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: _entryId,
        viewportSize: _phoneViewport,
      );

  List<TextStationerySheet> textSheets(WidgetTester tester) => tester
      .widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas))
      .coordinator
      .sheets
      .whereType<TextStationerySheet>()
      .toList();

  Rect activeCardRect(WidgetTester tester) => tester.getRect(find.byType(TemplateCanvasContainer).first);

  Future<void> startWritingAtEnd(WidgetTester tester, TextStationerySheet sheet) async {
    sheet.focusNode.requestFocus();
    await tester.pump();
    sheet.controller.updateSelection(
      TextSelection.collapsed(offset: sheet.controller.document.length - 1),
      ChangeSource.local,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openKeyboard(WidgetTester tester) async {
    tester.view.viewInsets = _keyboardInset;
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
  }

  group('Walnut desk layout', () {
    testWidgets('the walnut desk spans the canvas and the page indicator rests in the header band above the sheet', (tester) async {
      await openEditor(tester);

      expect(textSheets(tester), hasLength(2));
      final canvasRect = tester.getRect(find.byType(EditorPaperCanvas));
      expect(tester.getRect(find.byKey(const Key('editor_walnut_desk'))), canvasRect);

      final cardRect = activeCardRect(tester);
      final indicatorRect = tester.getRect(find.byKey(const Key('editor_sheet_indicator')));
      final workstationRect = tester.getRect(find.byKey(const Key('desk_workstation')));

      expect(indicatorRect.top, greaterThanOrEqualTo(canvasRect.top));
      expect(indicatorRect.bottom, lessThanOrEqualTo(cardRect.top));
      expect(workstationRect.top, greaterThanOrEqualTo(cardRect.bottom));

      // The chevron is centred on the sheet, not on the whole desk.
      final chevronCenter = tester.getCenter(find.byKey(const Key('editor_next_sheet_btn')));
      expect(chevronCenter.dy, closeTo(cardRect.center.dy, 1.0));
    });
  });

  group('Software keyboard', () {
    testWidgets('opening the keyboard leaves the sheet\'s size and ruling geometry unchanged', (tester) async {
      await openEditor(tester);
      final restingSize = activeCardRect(tester).size;
      final restingClip = tester.getRect(find.byKey(const Key('editor_paper_heart_viewport_clip')).first);
      final restingClipOffset = restingClip.top - activeCardRect(tester).top;

      await startWritingAtEnd(tester, textSheets(tester).first);
      await openKeyboard(tester);

      expect(activeCardRect(tester).size, restingSize);
      final clip = tester.getRect(find.byKey(const Key('editor_paper_heart_viewport_clip')).first);
      expect(clip.top - activeCardRect(tester).top, closeTo(restingClipOffset, 0.01));
      expect(clip.size, restingClip.size);
    });

    testWidgets('the caret on the last line stays above the Writing Dock, and the desk settles back when the keyboard closes', (tester) async {
      await openEditor(tester);
      final restingTop = activeCardRect(tester).top;
      final openingSheet = textSheets(tester).first;

      await startWritingAtEnd(tester, openingSheet);
      await openKeyboard(tester);

      final renderEditor = openingSheet.editorKey.currentState!.renderEditor;
      final localCaret = renderEditor.getLocalRectForCaret(openingSheet.controller.selection.extent);
      final caretBottom = renderEditor.localToGlobal(localCaret.bottomLeft).dy;
      final dockTop = tester.getRect(find.byType(WritingDock)).top;
      expect(caretBottom, lessThanOrEqualTo(dockTop));
      // Not merely positioned there: nothing between the caret and the dock clips it.
      final pageViewRect = tester.getRect(find.byType(PageView));
      expect(pageViewRect.bottom, greaterThanOrEqualTo(dockTop), reason: 'the page view must not clip the lifted sheet');
      expect(activeCardRect(tester).top, lessThan(restingTop), reason: 'the desk lifts to reveal the caret');

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(activeCardRect(tester).top, closeTo(restingTop, 0.5));
    });

    testWidgets('a caret near the top of the sheet keeps the desk where it rests', (tester) async {
      await openEditor(tester);
      final restingTop = activeCardRect(tester).top;
      final openingSheet = textSheets(tester).first;

      openingSheet.focusNode.requestFocus();
      await tester.pump();
      openingSheet.controller.updateSelection(const TextSelection.collapsed(offset: 0), ChangeSource.local);
      await openKeyboard(tester);

      expect(activeCardRect(tester).top, closeTo(restingTop, 0.5));
    });
  });

  group('Page turns while writing', () {
    testWidgets('tapping the next chevron carries focus to the next sheet without hiding the keyboard', (tester) async {
      await openEditor(tester);
      final sheets = textSheets(tester);
      await startWritingAtEnd(tester, sheets.first);
      expect(tester.testTextInput.isVisible, isTrue);
      tester.testTextInput.log.clear();

      await tester.tap(find.byKey(const Key('editor_next_sheet_btn')));
      await tester.pumpAndSettle();

      expect(find.text('第 2 / 2 页'), findsOneWidget);
      expect(sheets[1].focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(
        tester.testTextInput.log.map((call) => call.method),
        isNot(contains('TextInput.hide')),
        reason: 'the keyboard must not drop and pop back up on a page turn',
      );
    });

    testWidgets('turning pages with the keyboard closed does not summon it', (tester) async {
      await openEditor(tester);

      await tester.tap(find.byKey(const Key('editor_next_sheet_btn')));
      await tester.pumpAndSettle();

      expect(find.text('第 2 / 2 页'), findsOneWidget);
      expect(textSheets(tester).any((sheet) => sheet.focusNode.hasFocus), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    });
  });
}
