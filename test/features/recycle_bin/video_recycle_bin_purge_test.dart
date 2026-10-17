import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/recycle_bin_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;

  setUp(() async {
    db = AppDatabase.memory();
    tempDir = await Directory.systemTemp.createTemp('video_recycle_bin_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Video Recycle Bin Tests', () {
    test('permanentDeleteEntry removes physical .mp4 and companion _thumb.webp files', () async {
      final mediaDir = Directory(p.join(tempDir.path, 'media'))..createSync(recursive: true);

      // 1. Create entry
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'video_entry_delete',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Memory with Video'),
          contentDelta: jsonEncode([{'insert': 'A video memory\n'}]),
          plainText: 'A video memory',
          entryDate: DateTime.now(),
        ),
      );

      // 2. Create physical video and thumbnail files
      final videoFile = File(p.join(mediaDir.path, 'family_clip.mp4'))..writeAsBytesSync([1, 2, 3]);
      final thumbFile = File(p.join(mediaDir.path, 'family_clip_thumb.webp'))..writeAsBytesSync([4, 5]);

      await db.attachMediaToEntry(
        id: 'media_family_clip',
        entryId: 'video_entry_delete',
        relativePath: 'media/family_clip.mp4',
        thumbnailPath: 'media/family_clip_thumb.webp',
        mediaType: 'video',
      );

      expect(videoFile.existsSync(), isTrue);
      expect(thumbFile.existsSync(), isTrue);

      // 3. Soft delete first
      await db.softDeleteEntry('video_entry_delete');
      expect((await db.getDeletedEntries()).length, 1);

      // 4. Permanently delete entry
      await RecycleBinService.permanentDeleteEntry(
        entryId: 'video_entry_delete',
        database: db,
        mediaService: mediaService,
      );

      // Verify physical files are gone
      expect(videoFile.existsSync(), isFalse);
      expect(thumbFile.existsSync(), isFalse);

      // Verify database records are deleted
      expect(await db.getEntryById('video_entry_delete'), isNull);
      expect(await db.getMediaForEntry('video_entry_delete'), isEmpty);
    });

    test('emptyRecycleBin permanently removes all deleted entries with videos', () async {
      final mediaDir = Directory(p.join(tempDir.path, 'media'))..createSync(recursive: true);

      for (int i = 1; i <= 2; i++) {
        final id = 'batch_vid_entry_$i';
        await db.createEntry(
          EntriesCompanion.insert(
            id: id,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: Value('Clip $i'),
            contentDelta: jsonEncode([{'insert': 'Clip $i\n'}]),
            plainText: 'Clip $i',
            entryDate: DateTime.now(),
          ),
        );

        File(p.join(mediaDir.path, 'clip_$i.mp4')).writeAsBytesSync([i]);
        File(p.join(mediaDir.path, 'clip_${i}_thumb.webp')).writeAsBytesSync([i]);

        await db.attachMediaToEntry(
          id: 'media_clip_$i',
          entryId: id,
          relativePath: 'media/clip_$i.mp4',
          thumbnailPath: 'media/clip_${i}_thumb.webp',
          mediaType: 'video',
        );

        await db.softDeleteEntry(id);
      }

      expect((await db.getDeletedEntries()).length, 2);

      final purged = await RecycleBinService.emptyRecycleBin(
        database: db,
        mediaService: mediaService,
      );

      expect(purged, 2);
      expect((await db.getDeletedEntries()).isEmpty, isTrue);

      // Verify all physical video and thumbnail files deleted
      for (int i = 1; i <= 2; i++) {
        expect(File(p.join(mediaDir.path, 'clip_$i.mp4')).existsSync(), isFalse);
        expect(File(p.join(mediaDir.path, 'clip_${i}_thumb.webp')).existsSync(), isFalse);
      }
    });
  });
}
