import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import '../../helpers/editor_test_harness.dart';

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('freeze_repro_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);

    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: 'freeze_repro_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('冻结复现测试'),
            contentDelta: '[]',
            plainText: '',
            entryDate: DateTime(2026, 11, 4, 10, 30),
            mood: const Value(5),
            weather: const Value('晴'),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('Typing enters across page boundary preserves navigation and prevents freeze', (tester) async {
    await pumpEntryEditorScreen(
      tester,
      database: database,
      mediaSandboxService: sandboxService,
      entryId: 'freeze_repro_entry',
    );

    // Initial state: Sheet 1 of 1
    expect(find.text('第 1 / 1 页'), findsOneWidget);

    final firstEditorFinder = find.byType(QuillEditor);
    expect(firstEditorFinder, findsOneWidget);
    final firstEditor = tester.widget<QuillEditor>(firstEditorFinder);

    // Insert 9 enters to reach row 10 (Sheet 1 capacity)
    for (int i = 0; i < 9; i++) {
      firstEditor.controller.document.insert(
        firstEditor.controller.document.length - 1,
        '\n',
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('第 1 / 1 页'), findsOneWidget);

    // 11th enter triggers auto-spill onto Sheet 2
    firstEditor.controller.document.insert(
      firstEditor.controller.document.length - 1,
      '\n',
    );
    await tester.pumpAndSettle();

    // Verify page changed to Page 2
    expect(find.text('第 2 / 2 页'), findsOneWidget);

    // Find active QuillEditor on Sheet 2
    final secondEditorFinder = find.byType(QuillEditor);
    expect(secondEditorFinder, findsOneWidget);
    final secondEditor = tester.widget<QuillEditor>(secondEditorFinder);

    // Type 8 more enters on Sheet 2
    for (int i = 0; i < 8; i++) {
      secondEditor.controller.document.insert(
        secondEditor.controller.document.length - 1,
        '\n',
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // Page must remain on Page 2 and must not collapse or freeze
    expect(find.text('第 2 / 2 页'), findsOneWidget);

    // Type 15 enters on Sheet 2 to trigger cascading auto-spill onto Sheet 3
    for (int i = 0; i < 15; i++) {
      secondEditor.controller.document.insert(
        secondEditor.controller.document.length - 1,
        '\n',
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // Must be on Sheet 3 of 3
    expect(find.text('第 3 / 3 页'), findsOneWidget);

    // Navigate back to Sheet 2 via chevron
    final prevBtnFinder = find.byKey(const Key('editor_prev_sheet_btn'));
    expect(prevBtnFinder, findsOneWidget);
    await tester.tap(prevBtnFinder);
    await tester.pumpAndSettle();
    expect(find.text('第 2 / 3 页'), findsOneWidget);

    // Navigate back to Sheet 1 via chevron
    expect(prevBtnFinder, findsOneWidget);
    await tester.tap(prevBtnFinder);
    await tester.pumpAndSettle();
    expect(find.text('第 1 / 3 页'), findsOneWidget);

    // Navigate forward to Sheet 2 via chevron
    final nextBtnFinder = find.byKey(const Key('editor_next_sheet_btn'));
    expect(nextBtnFinder, findsOneWidget);
    await tester.tap(nextBtnFinder);
    await tester.pumpAndSettle();
    expect(find.text('第 2 / 3 页'), findsOneWidget);

    // Tap top bar back button to verify full exit navigation works
    final backBtnFinder = find.widgetWithIcon(IconButton, Icons.arrow_back);
    expect(backBtnFinder, findsOneWidget);
    await tester.tap(backBtnFinder);
    await tester.pumpAndSettle();
  });
}
