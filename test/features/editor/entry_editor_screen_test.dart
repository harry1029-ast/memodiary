import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/dictation_service.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/editor/widgets/editor_toolbar.dart';
import 'package:memodiary/features/editor/widgets/entry_metadata_bar.dart';
import 'package:memodiary/features/editor/widgets/thought_spark_banner.dart';
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
    testWidgets('renders all editor components and metadata bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: sandboxService,
            entryId: 'editor_test_entry',
            dictationService: dictationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header, metadata, banner, editor, and toolbar are rendered
      expect(find.byType(EntryMetadataBar), findsOneWidget);
      expect(find.byType(ThoughtSparkBanner), findsOneWidget);
      expect(find.byType(QuillEditor), findsOneWidget);
      expect(find.byType(EditorToolbar), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('2026-10-16 12:00'), findsOneWidget);
    });

    testWidgets('using thought spark prompt inserts it and hides banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: sandboxService,
            entryId: 'editor_test_entry',
            dictationService: dictationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Use Prompt'
      expect(find.text('Use Prompt'), findsOneWidget);
      await tester.tap(find.text('Use Prompt'));
      await tester.pumpAndSettle();

      // Banner should be hidden
      expect(find.byType(ThoughtSparkBanner), findsNothing);

      // Verify database gets updated with prompt content
      final entry = await db.getEntryById('editor_test_entry');
      expect(entry!.plainText.isNotEmpty, isTrue);
    });

    testWidgets('opening template switcher and typography sheets from toolbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: sandboxService,
            entryId: 'editor_test_entry',
            dictationService: dictationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap template button in AppBar
      await tester.tap(find.byTooltip('Switch Template'));
      await tester.pumpAndSettle();

      expect(find.text('Switch Template'), findsOneWidget);
      // Close sheet
      await tester.tap(find.text('Lined Paper'));
      await tester.pumpAndSettle();

      // Verify template changed in database
      final entry = await db.getEntryById('editor_test_entry');
      expect(entry!.templateId, 'template_lined_paper');

      // Tap typography in AppBar
      await tester.tap(find.byTooltip('Typography').first);
      await tester.pumpAndSettle();

      expect(find.text('Typography Settings'), findsOneWidget);
      expect(find.text('Font Family'), findsOneWidget);
      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Line Spacing'), findsOneWidget);
    });
  });
}
