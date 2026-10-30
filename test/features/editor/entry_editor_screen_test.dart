import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/dictation_service.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/editor/widgets/editor_toolbar.dart';
import 'package:memodiary/features/editor/widgets/entry_metadata_bar.dart';
import 'package:memodiary/features/editor/widgets/ghost_prompt_view.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/editor/widgets/thought_spark_banner.dart';
import 'package:memodiary/features/editor/widgets/writing_dock.dart';
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
    testWidgets('renders full-bleed journal sheet, letterhead, ghost prompt, and writing dock', (tester) async {
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
      expect(find.byType(GhostPromptView), findsOneWidget);
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

    testWidgets('using ghost prompt inserts it into editor and hides placeholder', (tester) async {
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

      // Tap '由此题落墨 · Adopt Prompt'
      expect(find.textContaining('由此题落墨'), findsOneWidget);
      await tester.tap(find.textContaining('由此题落墨'));
      await tester.pumpAndSettle();

      // Ghost prompt placeholder should vanish because editor now has text
      expect(find.textContaining('由此题落墨'), findsNothing);

      // Verify database gets updated with quoted prompt content
      final entry = await db.getEntryById('editor_test_entry');
      expect(entry!.plainText.contains('【灵感拾遗】'), isTrue);
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

      // Verify seal watermark is present
      expect(find.text('澄心\n寄墨'), findsOneWidget);
    });
  });
}
