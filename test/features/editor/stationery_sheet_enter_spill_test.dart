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
    tempDirectory = Directory.systemTemp.createTempSync('enter_spill_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);

    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: 'enter_spill_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('测试回车溢行与销毁'),
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

  testWidgets('Typing enters onto Sheet 2 preserves document and allows full navigation', (tester) async {
    await pumpEntryEditorScreen(
      tester,
      database: database,
      mediaSandboxService: sandboxService,
      entryId: 'enter_spill_entry',
    );

    final editorFinder = find.byType(QuillEditor);
    final firstEditor = tester.widget<QuillEditor>(editorFinder);

    // Initial empty doc has length 1 (1 line)
    // Insert 9 more enters -> total 10 lines on Sheet 1
    for (int enterIndex = 0; enterIndex < 9; enterIndex++) {
      _typeEnterAtEnd(firstEditor.controller);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('第 1 / 1 页'), findsOneWidget);

    // Insert 11th enter -> spills cleanly to Sheet 2
    _typeEnterAtEnd(firstEditor.controller);
    await tester.pumpAndSettle();

    expect(find.text('第 2 / 2 页'), findsOneWidget);

    // Typing multiple enters on Sheet 2 must not trigger premature empty-sheet collapse
    final secondEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    for (int enterIndex = 0; enterIndex < 5; enterIndex++) {
      _typeEnterAtEnd(secondEditor.controller);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('第 2 / 2 页'), findsOneWidget);
    expect(secondEditor.controller.document.length, greaterThan(5));

    // Navigate back to Sheet 1 via Page Corner
    final prevBtnFinder = find.byKey(const Key('editor_page_corner_prev'));
    expect(prevBtnFinder, findsOneWidget);
    await tester.tap(prevBtnFinder);
    await tester.pumpAndSettle();
    expect(find.text('第 1 / 2 页'), findsOneWidget);

    // Navigate forward to Sheet 2 via Page Corner
    final nextBtnFinder = find.byKey(const Key('editor_page_corner_next'));
    expect(nextBtnFinder, findsOneWidget);
    await tester.tap(nextBtnFinder);
    await tester.pumpAndSettle();
    expect(find.text('第 2 / 2 页'), findsOneWidget);

    // Deleting all content on Sheet 2 down to length 1 triggers trailing sheet collapse
    secondEditor.controller.document.delete(
      0,
      secondEditor.controller.document.length - 1,
    );
    await tester.pumpAndSettle();

    expect(find.text('第 1 / 1 页'), findsOneWidget);
  });
}

/// Presses Enter at the end of the sheet, the caret following as it does when typing.
void _typeEnterAtEnd(QuillController controller) {
  final endOffset = controller.document.length - 1;
  controller.replaceText(endOffset, 0, '\n', TextSelection.collapsed(offset: endOffset + 1));
}
