import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import 'package:memodiary/features/timeline/screens/entry_detail_screen.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;

  setUp(() {
    db = AppDatabase.memory();
    mediaService = MediaSandboxService();
  });

  tearDown(() async {
    await db.close();
  });

  group('EntryDetailScreen Widget Tests', () {
    testWidgets('renders entry inside template with metadata, title, and action buttons', (WidgetTester tester) async {
      final now = DateTime(2026, 10, 16, 14, 30);

      final entry = Entry(
        id: 'detail_entry_1',
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: 'Reflections on Autumn',
        contentDelta: jsonEncode([
          {'insert': 'The leaves are falling gently today.\n'}
        ]),
        plainText: 'The leaves are falling gently today.',
        entryDate: now,
        mood: 4,
        weather: 'sunny',
        isWeeklyReview: true,
        weekNumber: 42,
        createdAt: now,
        updatedAt: now,
        isLocked: false,
        isDeleted: false,
      );

      String? sharedContent;

      await tester.pumpWidget(
        MaterialApp(
          home: EntryDetailScreen(
            entry: entry,
            database: db,
            mediaService: mediaService,
            shareHandler: (text, {subject}) async {
              sharedContent = text;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Title & Metadata badges
      expect(find.text('Reflections on Autumn'), findsOneWidget);
      expect(find.text('W42 Review'), findsOneWidget);
      expect(find.text('🙂'), findsOneWidget); // Mood 4 emoji
      expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget); // Weather sunny

      // Verify Template and Rich-text editor are rendered
      expect(find.byType(TemplateCanvasContainer), findsOneWidget);
      expect(find.byType(quill.QuillEditor), findsOneWidget);

      // Verify Action Bar buttons exist
      expect(find.text('Template'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Edit Entry'), findsOneWidget);

      // Test Share Action Button
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      expect(sharedContent, isNotNull);
      expect(sharedContent, contains('Reflections on Autumn'));
      expect(sharedContent, contains('The leaves are falling gently today.'));
    });

    testWidgets('soft delete button triggers confirmation dialog', (WidgetTester tester) async {
      final now = DateTime.now();

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_to_soft_delete',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Will be deleted'),
          contentDelta: jsonEncode([{'insert': 'Goodbye\n'}]),
          plainText: 'Goodbye',
          entryDate: now,
        ),
      );

      final entry = (await db.getEntryById('entry_to_soft_delete'))!;

      await tester.pumpWidget(
        MaterialApp(
          home: EntryDetailScreen(
            entry: entry,
            database: db,
            mediaService: mediaService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap AppBar delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Move to Recycle Bin?'), findsOneWidget);
      expect(find.text('Move to Bin'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.text('Move to Bin'));
      await tester.pumpAndSettle();

      // Entry should now be soft deleted in the database
      final updated = await db.getEntryById('entry_to_soft_delete');
      expect(updated!.isDeleted, isTrue);
    });
  });
}
