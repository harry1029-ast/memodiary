import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/ocr/ocr_queue_manager.dart';
import 'package:memodiary/features/search/screens/ocr_photo_viewer_screen.dart';
import 'package:memodiary/features/search/screens/search_screen.dart';
import 'package:memodiary/features/search/widgets/photo_text_match_card.dart';
import '../../helpers/fake_ocr_service.dart';

void main() {
  late Directory tempDir;
  late MediaSandboxService mediaService;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('memodiary_ocr_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('PhotoTextMatchCard', () {
    testWidgets('renders badge, parent title, date, and highlighted snippet',
        (tester) async {
      // Create a dummy image file in temp directory
      final imageFile = File('${tempDir.path}/media/sample.webp');
      imageFile.parent.createSync(recursive: true);
      imageFile.writeAsBytesSync([0x00, 0x01, 0x02]);

      final match = PhotoTextMatch(
        id: 'photo_match_1',
        sourceType: PhotoTextMatch.sourceEntryMedia,
        parentId: 'entry_1',
        relativePath: 'media/sample.webp',
        thumbnailPath: 'media/sample.webp',
        ocrText: '西湖十景之一\n花港观鱼石碑题字\n乾隆御笔',
        parentTitle: '游西湖记',
        parentDate: DateTime(2026, 10, 15, 14, 30),
      );

      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: PhotoTextMatchCard(
              match: match,
              mediaService: mediaService,
              query: '花港观鱼',
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify card key
      expect(find.byKey(const Key('search_photo_match_card_photo_match_1')), findsOneWidget);

      // Verify "图中文字匹配" badge
      expect(find.text('图中文字匹配'), findsOneWidget);

      // Verify parent title
      expect(find.text('游西湖记'), findsOneWidget);

      // Verify date formatting
      expect(find.textContaining('2026年10月15日'), findsOneWidget);

      // Verify RichText containing highlighted snippet
      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsWidgets);

      // Find the RichText for snippet
      bool foundHighlightedSpan = false;
      for (final richTextWidget in tester.widgetList<RichText>(richTextFinder)) {
        final textSpan = richTextWidget.text;
        if (textSpan is TextSpan) {
          textSpan.visitChildren((inlineSpan) {
            if (inlineSpan is TextSpan && inlineSpan.text == '花港观鱼') {
              if (inlineSpan.style?.color != null &&
                  inlineSpan.style?.fontWeight == FontWeight.bold) {
                foundHighlightedSpan = true;
              }
            }
            return true;
          });
        }
      }
      expect(foundHighlightedSpan, isTrue, reason: 'Expected "花港观鱼" to be styled bold with cinnabar');

      // Tap card
      await tester.tap(find.byKey(const Key('search_photo_match_card_photo_match_1')));
      expect(wasTapped, isTrue);
    });
  });

  group('SearchScreen OCR Integration', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();

      // Seed an entry with matching text
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_coffee',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('午后咖啡'),
          contentDelta: '[{"insert":"今天在咖啡馆读书。\\n"}]',
          plainText: '今天在咖啡馆读书。',
          entryDate: DateTime(2026, 10, 20, 15, 0),
        ),
      );

      // Seed an entry with an image attachment having OCR text
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_travel',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('旅行游记'),
          contentDelta: '[{"insert":"杭州游记。\\n"}]',
          plainText: '杭州游记。',
          entryDate: DateTime(2026, 10, 21, 10, 0),
        ),
      );

      // Create dummy image file
      final mediaFile = File('${tempDir.path}/media/signboard.webp');
      mediaFile.parent.createSync(recursive: true);
      mediaFile.writeAsBytesSync([1, 2, 3]);

      await db.into(db.mediaAttachments).insert(
            MediaAttachmentsCompanion.insert(
              id: 'media_signboard',
              entryId: 'entry_travel',
              mediaType: 'image',
              relativePath: 'media/signboard.webp',
              thumbnailPath: const Value('media/signboard.webp'),
              ocrText: const Value('西湖名胜古迹\n星巴克咖啡厅题字'),
              ocrBlocksJson: const Value('[]'),
              createdAt: Value(DateTime(2026, 10, 21, 10, 0)),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders segmented filter bar with All, Entries, Photos chips',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: SearchScreen(
            database: db,
            mediaService: mediaService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('search_segment_all')), findsOneWidget);
      expect(find.byKey(const Key('search_segment_entries')), findsOneWidget);
      expect(find.byKey(const Key('search_segment_photos')), findsOneWidget);
    });

    testWidgets(
        'executes concurrent query across entries and photo text, displaying both under 全部',
        (tester) async {
      PhotoTextMatch? tappedMatch;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: SearchScreen(
            database: db,
            mediaService: mediaService,
            onPhotoMatchTap: (match) {
              tappedMatch = match;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search for "咖啡"
      await tester.enterText(find.byKey(const Key('search_text_field')), '咖啡');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // In "全部" segment: both entry card and photo text match card appear
      expect(find.text('午后咖啡'), findsOneWidget); // Entry title
      expect(find.byKey(const Key('search_photo_match_card_media_signboard')), findsOneWidget);
      expect(find.text('图中文字匹配'), findsOneWidget);

      // Tap on photo match card
      await tester.tap(find.byKey(const Key('search_photo_match_card_media_signboard')));
      expect(tappedMatch, isNotNull);
      expect(tappedMatch!.id, 'media_signboard');
    });

    testWidgets(
        'segment switching: 日记 shows only entries, 图中文字 shows only photo matches',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: SearchScreen(
            database: db,
            mediaService: mediaService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('search_text_field')), '咖啡');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // 1. Switch to "日记"
      await tester.tap(find.byKey(const Key('search_segment_entries')));
      await tester.pumpAndSettle();

      expect(find.text('午后咖啡'), findsOneWidget);
      expect(find.byKey(const Key('search_photo_match_card_media_signboard')), findsNothing);

      // 2. Switch to "图中文字"
      await tester.tap(find.byKey(const Key('search_segment_photos')));
      await tester.pumpAndSettle();

      expect(find.text('午后咖啡'), findsNothing);
      expect(find.byKey(const Key('search_photo_match_card_media_signboard')), findsOneWidget);

      // 3. Switch back to "全部"
      await tester.tap(find.byKey(const Key('search_segment_all')));
      await tester.pumpAndSettle();

      expect(find.text('午后咖啡'), findsOneWidget);
      expect(find.byKey(const Key('search_photo_match_card_media_signboard')), findsOneWidget);
    });

    testWidgets(
        'tapping photo match card navigates to OcrPhotoViewerScreen when onPhotoMatchTap is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: SearchScreen(
            database: db,
            mediaService: mediaService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('search_text_field')), '咖啡');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('search_photo_match_card_media_signboard')), findsOneWidget);

      await tester.tap(find.byKey(const Key('search_photo_match_card_media_signboard')));
      await tester.pumpAndSettle();

      expect(find.byType(OcrPhotoViewerScreen), findsOneWidget);
    });

    testWidgets(
        'empty search state under 图中文字 shows poetic ink prompt when no photos match',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: SearchScreen(
            database: db,
            mediaService: mediaService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Query that matches entry only, not photo OCR
      await tester.enterText(find.byKey(const Key('search_text_field')), '读书');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Switch to "图中文字"
      await tester.tap(find.byKey(const Key('search_segment_photos')));
      await tester.pumpAndSettle();

      expect(find.text('图中文字杳然 · 暂无匹配照片'), findsOneWidget);
    });

    testWidgets(
        'displays backfill banner when ocrQueueManager != null and pendingBackfillCount > 0',
        (tester) async {
      // Add an unindexed photo so count > 0
      await db.into(db.mediaAttachments).insert(
            MediaAttachmentsCompanion.insert(
              id: 'unindexed_media',
              entryId: 'entry_travel',
              mediaType: 'image',
              relativePath: 'media/unindexed.webp',
              createdAt: Value(DateTime(2026, 10, 22, 10, 0)),
            ),
          );

      final fakeOcr = FakeOcrService();
      final queueManager = OcrQueueManager(
        database: db,
        mediaSandboxService: mediaService,
        ocrService: fakeOcr,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: SearchScreen(
            database: db,
            mediaService: mediaService,
            ocrQueueManager: queueManager,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('search_ocr_backfill_banner')), findsOneWidget);
      expect(find.textContaining('尚未建立文字索引'), findsOneWidget);

      await queueManager.dispose();
    });

    testWidgets(
        'natural language query extracts keywords and forwards effective keyword to photo match card and viewer',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: SearchScreen(
            database: db,
            mediaService: mediaService,
            referenceNow: DateTime(2026, 10, 25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search "10月咖啡" (parsed keywords should be "咖啡")
      await tester.enterText(find.byKey(const Key('search_text_field')), '10月咖啡');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Card found
      final cardFinder = find.byKey(const Key('search_photo_match_card_media_signboard'));
      expect(cardFinder, findsOneWidget);

      final cardWidget = tester.widget<PhotoTextMatchCard>(find.byType(PhotoTextMatchCard));
      expect(cardWidget.query, '咖啡');

      // Tapping card navigates to viewer with effective query
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      final viewerFinder = find.byType(OcrPhotoViewerScreen);
      expect(viewerFinder, findsOneWidget);
      final viewerWidget = tester.widget<OcrPhotoViewerScreen>(viewerFinder);
      expect(viewerWidget.query, '咖啡');
    });
  });
}
