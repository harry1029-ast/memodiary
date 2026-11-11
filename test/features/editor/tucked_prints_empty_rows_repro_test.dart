import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/controllers/stationery_quill_controller.dart';
import 'package:memodiary/features/editor/models/mount_marker.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/tucked_prints_test_helpers.dart';

const _entryId = 'repro_empty_rows_entry';
const _viewport = Size(360.0, 780.0);

void main() {
  group('MountMarker unit tests', () {
    test('endOfTextOffset anchors after text and before trailing newlines', () {
      final delta = Delta()
        ..insert('春水')
        ..insert('\n\n\n');
      expect(MountMarker.endOfTextOffset(delta), 2);
    });

    test('endOfTextOffset anchors after trailing content embed and before newlines', () {
      final delta = Delta()
        ..insert({'image': 'sandbox/media/inline.webp'})
        ..insert('\n\n');
      expect(MountMarker.endOfTextOffset(delta), 1);
    });

    test('endOfTextOffset advances past existing consecutive mount markers', () {
      final delta = Delta()
        ..insert('荷花')
        ..insert({'mount': 'photo1'})
        ..insert({'mount': 'photo2'})
        ..insert('\n\n');
      expect(MountMarker.endOfTextOffset(delta), 4);
    });

    test('prevNonMarkerOffset finds character before marker', () {
      final delta = Delta()
        ..insert('字')
        ..insert({'mount': 'photo1'})
        ..insert('\n');
      expect(MountMarker.prevNonMarkerOffset(delta, 1), 0);
      expect(MountMarker.prevNonMarkerOffset(delta, 0), isNull);
    });
  });

  group('StationeryQuillController heuristics', () {
    test('inserting newline shifts past consecutive mount markers', () {
      final doc = Document.fromJson([
        {'insert': '诗'},
        {'insert': {'mount': 'photo1'}},
        {'insert': '\n'},
      ]);
      final controller = StationeryQuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 1),
      );

      // Typing Enter at offset 1 (before marker):
      controller.replaceText(1, 0, '\n', const TextSelection.collapsed(offset: 2));

      // Result should be: '诗' + {mount: photo1} + '\n' + '\n'
      final ops = controller.document.toDelta().operations;
      expect(ops[0].data, '诗');
      expect(MountMarker.mediaIdOf(ops[1]), 'photo1');
      expect(ops[2].data, '\n\n');
    });

    test('character-by-character backspace deletes text first, protecting marker when text is gone', () {
      final doc = Document.fromJson([
        {'insert': 'a'},
        {'insert': {'mount': 'photo1'}},
        {'insert': '\n'},
      ]);
      final controller = StationeryQuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 2),
      );

      // Backspace with cursor at offset 2 targeting marker at offset 1:
      // Redirects to offset 0, deleting 'a'.
      controller.replaceText(1, 1, '', const TextSelection.collapsed(offset: 1));
      expect(controller.document.toPlainText(), '\uFFFC\n');
      expect(MountMarker.isMarkerAt(controller.document.toDelta(), 0), isTrue);

      // Backspace again with cursor at offset 1: no text precedes marker.
      // Single-character collapsed backspace is suppressed, preserving the marker.
      controller.replaceText(0, 1, '', const TextSelection.collapsed(offset: 0));
      expect(MountMarker.isMarkerAt(controller.document.toDelta(), 0), isTrue);
      expect(controller.document.toPlainText(), '\uFFFC\n');
    });

    test('explicit 1-character selection over marker deletes marker', () {
      final doc = Document.fromJson([
        {'insert': 'abc'},
        {'insert': {'mount': 'photo1'}},
        {'insert': '\n'},
      ]);
      final controller = StationeryQuillController(
        document: doc,
        selection: const TextSelection(baseOffset: 3, extentOffset: 4),
      );

      // User highlighted the marker and pressed Backspace/Delete (not a collapsed cursor)
      controller.replaceText(3, 1, '', const TextSelection.collapsed(offset: 3));
      expect(MountMarker.isMarkerAt(controller.document.toDelta(), 3), isFalse);
      expect(controller.document.toPlainText(), 'abc\n');
    });
  });

  group('Tucked Prints widget integration', () {
    late AppDatabase database;
    late Directory tempDirectory;
    late MediaSandboxService sandboxService;

    setUpAll(() {
      VideoPlayerPlatform.instance = FakeEditorVideoPlatform();
    });

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      tempDirectory = Directory.systemTemp.createTempSync('repro_empty_rows_test_');
      sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
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
          viewportSize: _viewport,
        );

    QuillController openingController(WidgetTester tester) =>
        tester.widget<QuillEditor>(find.byType(QuillEditor).first).controller;

    Finder mountPinButton(String mediaId) => find.byKey(Key('handscroll_mount_$mediaId'));
    Finder handscrollItem(String mediaId) => find.byKey(Key('handscroll_item_$mediaId'));

    testWidgets('mounting on empty sheet 1, typing empty rows keeps photo on sheet 1', (tester) async {
      await seedMountedEntry(
        database,
        tempDirectory,
        entryId: _entryId,
        delta: Delta()..insert('\n'),
        stagedIds: ['photo1'],
      );
      await openEditor(tester);

      expect(mountPinButton('photo1'), findsOneWidget);
      await tester.tap(mountPinButton('photo1'));
      await tester.pumpAndSettle();

      expect(tuckedPrint('photo1'), findsOneWidget);
      expect(find.text('第 1 / 1 页'), findsOneWidget);

      final controller = openingController(tester);

      // User types empty rows until auto-spill creates sheet 2
      for (int i = 0; i < 11; i++) {
        final offset = controller.selection.baseOffset.clamp(0, controller.document.length - 1);
        controller.replaceText(offset, 0, '\n', TextSelection.collapsed(offset: offset + 1));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining(' / 2 页'), findsWidgets);

      // Turn back to Sheet 1:
      final prevCorner = find.byKey(const Key('editor_page_corner_prev'));
      if (prevCorner.evaluate().isNotEmpty) {
        await tester.tap(prevCorner);
        await tester.pumpAndSettle();
      }
      expect(find.text('第 1 / 2 页'), findsOneWidget);

      // photo1 should remain on sheet 1:
      expect(tuckedPrint('photo1'), findsOneWidget, reason: 'photo1 should remain on sheet 1 where it was mounted');
    });

    testWidgets('mounting on empty sheet 1, typing empty rows, saving and reopening preserves photo on sheet 1', (tester) async {
      await seedMountedEntry(
        database,
        tempDirectory,
        entryId: _entryId,
        delta: Delta()..insert('\n'),
        stagedIds: ['photo1'],
      );
      await openEditor(tester);

      await tester.tap(mountPinButton('photo1'));
      await tester.pumpAndSettle();

      final controller = openingController(tester);

      for (int i = 0; i < 11; i++) {
        final offset = controller.selection.baseOffset.clamp(0, controller.document.length - 1);
        controller.replaceText(offset, 0, '\n', TextSelection.collapsed(offset: offset + 1));
        await tester.pumpAndSettle();
      }

      // Wait for autosave debounce if needed
      await tester.pump(const Duration(seconds: 2));

      // Reopen in another tester pump
      await tester.pumpWidget(const SizedBox());
      await openEditor(tester);

      expect(tuckedPrint('photo1'), findsOneWidget);
    });

    testWidgets('mounting on text sheet 1, typing empty rows keeps photo on sheet 1', (tester) async {
      await seedMountedEntry(
        database,
        tempDirectory,
        entryId: _entryId,
        delta: Delta()..insert('初春微风\n'),
        stagedIds: ['photo1'],
      );
      await openEditor(tester);

      expect(mountPinButton('photo1'), findsOneWidget);
      await tester.tap(mountPinButton('photo1'));
      await tester.pumpAndSettle();

      expect(tuckedPrint('photo1'), findsOneWidget);

      final controller = openingController(tester);
      controller.updateSelection(
        TextSelection.collapsed(offset: controller.document.length - 1),
        ChangeSource.local,
      );

      // User adds 11 empty rows at the end of the text
      for (int i = 0; i < 11; i++) {
        final offset = controller.selection.baseOffset.clamp(0, controller.document.length - 1);
        controller.replaceText(offset, 0, '\n', TextSelection.collapsed(offset: offset + 1));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining(' / 2 页'), findsWidgets);

      // Turn back to Sheet 1:
      final prevCorner = find.byKey(const Key('editor_page_corner_prev'));
      if (prevCorner.evaluate().isNotEmpty) {
        await tester.tap(prevCorner);
        await tester.pumpAndSettle();
      }
      expect(find.text('第 1 / 2 页'), findsOneWidget);

      expect(tuckedPrint('photo1'), findsOneWidget, reason: 'photo1 should remain on sheet 1 with its text');
    });

    testWidgets('typing empty rows above text until text spills moves photo to sheet 2 with text', (tester) async {
      await seedMountedEntry(
        database,
        tempDirectory,
        entryId: _entryId,
        delta: Delta()..insert('初春微风\n'),
        stagedIds: ['photo1'],
      );
      await openEditor(tester);

      await tester.tap(mountPinButton('photo1'));
      await tester.pumpAndSettle();
      expect(tuckedPrint('photo1'), findsOneWidget);

      final controller = openingController(tester);
      controller.updateSelection(const TextSelection.collapsed(offset: 0), ChangeSource.local);

      // User adds 11 empty rows above the text, pushing text onto sheet 2
      for (int i = 0; i < 11; i++) {
        controller.replaceText(0, 0, '\n', const TextSelection.collapsed(offset: 1));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining(' / 2 页'), findsWidgets);
      await goToSheet(tester, 2, 2);
      expect(find.text('第 2 / 2 页'), findsOneWidget);

      // photo1 should follow the spilled text to sheet 2:
      expect(tuckedPrint('photo1'), findsOneWidget, reason: 'photo1 should follow its text to sheet 2');
    });

    testWidgets('deleting an empty row deletes the newline, preserving the mount marker', (tester) async {
      await seedMountedEntry(
        database,
        tempDirectory,
        entryId: _entryId,
        delta: Delta()..insert('\n'),
        stagedIds: ['photo1'],
      );
      await openEditor(tester);

      await tester.tap(mountPinButton('photo1'));
      await tester.pumpAndSettle();
      expect(tuckedPrint('photo1'), findsOneWidget);

      final controller = openingController(tester);

      // User types "Hello" without newline
      controller.replaceText(0, 0, 'Hello', const TextSelection.collapsed(offset: 5));
      await tester.pumpAndSettle();

      // Delta: "Hello" + {mount: photo1} + "\n"
      // User presses Enter to create an empty line:
      controller.replaceText(5, 0, '\n', const TextSelection.collapsed(offset: 7));
      await tester.pumpAndSettle();

      // User presses Backspace on the empty row:
      // The cursor was after the newline of the empty line (offset 7), deleting 1 char (offset 6)
      controller.replaceText(6, 1, '', const TextSelection.collapsed(offset: 6));
      await tester.pumpAndSettle();

      expect(handscrollItem('photo1'), findsNothing, reason: 'Deleting an empty row should NOT unmount the photo');
      expect(tuckedPrint('photo1'), findsOneWidget, reason: 'photo1 should still be tucked onto sheet 1');
    });

    testWidgets('mounting on sheet with multiple trailing empty lines anchors to text', (tester) async {
      await seedMountedEntry(
        database,
        tempDirectory,
        entryId: _entryId,
        delta: Delta()..insert('春水\n\n\n'),
        stagedIds: ['photo1'],
      );
      await openEditor(tester);

      await tester.tap(mountPinButton('photo1'));
      await tester.pumpAndSettle();

      final controller = openingController(tester);
      final delta = controller.document.toDelta();

      // Marker should be immediately after '春水' (offset 2), before the newlines
      expect(MountMarker.isMarkerAt(delta, 2), isTrue);
      expect(tuckedPrint('photo1'), findsOneWidget);
    });

    testWidgets('deleting a passage (len > 1) still unmounts the item as expected by ADR-0009', (tester) async {
      await seedMountedEntry(
        database,
        tempDirectory,
        entryId: _entryId,
        delta: Delta()
          ..insert('断桥')
          ..insert('残雪')
          ..insert({'mount': 'photo1'})
          ..insert('\n'),
        stagedIds: ['photo1'],
      );
      await openEditor(tester);

      expect(tuckedPrint('photo1'), findsOneWidget);
      final controller = openingController(tester);

      // Deleting a 3-character passage (len = 3)
      controller.replaceText(2, 3, '', const TextSelection.collapsed(offset: 2));
      await tester.pumpAndSettle();

      expect(tuckedPrint('photo1'), findsNothing);
      expect(handscrollItem('photo1'), findsOneWidget);
    });

    testWidgets('continuation sheet with Tucked Print stays on swipe, deletes character first, then collapses on Backspace and returns print to Staging Handscroll', (tester) async {
      await seedMountedEntry(database, tempDirectory, entryId: _entryId, delta: Delta()..insert('\n'), stagedIds: ['photo1']);
      await openEditor(tester);

      final sheet1Controller = openingController(tester);
      for (int i = 0; i < 10; i++) {
        final offset = sheet1Controller.selection.baseOffset.clamp(0, sheet1Controller.document.length - 1);
        sheet1Controller.replaceText(offset, 0, '\n', TextSelection.collapsed(offset: offset + 1));
        await tester.pumpAndSettle();
      }
      expect(find.text('第 2 / 2 页'), findsOneWidget);

      await tester.tap(mountPinButton('photo1'));
      await tester.pumpAndSettle();
      expect(tuckedPrint('photo1'), findsOneWidget);
      expect(handscrollItem('photo1'), findsNothing);

      await goToSheet(tester, 1, 2);
      expect(find.text('第 1 / 2 页'), findsOneWidget);
      await goToSheet(tester, 2, 2);
      expect(find.text('第 2 / 2 页'), findsOneWidget);
      expect(tuckedPrint('photo1'), findsOneWidget);

      final sheet2Controller = tester.widgetList<QuillEditor>(find.byType(QuillEditor)).last.controller;
      final insertOffset = sheet2Controller.document.length - 1;
      sheet2Controller.replaceText(insertOffset, 0, 'A', TextSelection.collapsed(offset: insertOffset + 1));
      await tester.pumpAndSettle();
      expect(sheet2Controller.document.toPlainText(), contains('A'));

      sheet2Controller.replaceText(insertOffset, 1, '', TextSelection.collapsed(offset: insertOffset));
      await tester.pumpAndSettle();
      expect(find.text('第 2 / 2 页'), findsOneWidget);
      expect(tuckedPrint('photo1'), findsOneWidget);

      sheet2Controller.updateSelection(const TextSelection.collapsed(offset: 1), ChangeSource.local);
      sheet2Controller.replaceText(0, 1, '', const TextSelection.collapsed(offset: 0));
      await tester.pumpAndSettle();

      expect(find.text('第 1 / 1 页'), findsOneWidget);
      expect(tuckedPrint('photo1'), findsNothing);
      expect(handscrollItem('photo1'), findsOneWidget);
      expect(sheet1Controller.selection.baseOffset, sheet1Controller.document.length - 1);
    });

    testWidgets('tapping unoccupied ruled space in the Paper Heart below existing text focuses the sheet and places caret at end of text without adding newlines', (tester) async {
      await seedMountedEntry(database, tempDirectory, entryId: _entryId, delta: Delta()..insert('第一行文字\n'), stagedIds: const []);
      await openEditor(tester);

      final editor = tester.widget<QuillEditor>(find.byType(QuillEditor).first);
      final controller = editor.controller;
      controller.updateSelection(const TextSelection.collapsed(offset: 0), ChangeSource.local);
      editor.focusNode.unfocus();
      await tester.pumpAndSettle();
      expect(editor.focusNode.hasFocus, isFalse);

      final paperHeartRect = tester.getRect(find.byKey(const Key('editor_paper_heart_viewport_clip')).first);
      await tester.tapAt(Offset(paperHeartRect.center.dx, paperHeartRect.bottom - 24.0));
      await tester.pumpAndSettle();

      expect(editor.focusNode.hasFocus, isTrue);
      expect(controller.selection.baseOffset, 5);
      expect(controller.document.toPlainText(), '第一行文字\n');
    });
  });
}
