import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/editor/widgets/paper_heart_metrics.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/services/stationery_layout_calculator.dart';

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = await Directory.systemTemp.createTemp('paginated_editor_stage_test_');
    sandboxService = MediaSandboxService(
      baseDirProvider: () async => tempDirectory,
      compressor: (sourcePath, targetPath, {minWidth = 1600, minHeight = 1600, quality = 80}) async {
        final source = File(sourcePath);
        return source.copy(targetPath);
      },
    );

    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: 'paginated_test_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('兰亭偶得'),
            contentDelta: '[]',
            plainText: '',
            entryDate: DateTime(2026, 11, 4, 10, 30),
            mood: const Value(5),
            weather: const Value('晴 · 微风'),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  group('Paginated Editor Stage - Navigation, Spill & Seal Tests', () {
    testWidgets('empty entry renders Sheet 1 with letterhead, page indicator 1/1, and hidden chevrons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: database,
            mediaSandboxService: sandboxService,
            entryId: 'paginated_test_entry',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // OpeningSheet renders letterhead
      expect(find.byType(JournalLetterhead), findsOneWidget);
      expect(find.text('兰亭偶得'), findsOneWidget);

      // Page indicator displays 第 1 / 1 页
      expect(find.byKey(const Key('editor_sheet_indicator')), findsOneWidget);
      expect(find.text('第 1 / 1 页'), findsOneWidget);

      // On Sheet 1 of 1, both border chevrons are hidden
      expect(find.byKey(const Key('editor_prev_sheet_btn')), findsNothing);
      expect(find.byKey(const Key('editor_next_sheet_btn')), findsNothing);

      // Bounded seal renders on the final (and only) sheet
      expect(find.byType(BoundedCinnabarSeal), findsOneWidget);
    });

    testWidgets('multi-sheet entry navigates via center-border chevrons and updates page indicator', (tester) async {
      // Create an entry with 3 sheets: Sheet 1 (10 rows), Sheet 2 (14 rows), Sheet 3 (5 rows)
      final multiSheetDelta = Delta();
      for (int lineIndex = 1; lineIndex <= 29; lineIndex++) {
        multiSheetDelta.insert('第${lineIndex.toString().padLeft(2, '0')}行信笺书法墨迹书写记录\n');
      }

      await database.updateEntryContent(
        'paginated_test_entry',
        jsonEncode(multiSheetDelta.toJson()),
        'Multi-sheet content',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: database,
            mediaSandboxService: sandboxService,
            entryId: 'paginated_test_entry',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On Sheet 0 (Sheet 1): left chevron hidden, right chevron visible, page indicator 第 1 / 3 页
      expect(find.text('第 1 / 3 页'), findsOneWidget);
      expect(find.byKey(const Key('editor_prev_sheet_btn')), findsNothing);
      expect(find.byKey(const Key('editor_next_sheet_btn')), findsOneWidget);
      expect(find.byType(BoundedCinnabarSeal), findsNothing, reason: 'Seal is final-sheet only');

      // Tap next chevron to glide forward to Sheet 2
      await tester.tap(find.byKey(const Key('editor_next_sheet_btn')));
      await tester.pumpAndSettle();

      // On Sheet 1 (Sheet 2): both chevrons visible, colophon header present
      expect(find.text('第 2 / 3 页'), findsOneWidget);
      expect(find.byKey(const Key('editor_prev_sheet_btn')), findsOneWidget);
      expect(find.byKey(const Key('editor_next_sheet_btn')), findsOneWidget);
      expect(find.byKey(const Key('editor_continuation_colophon_header')), findsOneWidget);
      expect(find.text('《兰亭偶得》 · 第 2 页'), findsOneWidget);
      expect(find.byType(BoundedCinnabarSeal), findsNothing);

      // Tap next chevron to advance to Sheet 3 (the final sheet)
      await tester.tap(find.byKey(const Key('editor_next_sheet_btn')));
      await tester.pumpAndSettle();

      // On Sheet 2 (Sheet 3): left chevron visible, right chevron hidden
      expect(find.text('第 3 / 3 页'), findsOneWidget);
      expect(find.byKey(const Key('editor_prev_sheet_btn')), findsOneWidget);
      expect(find.byKey(const Key('editor_next_sheet_btn')), findsNothing);
      expect(find.text('《兰亭偶得》 · 第 3 页'), findsOneWidget);
      expect(find.byType(BoundedCinnabarSeal), findsOneWidget, reason: 'Seal is present on final sheet');

      // Tap prev chevron to return to Sheet 2
      await tester.tap(find.byKey(const Key('editor_prev_sheet_btn')));
      await tester.pumpAndSettle();
      expect(find.text('第 2 / 3 页'), findsOneWidget);
    });

    testWidgets('final-sheet-only BoundedCinnabarSeal is strictly contained within innerFrameRect on 360px viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: database,
            mediaSandboxService: sandboxService,
            entryId: 'paginated_test_entry',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sealFinder = find.byType(BoundedCinnabarSeal);
      expect(sealFinder, findsOneWidget);

      final sealRect = tester.getRect(sealFinder);
      final metrics = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 360.0,
        canvasHeight: 640.0,
        backgroundType: TemplateBackgroundType.lined,
        horizontalMargin: 24.0,
        fontSize: 16.0,
        lineSpacing: 1.5,
      );

      final isContained = PaperHeartMetrics.isInsideDoubleOuterBorder(
        innerFrameRect: metrics.innerFrameRect,
        targetRect: sealRect,
      );
      expect(isContained, isTrue, reason: 'Seal must never protrude past Double Outer Border on 360px viewport');
    });

    testWidgets('typing Auto-Spill advances PageView forward and backspace Spill-Back collapses continuation sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: database,
            mediaSandboxService: sandboxService,
            entryId: 'paginated_test_entry',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('第 1 / 1 页'), findsOneWidget);

      // Access active QuillEditor
      final quillEditorFinder = find.byType(QuillEditor);
      expect(quillEditorFinder, findsOneWidget);
      final quillEditor = tester.widget<QuillEditor>(quillEditorFinder);

      // Insert 15 lines of text onto Sheet 1 (exceeds 10-line rowCapacity)
      for (int lineIndex = 1; lineIndex <= 15; lineIndex++) {
        final currentLength = quillEditor.controller.document.length;
        quillEditor.controller.document.insert(
          currentLength - 1,
          '第${lineIndex.toString().padLeft(2, '0')}行测试自动溢行溢出长段落文字内容\n',
        );
      }
      await tester.pumpAndSettle();

      // Auto-Spill must allocate Sheet 2 and advance to 第 2 / 2 页
      expect(find.text('第 2 / 2 页'), findsOneWidget);
      expect(find.byKey(const Key('editor_continuation_colophon_header')), findsOneWidget);

      // Simulate backspace at offset 0 on continuation sheet to trigger Spill-Back
      final secondSheetEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      secondSheetEditor.controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
      await tester.pumpAndSettle();

      // Clear continuation text and trigger backspace at offset 0
      secondSheetEditor.focusNode.requestFocus();
      await tester.pump();
      secondSheetEditor.controller.document.delete(
        0,
        secondSheetEditor.controller.document.length - 1,
      );
      secondSheetEditor.controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      // Continuation sheet collapses back to 第 1 / 1 页
      expect(find.text('第 1 / 1 页'), findsOneWidget);
    });
  });
}
