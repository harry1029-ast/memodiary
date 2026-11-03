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
import 'package:memodiary/features/editor/widgets/integer_snapped_letterhead.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/editor/widgets/paper_heart_metrics.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/services/stationery_layout_calculator.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../helpers/editor_test_harness.dart';

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('paginated_editor_stage_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);

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
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  group('Paginated Editor Stage - Navigation, Spill & Seal Tests', () {
    testWidgets('empty entry renders 14-row clipped Paper Heart, 4-row letterhead, 1/1 badge, and hidden chevrons', (tester) async {
      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'paginated_test_entry',
      );

      expect(find.byType(JournalLetterhead), findsOneWidget);
      expect(find.text('兰亭偶得'), findsOneWidget);

      // Verify 4-row IntegerSnappedLetterhead and 14-row clipped Paper Heart
      final letterheadFinder = find.byType(IntegerSnappedLetterhead);
      final letterheadWidget = tester.widget<IntegerSnappedLetterhead>(letterheadFinder);
      final letterheadSize = tester.getSize(letterheadFinder);
      expect(letterheadSize.height, equals(4 * letterheadWidget.lineStridePx));

      final canvasContainer = tester.widget<TemplateCanvasContainer>(
        find.byType(TemplateCanvasContainer),
      );
      expect(canvasContainer.layoutMetrics!.rowCount, equals(14));

      final clipRectFinder = find.byKey(const Key('editor_paper_heart_viewport_clip'));
      expect(clipRectFinder, findsOneWidget);
      final clipSize = tester.getSize(clipRectFinder);
      expect(clipSize.height, equals(canvasContainer.layoutMetrics!.innerFrameRect.height));

      // Page indicator displays 第 1 / 1 页 and boundary chevrons are hidden
      expect(find.byKey(const Key('editor_sheet_indicator')), findsOneWidget);
      expect(find.text('第 1 / 1 页'), findsOneWidget);
      expect(find.byKey(const Key('editor_prev_sheet_btn')), findsNothing);
      expect(find.byKey(const Key('editor_next_sheet_btn')), findsNothing);
      expect(find.byType(BoundedCinnabarSeal), findsOneWidget);
    });

    testWidgets('multi-sheet entry navigates via center-border chevrons and updates page indicator', (tester) async {
      final multiSheetDelta = Delta();
      for (int lineIndex = 1; lineIndex <= 29; lineIndex++) {
        multiSheetDelta.insert('第${lineIndex.toString().padLeft(2, '0')}行信笺书法墨迹书写记录\n');
      }

      await database.updateEntryContent(
        'paginated_test_entry',
        jsonEncode(multiSheetDelta.toJson()),
        'Multi-sheet content',
      );

      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'paginated_test_entry',
      );

      expect(find.text('第 1 / 3 页'), findsOneWidget);
      expect(find.byKey(const Key('editor_prev_sheet_btn')), findsNothing);
      expect(find.byKey(const Key('editor_next_sheet_btn')), findsOneWidget);
      expect(find.byType(BoundedCinnabarSeal), findsNothing, reason: 'Seal is final-sheet only');

      await tester.tap(find.byKey(const Key('editor_next_sheet_btn')));
      await tester.pumpAndSettle();

      expect(find.text('第 2 / 3 页'), findsOneWidget);
      expect(find.byKey(const Key('editor_prev_sheet_btn')), findsOneWidget);
      expect(find.byKey(const Key('editor_next_sheet_btn')), findsOneWidget);
      expect(find.byKey(const Key('editor_continuation_colophon_header')), findsOneWidget);
      expect(find.text('《兰亭偶得》 · 第 2 页'), findsOneWidget);
      expect(find.byType(BoundedCinnabarSeal), findsNothing);

      await tester.tap(find.byKey(const Key('editor_next_sheet_btn')));
      await tester.pumpAndSettle();

      expect(find.text('第 3 / 3 页'), findsOneWidget);
      expect(find.byKey(const Key('editor_prev_sheet_btn')), findsOneWidget);
      expect(find.byKey(const Key('editor_next_sheet_btn')), findsNothing);
      expect(find.text('《兰亭偶得》 · 第 3 页'), findsOneWidget);
      expect(find.byType(BoundedCinnabarSeal), findsOneWidget, reason: 'Seal is present on final sheet');

      await tester.tap(find.byKey(const Key('editor_prev_sheet_btn')));
      await tester.pumpAndSettle();
      expect(find.text('第 2 / 3 页'), findsOneWidget);
    });

    testWidgets('final-sheet-only BoundedCinnabarSeal is strictly contained within innerFrameRect on 360px viewport', (tester) async {
      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'paginated_test_entry',
        viewportSize: const Size(360, 640),
      );

      final sealFinder = find.byType(BoundedCinnabarSeal);
      expect(sealFinder, findsOneWidget);

      final sealRect = tester.getRect(sealFinder);
      final canvasFinder = find.byType(TemplateCanvasContainer);
      final canvasOrigin = tester.getTopLeft(canvasFinder);
      final canvasMetrics = tester.widget<TemplateCanvasContainer>(canvasFinder).layoutMetrics!;
      final globalInnerFrameRect = canvasMetrics.innerFrameRect.shift(canvasOrigin);

      final isContained = PaperHeartMetrics.isContainedInside(
        innerFrameRect: globalInnerFrameRect,
        targetRect: sealRect,
      );
      expect(isContained, isTrue, reason: 'Seal must stay strictly inside Paper Heart innerFrameRect');

      final standardMetrics = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 360.0,
        canvasHeight: 640.0,
        backgroundType: TemplateBackgroundType.lined,
        horizontalMargin: 24.0,
        fontSize: 16.0,
        lineSpacing: 1.5,
      );
      expect(
        PaperHeartMetrics.isInsideDoubleOuterBorder(
          innerFrameRect: standardMetrics.innerFrameRect,
          targetRect: sealRect,
        ),
        isTrue,
      );
    });

    testWidgets('typing Auto-Spill advances PageView forward and deleting continuation text auto-collapses sheet', (tester) async {
      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'paginated_test_entry',
      );

      expect(find.text('第 1 / 1 页'), findsOneWidget);

      final quillEditorFinder = find.byType(QuillEditor);
      expect(quillEditorFinder, findsOneWidget);
      final quillEditor = tester.widget<QuillEditor>(quillEditorFinder);

      for (int lineIndex = 1; lineIndex <= 15; lineIndex++) {
        final currentLength = quillEditor.controller.document.length;
        quillEditor.controller.document.insert(
          currentLength - 1,
          '第${lineIndex.toString().padLeft(2, '0')}行测试自动溢行溢出长段落文字内容\n',
        );
      }
      await tester.pumpAndSettle();

      expect(find.text('第 2 / 2 页'), findsOneWidget);
      expect(find.byKey(const Key('editor_continuation_colophon_header')), findsOneWidget);

      // Delete all text on Sheet 2 WITHOUT pressing hardware Backspace: must auto-collapse cleanly!
      final secondSheetEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      secondSheetEditor.controller.document.delete(
        0,
        secondSheetEditor.controller.document.length - 1,
      );
      await tester.pumpAndSettle();

      expect(find.text('第 1 / 1 页'), findsOneWidget);
    });

    testWidgets('hardware Backspace at offset 0 on non-empty continuation sheet triggers Spill-Back', (tester) async {
      final delta = Delta();
      for (int lineIndex = 1; lineIndex <= 12; lineIndex++) {
        delta.insert('第${lineIndex.toString().padLeft(2, '0')}行墨迹\n');
      }
      await database.updateEntryContent(
        'paginated_test_entry',
        jsonEncode(delta.toJson()),
        '12 lines',
      );

      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'paginated_test_entry',
      );

      expect(find.text('第 1 / 2 页'), findsOneWidget);
      await tester.tap(find.byKey(const Key('editor_next_sheet_btn')));
      await tester.pumpAndSettle();
      expect(find.text('第 2 / 2 页'), findsOneWidget);

      final secondEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      secondEditor.focusNode.requestFocus();
      secondEditor.controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      expect(find.text('第 1 / 2 页'), findsOneWidget);
    });
  });
}
