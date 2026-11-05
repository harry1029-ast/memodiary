import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/timeline/screens/entry_detail_screen.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_3d_stage.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_reading_perspective.dart';
import 'package:memodiary/features/timeline/widgets/folio/thread_bound_folio_screen.dart';

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

  group('EntryDetailScreen Thread-Bound Folio Overhaul Tests', () {
    testWidgets('renders entry inside ThreadBoundFolioScreen with frontispiece metadata and action dock', (WidgetTester tester) async {
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
        legacyMountsPending: false,
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

      // Verify Folio stage rendered
      expect(find.byType(ThreadBoundFolioScreen), findsOneWidget);
      expect(find.byType(Folio3DStage), findsOneWidget);

      // Verify Title & Frontispiece metadata
      expect(find.text('Reflections on Autumn'), findsAtLeastNWidgets(1));
      expect(find.text('周报 · 第42周'), findsOneWidget);
      expect(find.text('愉快'), findsOneWidget); // Mood 4

      // Verify Action Bar items exist (Reading Perspective, Share, Edit)
      expect(find.byKey(const Key('folio_reading_perspective_btn')), findsOneWidget);
      expect(find.text('忠实原貌'), findsOneWidget);
      expect(find.byKey(const Key('folio_share_btn')), findsOneWidget);
      expect(find.byKey(const Key('folio_edit_entry_btn')), findsOneWidget);
      expect(find.text('落墨修改'), findsOneWidget);
      expect(find.byKey(const Key('folio_page_indicator')), findsOneWidget);

      // Test Share Action Button
      await tester.tap(find.byKey(const Key('folio_share_btn')));
      await tester.pumpAndSettle();

      expect(sharedContent, isNotNull);
      expect(sharedContent, contains('Reflections on Autumn'));
      expect(sharedContent, contains('The leaves are falling gently today.'));
    });

    testWidgets('non-destructive Reading Perspective switching updates active layout', (WidgetTester tester) async {
      final now = DateTime(2026, 10, 16, 14, 30);

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'detail_entry_persp',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('山行即景'),
          contentDelta: jsonEncode([
            {'insert': '远上寒山石径斜，白云生处有人家。\n'}
          ]),
          plainText: '远上寒山石径斜，白云生处有人家。',
          entryDate: now,
          mood: const Value(3),
          weather: const Value('cloudy'),
        ),
      );
      final entry = (await db.getEntryById('detail_entry_persp'))!;

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

      // Open Perspective Sheet
      await tester.tap(find.byKey(const Key('folio_reading_perspective_btn')));
      await tester.pumpAndSettle();

      expect(find.text('展阅视角'), findsOneWidget);
      expect(find.text('朱丝古刻'), findsOneWidget);
      expect(find.text('原稿墨格'), findsOneWidget);
      expect(find.text('松烟夜卷'), findsOneWidget);

      // Select '朱丝古刻'
      await tester.tap(find.byKey(Key('folio_perspective_option_${ReadingPerspective.vermilionVertical.name}')));
      await tester.pumpAndSettle();

      // Perspective button now displays '朱丝古刻'
      expect(find.text('朱丝古刻'), findsOneWidget);

      // Verify SQLite entry record template is completely untouched
      final dbEntry = await db.getEntryById('detail_entry_persp');
      expect(dbEntry?.templateId, equals('template_minimalist_white'));
    });

    testWidgets('soft delete via consolidated More menu triggers confirmation dialog', (WidgetTester tester) async {
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

      // Open More Menu
      await tester.tap(find.byKey(const Key('folio_more_menu_btn')));
      await tester.pumpAndSettle();

      // Tap soft delete menu item
      await tester.tap(find.byKey(const Key('folio_menu_delete_entry')));
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

    testWidgets('loads asynchronously when initialized via entryId with clean spinner', (tester) async {
      final now = DateTime(2026, 10, 20);
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'async_loaded_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('异步载入手札'),
          contentDelta: jsonEncode([{'insert': '异步内容\n'}]),
          plainText: '异步内容',
          entryDate: now,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EntryDetailScreen(
            entryId: 'async_loaded_entry',
            database: db,
            mediaService: mediaService,
          ),
        ),
      );

      // Verify progress indicator is rendered initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify loaded title and content
      expect(find.text('异步载入手札'), findsAtLeastNWidgets(1));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('tapping page indicator opens FolioPageJumpSheet and jumps to selected page', (tester) async {
      final now = DateTime(2026, 10, 20);
      final longText = List.generate(40, (i) => '这是第$i行长文本，用于产生多页手稿。').join('\n');
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'multipage_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('多页长篇手札'),
          contentDelta: jsonEncode([{'insert': '$longText\n'}]),
          plainText: longText,
          entryDate: now,
        ),
      );

      final entry = (await db.getEntryById('multipage_entry'))!;

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

      // Verify page indicator and prev/next navigation buttons
      expect(find.byKey(const Key('folio_page_indicator')), findsOneWidget);
      expect(find.byKey(const Key('folio_prev_page_btn')), findsOneWidget);
      expect(find.byKey(const Key('folio_next_page_btn')), findsOneWidget);

      // Tap next page button
      await tester.tap(find.byKey(const Key('folio_next_page_btn')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('folio_page_indicator')),
          matching: find.textContaining('第 2 /'),
        ),
        findsOneWidget,
      );

      // Tap page indicator to open FolioPageJumpSheet
      await tester.tap(find.byKey(const Key('folio_page_indicator')));
      await tester.pumpAndSettle();

      expect(find.text('展卷索引 · 翻转至特定页'), findsOneWidget);
      expect(find.byKey(const Key('folio_jump_page_tile_0')), findsOneWidget);

      // Tap first page tile to jump back to frontispiece
      await tester.tap(find.byKey(const Key('folio_jump_page_tile_0')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('folio_page_indicator')),
          matching: find.textContaining('第 1 /'),
        ),
        findsOneWidget,
      );
    });
  });
}
