import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/albums/screens/album_workspace_screen.dart';
import 'package:memodiary/features/search/screens/ocr_photo_viewer_screen.dart';
import 'package:memodiary/features/search/widgets/ocr_highlight_overlay.dart';
import 'package:memodiary/features/timeline/screens/entry_detail_screen.dart';

void main() {
  late Directory tempDir;
  late MediaSandboxService mediaService;
  late AppDatabase db;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ocr_photo_viewer_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  PhotoTextMatch createTestMatch({
    required String id,
    required String sourceType,
    required String parentId,
    required String relativePath,
    String? parentTitle,
  }) {
    return PhotoTextMatch(
      id: id,
      sourceType: sourceType,
      parentId: parentId,
      relativePath: relativePath,
      thumbnailPath: relativePath,
      ocrText: '西湖名胜古迹\n花港观鱼题字\n乾隆御笔',
      ocrBlocksJson:
          '[{"text":"西湖名胜古迹","box":[0.1,0.1,0.8,0.1]},{"text":"花港观鱼题字","box":[0.15,0.25,0.7,0.1]}]',
      parentTitle: parentTitle ?? '西湖游记',
      parentDate: DateTime(2026, 10, 25, 14, 0),
    );
  }

  group('OcrPhotoViewerScreen - Rendering & InteractiveViewer', () {
    testWidgets('renders InteractiveViewer with image and OcrHighlightOverlay', (tester) async {
      final sampleImage = File('${tempDir.path}/media/lake.webp');
      sampleImage.parent.createSync(recursive: true);
      sampleImage.writeAsBytesSync([1, 2, 3]);

      final match = createTestMatch(
        id: 'photo_lake',
        sourceType: PhotoTextMatch.sourceEntryMedia,
        parentId: 'entry_lake',
        relativePath: 'media/lake.webp',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: OcrPhotoViewerScreen(
            match: match,
            query: '花港观鱼',
            mediaSandboxService: mediaService,
            database: db,
            enableAnimation: false,
            imageSize: const Size(1200, 800),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(OcrHighlightOverlay), findsOneWidget);
      expect(find.byKey(const Key('search_ocr_highlight_toggle')), findsOneWidget);
      expect(find.byKey(const Key('search_ocr_viewer_view_parent_button')), findsOneWidget);
      expect(find.text('西湖游记'), findsWidgets);
    });

    testWidgets('handles missing or invalid image file gracefully', (tester) async {
      final match = createTestMatch(
        id: 'missing_photo',
        sourceType: PhotoTextMatch.sourceEntryMedia,
        parentId: 'entry_1',
        relativePath: 'media/non_existent.webp',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: OcrPhotoViewerScreen(
            match: match,
            query: '花港观鱼',
            mediaSandboxService: mediaService,
            database: db,
            enableAnimation: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('未能载入照片'), findsOneWidget);
    });
  });

  group('OcrPhotoViewerScreen - Toggle Highlight Button', () {
    testWidgets('toggles highlight overlay visibility and updates semantics label', (tester) async {
      final sampleImage = File('${tempDir.path}/media/lake.webp');
      sampleImage.parent.createSync(recursive: true);
      sampleImage.writeAsBytesSync([1, 2, 3]);

      final match = createTestMatch(
        id: 'photo_lake',
        sourceType: PhotoTextMatch.sourceEntryMedia,
        parentId: 'entry_lake',
        relativePath: 'media/lake.webp',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: OcrPhotoViewerScreen(
            match: match,
            query: '花港观鱼',
            mediaSandboxService: mediaService,
            database: db,
            enableAnimation: false,
            imageSize: const Size(1200, 800),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, highlights are visible: button shows "隐藏高亮"
      expect(find.text('隐藏高亮'), findsOneWidget);
      final overlayBefore = tester.widget<OcrHighlightOverlay>(find.byType(OcrHighlightOverlay));
      expect(overlayBefore.isVisible, isTrue);

      // Tap toggle button
      await tester.tap(find.byKey(const Key('search_ocr_highlight_toggle')));
      await tester.pumpAndSettle();

      // Button now shows "显示高亮" and overlay is hidden
      expect(find.text('显示高亮'), findsOneWidget);
      final overlayAfter = tester.widget<OcrHighlightOverlay>(find.byType(OcrHighlightOverlay));
      expect(overlayAfter.isVisible, isFalse);

      // Tap toggle button again to restore
      await tester.tap(find.byKey(const Key('search_ocr_highlight_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('隐藏高亮'), findsOneWidget);
      final overlayRestored = tester.widget<OcrHighlightOverlay>(find.byType(OcrHighlightOverlay));
      expect(overlayRestored.isVisible, isTrue);
    });
  });

  group('OcrPhotoViewerScreen - Parent Navigation', () {
    testWidgets('navigates to EntryDetailScreen when sourceType is entry_media', (tester) async {
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_123',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('秋日私语'),
          contentDelta: '[{"insert":"秋风起兮白云飞。\\n"}]',
          plainText: '秋风起兮白云飞。',
          entryDate: DateTime(2026, 10, 20),
        ),
      );

      final sampleImage = File('${tempDir.path}/media/entry_pic.webp');
      sampleImage.parent.createSync(recursive: true);
      sampleImage.writeAsBytesSync([1, 2, 3]);

      final match = createTestMatch(
        id: 'entry_photo_1',
        sourceType: PhotoTextMatch.sourceEntryMedia,
        parentId: 'entry_123',
        relativePath: 'media/entry_pic.webp',
        parentTitle: '秋日私语',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: OcrPhotoViewerScreen(
            match: match,
            query: '花港',
            mediaSandboxService: mediaService,
            database: db,
            enableAnimation: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('查看原日记'), findsOneWidget);

      await tester.tap(find.byKey(const Key('search_ocr_viewer_view_parent_button')));
      await tester.pumpAndSettle();

      expect(find.byType(EntryDetailScreen), findsOneWidget);
    });

    testWidgets('navigates to AlbumWorkspaceScreen when sourceType is album_photo', (tester) async {
      await db.into(db.albumCollections).insert(
        AlbumCollectionsCompanion.insert(
          id: 'collection_travel_2026',
          title: '江南之行',
          createdAt: Value(DateTime(2026, 10, 25)),
          updatedAt: Value(DateTime(2026, 10, 25)),
        ),
      );

      final sampleImage = File('${tempDir.path}/media/album_pic.webp');
      sampleImage.parent.createSync(recursive: true);
      sampleImage.writeAsBytesSync([1, 2, 3]);

      final match = createTestMatch(
        id: 'album_photo_1',
        sourceType: PhotoTextMatch.sourceAlbumPhoto,
        parentId: 'collection_travel_2026',
        relativePath: 'media/album_pic.webp',
        parentTitle: '江南之行',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: OcrPhotoViewerScreen(
            match: match,
            query: '花港',
            mediaSandboxService: mediaService,
            database: db,
            enableAnimation: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('查看相册'), findsOneWidget);

      await tester.tap(find.byKey(const Key('search_ocr_viewer_view_parent_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AlbumWorkspaceScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
