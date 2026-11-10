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
import 'package:memodiary/features/editor/widgets/desk_workstation/desk_space_budget.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import 'package:memodiary/features/editor/widgets/ghost_prompt_view.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/editor/widgets/thought_spark_banner.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../helpers/editor_test_harness.dart';

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('split_desk_centering_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);

    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: 'text_only_scholar_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('静夜沉思'),
            contentDelta: '[]',
            plainText: '',
            entryDate: DateTime(2026, 11, 4, 21, 0),
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

  group('Split Desk Architecture & Text-Only Scholar Centering (Ticket 01)', () {
    testWidgets('mounts permanent EditorPaperCanvas without prototype switcher or ghost prompts', (tester) async {
      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'text_only_scholar_entry',
        viewportSize: const Size(360.0, 780.0),
      );

      // Prototype switcher pill and prompt banners must be absent
      expect(find.byKey(const Key('prototype_variant_switcher')), findsNothing);
      expect(find.text('PROTOTYPE'), findsNothing);
      expect(find.byType(GhostPromptView), findsNothing);
      expect(find.byType(ThoughtSparkBanner), findsNothing);

      // Elevated EditorPaperCanvas is mounted
      expect(find.byType(EditorPaperCanvas), findsOneWidget);
      expect(find.byType(JournalLetterhead), findsOneWidget);
      expect(find.byType(QuillEditor), findsOneWidget);
    });

    testWidgets('text-only entry docks the 14-row card under the desk header band with Cinnabar Signature Seal resting cleanly beneath it', (tester) async {
      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'text_only_scholar_entry',
        viewportSize: const Size(360.0, 780.0),
      );

      final cardFinder = find.byType(TemplateCanvasContainer);
      expect(cardFinder, findsOneWidget);
      final cardRect = tester.getRect(cardFinder);

      // The card docks just beneath the header band holding the page indicator,
      // leaving the rest of the desk to the seal and the workstation.
      final canvasRect = tester.getRect(find.byType(EditorPaperCanvas));
      expect(
        cardRect.top - canvasRect.top,
        closeTo(DeskSpaceBudget.kHeaderHeight, 1.0),
        reason: 'Text-only stationery card should rest under the desk header band, with no dead desk above it',
      );

      // Diarist\'s Cinnabar Signature Seal rests cleanly beneath the card
      final sealFinder = find.byKey(const Key('cinnabar_signature_seal'));
      expect(sealFinder, findsOneWidget);
      final sealRect = tester.getRect(sealFinder);

      expect(
        sealRect.top,
        greaterThanOrEqualTo(cardRect.bottom),
        reason: 'Cinnabar Signature Seal must rest beneath the stationery card',
      );
      expect(
        sealRect.bottom,
        lessThanOrEqualTo(780.0),
        reason: 'Seal must not bleed outside canvas boundaries',
      );
    });

    testWidgets('multi-sheet navigation preserves vertical stability and renders seal on final sheet only', (tester) async {
      final multiSheetDelta = Delta();
      for (int lineIndex = 1; lineIndex <= 20; lineIndex++) {
        multiSheetDelta.insert('第${lineIndex.toString().padLeft(2, '0')}行砚池墨痕记录\n');
      }

      await database.updateEntryContent(
        'text_only_scholar_entry',
        jsonEncode(multiSheetDelta.toJson()),
        'Multi-sheet content',
      );

      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'text_only_scholar_entry',
        viewportSize: const Size(360.0, 780.0),
      );

      // Sheet 1 of 2: Seal must not be rendered
      expect(find.text('第 1 / 2 页'), findsOneWidget);
      final sheet1CardRect = tester.getRect(find.byType(TemplateCanvasContainer));
      expect(sheet1CardRect.top, greaterThan(40.0));
      expect(find.byKey(const Key('cinnabar_signature_seal')), findsNothing);

      // Navigate to Sheet 2 of 2 (final sheet)
      await tester.tap(find.byKey(const Key('editor_page_corner_next')));
      await tester.pumpAndSettle();

      expect(find.text('第 2 / 2 页'), findsOneWidget);
      final sheet2CardRect = tester.getRect(find.byType(TemplateCanvasContainer));

      // Card remains at the same vertical offset across sheets for smooth flipping
      expect(
        (sheet2CardRect.top - sheet1CardRect.top).abs(),
        lessThan(2.0),
        reason: 'Stationery card vertical position should remain stable across page turns',
      );

      // Final sheet renders seal beneath card
      final finalSealFinder = find.byKey(const Key('cinnabar_signature_seal'));
      expect(finalSealFinder, findsOneWidget);
      final finalSealRect = tester.getRect(finalSealFinder);
      expect(finalSealRect.top, greaterThanOrEqualTo(sheet2CardRect.bottom));
      expect(finalSealRect.bottom, lessThanOrEqualTo(780.0));
    });

    testWidgets('rapid text entry past row 14 triggers auto-spill without infinite loops or UI freeze', (tester) async {
      await pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: 'text_only_scholar_entry',
        viewportSize: const Size(360.0, 780.0),
      );

      expect(find.text('第 1 / 1 页'), findsOneWidget);
      final quillEditorFinder = find.byType(QuillEditor);
      final quillEditor = tester.widget<QuillEditor>(quillEditorFinder);

      // Insert 15 lines of text onto Sheet 1 (capacity is 10)
      for (int lineIndex = 1; lineIndex <= 15; lineIndex++) {
        // Typed at the end, so the caret follows the text as it spills.
        final currentLength = quillEditor.controller.document.length;
        final line = '行$lineIndex: 笔底波澜随文生\n';
        quillEditor.controller.replaceText(
          currentLength - 1,
          0,
          line,
          TextSelection.collapsed(offset: currentLength - 1 + line.length),
        );
      }
      await tester.pumpAndSettle();

      // Auto-spill advances to Sheet 2
      expect(find.text('第 2 / 2 页'), findsOneWidget);
      expect(find.byKey(const Key('editor_continuation_colophon_header')), findsOneWidget);
    });
  });
}
