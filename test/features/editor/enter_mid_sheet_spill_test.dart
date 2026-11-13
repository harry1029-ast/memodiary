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
import '../../helpers/editor_test_harness.dart';

const _entryId = 'enter_mid_sheet_entry';

/// Blank lines count as rows, so a sheet holding a few words over many empty
/// lines can be full. Pressing Enter mid-sheet then spills only the trailing
/// blank row onto the next sheet: the caret must stay where the diarist is
/// writing rather than jump to the start of the next sheet.
void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('enter_mid_sheet_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);

    // A full opening sheet, then a second sheet: "wnd" over thirteen blank rows.
    final delta = Delta();
    for (int lineIndex = 1; lineIndex <= 10; lineIndex++) {
      delta.insert('第$lineIndex行\n');
    }
    delta.insert('wnd\n');
    delta.insert('\n' * 13);
    await database.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: _entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value(''),
            contentDelta: jsonEncode(delta.toJson()),
            plainText: 'wnd',
            entryDate: DateTime(2026, 11, 10, 13, 15),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  testWidgets('Enter on a full sheet of blank rows keeps the caret on that sheet', (tester) async {
    await pumpEntryEditorScreen(
      tester,
      database: database,
      mediaSandboxService: sandboxService,
      entryId: _entryId,
      viewportSize: const Size(360.0, 780.0),
    );
    final coordinator = tester.widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas)).coordinator;
    expect(coordinator.totalSheets, 2);

    await tester.tap(find.byKey(const Key('editor_page_corner_next')));
    await tester.pumpAndSettle();
    final secondSheet = coordinator.sheets[1] as TextStationerySheet;
    expect(secondSheet.plainText, startsWith('wnd'));
    secondSheet.focusNode.requestFocus();
    await tester.pump();

    // Caret on the third row ("wnd", blank, here), then Enter.
    const caret = 5;
    secondSheet.controller.updateSelection(const TextSelection.collapsed(offset: caret), ChangeSource.local);
    await tester.pump();
    secondSheet.controller.replaceText(caret, 0, '\n', const TextSelection.collapsed(offset: caret + 1));
    await tester.pumpAndSettle();

    expect(coordinator.totalSheets, 3, reason: 'the trailing blank row spills onto a new sheet');
    expect(find.text('第 2 / 3 页'), findsOneWidget, reason: 'the page must not turn');
    expect(secondSheet.focusNode.hasFocus, isTrue);
    expect(secondSheet.controller.selection, const TextSelection.collapsed(offset: caret + 1));
  });
}
