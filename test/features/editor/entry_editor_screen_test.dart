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
import 'package:memodiary/features/editor/widgets/editor_toolbar.dart';
import 'package:memodiary/features/editor/widgets/entry_metadata_bar.dart';
import 'package:memodiary/features/editor/widgets/ghost_prompt_view.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/editor/widgets/thought_spark_banner.dart';
import 'package:memodiary/features/editor/widgets/writing_dock.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../core/services/dictation_service_test.dart';

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
      expect(find.byKey(const Key('editor_more_options_btn')), findsOneWidget);
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

      // Switch to Lined Paper via menu
      await tester.tap(find.byKey(const Key('editor_more_options_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('更换素笺模板'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lined Paper'));
      await tester.pumpAndSettle();

      final updatedContainer = tester.widget<TemplateCanvasContainer>(
        find.byType(TemplateCanvasContainer),
      );
      expect(updatedContainer.style.type, TemplateBackgroundType.lined);
      expect(updatedContainer.typography!.lineSpacing, updatedContainer.style.lineSpacing);
    });

    testWidgets('applies contextual left padding: marginX + 12 on lined paper and marginX on grid paper', (tester) async {
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

      // Switch to Lined Paper
      await tester.tap(find.byKey(const Key('editor_more_options_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('更换素笺模板'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lined Paper'));
      await tester.pumpAndSettle();

      // Find the Padding widget wrapping QuillEditor
      final linedPaddingWidget = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(QuillEditor),
          matching: find.byType(Padding),
        ).first,
      );
      final linedPadding = linedPaddingWidget.padding as EdgeInsets;
      // Lined paper should have marginX (24.0) + 12.0 = 36.0
      expect(linedPadding.left, equals(36.0));

      // Switch to Grid Paper (named 'Weekly Review' in defaults)
      await tester.tap(find.byKey(const Key('editor_more_options_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('更换素笺模板'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekly Review'));
      await tester.pumpAndSettle();

      final gridPaddingWidget = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(QuillEditor),
          matching: find.byType(Padding),
        ).first,
      );
      final gridPadding = gridPaddingWidget.padding as EdgeInsets;
      // Grid paper should be exactly marginX (16.0) without the +12 gutter
      expect(gridPadding.left, equals(16.0));
    });

    testWidgets('opening template switcher and typography sheets from options menu', (tester) async {
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

      // Open options menu in AppBar
      await tester.tap(find.byKey(const Key('editor_more_options_btn')));
      await tester.pumpAndSettle();

      // Select Templates
      expect(find.textContaining('更换素笺模板'), findsOneWidget);
      await tester.tap(find.textContaining('更换素笺模板'));
      await tester.pumpAndSettle();

      expect(find.text('Switch Template'), findsOneWidget);
      // Select Lined Paper
      await tester.tap(find.text('Lined Paper'));
      await tester.pumpAndSettle();

      // Verify template changed in database
      final entry = await db.getEntryById('editor_test_entry');
      expect(entry!.templateId, 'template_lined_paper');

      // Re-open options menu for Typography
      await tester.tap(find.byKey(const Key('editor_more_options_btn')));
      await tester.pumpAndSettle();

      expect(find.textContaining('字法排印'), findsOneWidget);
      await tester.tap(find.textContaining('字法排印'));
      await tester.pumpAndSettle();

      expect(find.text('Typography Settings'), findsOneWidget);
      expect(find.text('Font Family'), findsOneWidget);
      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Line Spacing'), findsOneWidget);
    });

    testWidgets('renders cleanly in dark mode without canvas collapse', (tester) async {
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
