import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/dictation_service.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/editor/widgets/keepsake_scroll_view.dart';
import 'package:memodiary/features/editor/widgets/editor_quill_styles_builder.dart';
import 'package:memodiary/features/editor/widgets/editor_toolbar.dart';
import 'package:memodiary/features/editor/widgets/entry_metadata_bar.dart';
import 'package:memodiary/features/editor/widgets/ghost_prompt_view.dart';
import 'package:memodiary/features/editor/widgets/integer_snapped_letterhead.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/editor/widgets/thought_spark_banner.dart';
import 'package:memodiary/features/editor/widgets/writing_dock.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/services/stationery_layout_calculator.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../helpers/fake_speech_to_text.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService sandboxService;
  late FakeSpeechToText fakeSpeech;
  late DictationService dictationService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('editor_screen_test_');
    sandboxService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
      compressor: (sourcePath, targetPath, {minWidth = 1600, minHeight = 1600, quality = 80}) async {
        final src = File(sourcePath);
        return src.copy(targetPath);
      },
    );

    fakeSpeech = FakeSpeechToText();
    dictationService = DictationService(speech: fakeSpeech);

    // Insert test entry
    await db.into(db.entries).insert(
          EntriesCompanion.insert(
            id: 'editor_test_entry',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Test Diary Title'),
            contentDelta: '[]',
            plainText: '',
            entryDate: DateTime(2026, 10, 16, 12, 0),
            mood: const Value(4),
            weather: const Value('sunny'),
          ),
        );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('EntryEditorScreen Widget Tests', () {
    testWidgets('renders full-bleed journal sheet, letterhead, and writing dock without inline ghost prompt', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: sandboxService,
            entryId: 'editor_test_entry',
            dictationService: dictationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify new architecture widgets are rendered
      expect(find.byType(JournalLetterhead), findsOneWidget);
      expect(find.byType(GhostPromptView), findsNothing, reason: 'Inline ghost prompt should be removed from canvas');
      expect(find.byType(QuillEditor), findsOneWidget);
      expect(find.byType(WritingDock), findsOneWidget);

      // Verify old cluttered components are completely retired
      expect(find.byType(EntryMetadataBar), findsNothing);
      expect(find.byType(ThoughtSparkBanner), findsNothing);
      expect(find.byType(EditorToolbar), findsNothing);

      // Verify status and title
      expect(find.text('已保存'), findsOneWidget);
      expect(find.text('Test Diary Title'), findsOneWidget);
      expect(find.byKey(const Key('editor_seal_done_btn')), findsOneWidget);
      expect(find.byKey(const Key('top_bar_scholar_chest_button')), findsOneWidget);
    });

    testWidgets('tapping sparkle button in WritingDock displays thought spark SnackBar and adopts it into editor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: sandboxService,
            entryId: 'editor_test_entry',
            dictationService: dictationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap sparkle tool in WritingDock
      expect(find.byKey(const Key('writing_dock_spark_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('writing_dock_spark_btn')));
      await tester.pumpAndSettle();

      // Verify SnackBar with '由此题落墨' appears
      expect(find.textContaining('由此题落墨'), findsOneWidget);
      await tester.tap(find.textContaining('由此题落墨'));
      await tester.pumpAndSettle();

      // Verify database gets updated with quoted prompt content
      final entry = await db.getEntryById('editor_test_entry');
      expect(entry!.plainText.contains('【灵感拾遗】'), isTrue);
    });

    testWidgets('synchronizes typography from template on load and template switch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: sandboxService,
            entryId: 'editor_test_entry',
            dictationService: dictationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify TemplateCanvasContainer receives typography synchronized with initial template
      final initialContainer = tester.widget<TemplateCanvasContainer>(
        find.byType(TemplateCanvasContainer),
      );
      expect(initialContainer.typography, isNotNull);
      expect(initialContainer.typography!.lineSpacing, 1.5);

      // Switch to Lined Paper via Scholar's Stationery Chest
      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.tap(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.pumpAndSettle();

      // Dismiss drawer to inspect updated container
      await tester.tap(find.byKey(const Key('chest_dismiss_handle')));
      await tester.pumpAndSettle();

      final updatedContainer = tester.widget<TemplateCanvasContainer>(
        find.byType(TemplateCanvasContainer),
      );
      expect(updatedContainer.style.type, TemplateBackgroundType.lined);
      expect(updatedContainer.typography!.lineSpacing, updatedContainer.style.lineSpacing);
    });

    testWidgets('synchronizes editor horizontal margins directly to innerFrameRect and clamps letterhead height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: sandboxService,
            entryId: 'editor_test_entry',
            dictationService: dictationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify IntegerSnappedLetterhead height on canvas is an integer multiple of lineStridePx
      final letterheadFinder = find.byType(IntegerSnappedLetterhead);
      expect(letterheadFinder, findsOneWidget);
      final letterheadWidget = tester.widget<IntegerSnappedLetterhead>(letterheadFinder);
      final letterheadSize = tester.getSize(letterheadFinder);
      expect(letterheadSize.height % letterheadWidget.lineStridePx, equals(0.0));

      final canvasContainer = tester.widget<TemplateCanvasContainer>(
        find.byType(TemplateCanvasContainer),
      );
      expect(canvasContainer.headerHeight, equals(letterheadSize.height));

      // 2. Switch to Lined Paper
      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.tap(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.pumpAndSettle();

      // Dismiss drawer to inspect padding
      await tester.tap(find.byKey(const Key('chest_dismiss_handle')));
      await tester.pumpAndSettle();

      // Find the Padding widget wrapping QuillEditor
      final linedPaddingWidget = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(QuillEditor),
          matching: find.byType(Padding),
        ).first,
      );
      final linedPadding = linedPaddingWidget.padding as EdgeInsets;

      // Verify horizontal padding on lined paper includes inner breathing room beyond margin line
      final linedMetrics = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 800.0,
        canvasHeight: 600.0,
        backgroundType: TemplateBackgroundType.lined,
        horizontalMargin: 24.0,
        fontSize: 16.0,
        lineSpacing: 1.5,
      );
      expect(linedPadding.left, equals(linedMetrics.innerFrameRect.left + 32.0));
      expect(linedPadding.right, equals(800.0 - linedMetrics.innerFrameRect.right + 20.0));

      // 3. Switch to Grid Paper (named 'Weekly Review' in defaults)
      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('chest_template_chip_template_weekly_review')));
      await tester.tap(find.byKey(const Key('chest_template_chip_template_weekly_review')));
      await tester.pumpAndSettle();

      // Dismiss drawer to inspect padding
      await tester.tap(find.byKey(const Key('chest_dismiss_handle')));
      await tester.pumpAndSettle();

      final gridPaddingWidget = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(QuillEditor),
          matching: find.byType(Padding),
        ).first,
      );
      final gridPadding = gridPaddingWidget.padding as EdgeInsets;

      final gridMetrics = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 800.0,
        canvasHeight: 600.0,
        backgroundType: TemplateBackgroundType.grid,
        horizontalMargin: 16.0,
        fontSize: 16.0,
        lineSpacing: 1.5,
      );
      expect(gridPadding.left, equals(gridMetrics.innerFrameRect.left));
      expect(gridPadding.right, equals(800.0 - gridMetrics.innerFrameRect.right));
    });

    testWidgets('enforces StrutStyle forceStrutHeight on editor styles and toggles grid letterSpacing cleanly without mutating delta', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: sandboxService,
            entryId: 'editor_test_entry',
            dictationService: dictationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify StrutStyle on editor styles
      final strutStyle = EditorQuillStylesBuilder.buildStrutStyle(
        fontSize: 16.0,
        lineStridePx: 24.0,
      );
      expect(strutStyle.forceStrutHeight, isTrue);

      final initialEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      final initialParagraphStyle = initialEditor.config.customStyles!.paragraph!.style;
      expect(initialParagraphStyle.height, equals(24.0 / 16.0));

      // Switch to Grid template
      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('chest_template_chip_template_weekly_review')));
      await tester.tap(find.byKey(const Key('chest_template_chip_template_weekly_review')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chest_dismiss_handle')));
      await tester.pumpAndSettle();

      final gridEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      final gridParagraphStyle = gridEditor.config.customStyles!.paragraph!.style;
      // letterSpacing = lineStridePx - fontSize = 24.0 - 16.0 = 8.0
      expect(gridParagraphStyle.letterSpacing, equals(8.0));

      // Switch back to Lined template
      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.tap(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chest_dismiss_handle')));
      await tester.pumpAndSettle();

      final linedEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      final linedParagraphStyle = linedEditor.config.customStyles!.paragraph!.style;
      // letterSpacing restores to 0.0
      expect(linedParagraphStyle.letterSpacing, equals(0.0));

      // Verify database contentDelta remains byte-for-byte identical
      final entry = await db.getEntryById('editor_test_entry');
      expect(entry!.contentDelta, equals('[]'));
    });

    testWidgets('opening template switcher and typography sheets from scholar chest', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: sandboxService,
            entryId: 'editor_test_entry',
            dictationService: dictationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Scholar's Stationery Chest
      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      await tester.pumpAndSettle();

      // Select Lined Paper
      expect(find.byKey(const Key('chest_template_chip_template_lined_paper')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.tap(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.pumpAndSettle();

      // Verify template changed in database
      final entry = await db.getEntryById('editor_test_entry');
      expect(entry!.templateId, 'template_lined_paper');

      // Switch artifact to Brush Mountain for Typography without having to leave the chest
      await tester.ensureVisible(find.byKey(const Key('chest_artifact_brush_mountain')));
      await tester.tap(find.byKey(const Key('chest_artifact_brush_mountain')));
      await tester.pumpAndSettle();

      expect(find.text('字法墨韵 · 笔意规制'), findsOneWidget);
      expect(find.textContaining('字形大小'), findsOneWidget);
      expect(find.textContaining('行间高距'), findsOneWidget);
      expect(find.text('墨色韵调'), findsOneWidget);
    });

    testWidgets('renders cleanly in dark mode without canvas collapse', (tester) async {
      // A phone-shaped desk, tall enough for the seal beneath the sheet.
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.dark,
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: sandboxService,
            entryId: 'editor_test_entry',
            dictationService: dictationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify canvas container fills the screen vertically
      final canvasFinder = find.byType(Positioned);
      expect(canvasFinder, findsWidgets);

      // Verify no old ThoughtSparkBanner is present
      expect(find.byType(ThoughtSparkBanner), findsNothing);

      // Verify Cinnabar Signature Seal is present
      expect(find.byKey(const Key('cinnabar_signature_seal')), findsOneWidget);
      expect(find.text('心'), findsOneWidget);
      expect(find.text('放'), findsOneWidget);
    });

    testWidgets('tapping top_bar_keepsake_scroll_button opens KeepsakeScrollView without mutating delta', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: sandboxService,
            entryId: 'editor_test_entry',
            dictationService: dictationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final keepsakeBtn = find.byKey(const Key('top_bar_keepsake_scroll_button'));
      expect(keepsakeBtn, findsOneWidget);

      await tester.tap(keepsakeBtn);
      await tester.pumpAndSettle();

      expect(find.byType(KeepsakeScrollView), findsOneWidget);
      expect(find.textContaining('卷轴赏鉴'), findsOneWidget);

      // Verify close button dismisses KeepsakeScrollView
      await tester.tap(find.byKey(const Key('keepsake_close_button')));
      await tester.pumpAndSettle();

      expect(find.byType(KeepsakeScrollView), findsNothing);

      // Verify database delta is untouched
      final entry = await db.getEntryById('editor_test_entry');
      expect(entry!.contentDelta, equals('[]'));
    });
  });
}
