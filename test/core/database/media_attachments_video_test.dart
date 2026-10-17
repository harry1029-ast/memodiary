import 'dart:convert';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('MediaAttachments Video Database Tests', () {
    test('records video attachment with relativePath and thumbnailPath and queries via getVideosForEntry', () async {
      final now = DateTime(2026, 10, 18);

      // 1. Create entry
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_with_video',
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('Day at the Beach'),
          contentDelta: jsonEncode([
            {'insert': 'Ocean waves video:\n'},
            {
              'insert': {'video': 'media/video_123.mp4'}
            },
          ]),
          plainText: 'Ocean waves video:',
          entryDate: now,
        ),
      );

      // 2. Attach video media
      await db.attachMediaToEntry(
        id: 'media_video_1',
        entryId: 'entry_with_video',
        relativePath: 'media/video_123.mp4',
        mediaType: 'video',
        thumbnailPath: 'media/video_123_thumb.webp',
      );

      // 3. Attach image media
      await db.attachMediaToEntry(
        id: 'media_photo_1',
        entryId: 'entry_with_video',
        relativePath: 'media/photo_123.webp',
        mediaType: 'image',
      );

      // 4. Test getVideosForEntry filters strictly videos
      final videos = await db.getVideosForEntry('entry_with_video');
      expect(videos.length, equals(1));
      expect(videos.first.id, equals('media_video_1'));
      expect(videos.first.mediaType, equals('video'));
      expect(videos.first.relativePath, equals('media/video_123.mp4'));
      expect(videos.first.thumbnailPath, equals('media/video_123_thumb.webp'));

      // 5. Test getAllMediaRelativePaths returns both video relativePath and thumbnailPath
      final allPaths = await db.getAllMediaRelativePaths();
      expect(allPaths.contains('media/video_123.mp4'), isTrue);
      expect(allPaths.contains('media/video_123_thumb.webp'), isTrue);
      expect(allPaths.contains('media/photo_123.webp'), isTrue);
    });
  });
}

