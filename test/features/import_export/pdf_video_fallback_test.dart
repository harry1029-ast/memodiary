import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/services/pdf_export_engine.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('pdf_video_fallback_test_');
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

  group('PDF Video Fallback Tests', () {
    test('renders video embed with companion poster in generated PDF', () async {
      final mediaDir = Directory(p.join(tempDir.path, 'media'))..createSync(recursive: true);
      // Create fake video and poster thumbnail
      File(p.join(mediaDir.path, 'clip.mp4')).writeAsBytesSync([1, 2, 3]);

      // Generate a valid procedural poster thumbnail
      await MediaSandboxService.generateProceduralVideoPoster(
        targetThumbnailPath: p.join(mediaDir.path, 'clip_thumb.webp'),
        durationSeconds: 24,
      );

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_video_1',
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('Lake Sunset Clip'),
          contentDelta: jsonEncode([
            {'insert': 'Watched the golden dusk at the lake.\n'},
            {'insert': {'video': 'media/clip.mp4'}},
            {'insert': '\nThe water ripples were mesmerizing.\n'},
          ]),
          plainText: 'Watched the golden dusk at the lake.\n\nThe water ripples were mesmerizing.',
          entryDate: DateTime(2026, 10, 16),
        ),
      );

      final entry = await db.getEntryById('entry_video_1');
      expect(entry, isNotNull);

      final pdfBytes = await PdfExportEngine.generatePdfForEntry(
        entry: entry!,
        database: db,
        mediaService: mediaService,
      );

      expect(pdfBytes, isNotEmpty);
      // Standard PDF magic byte sequence: %PDF-
      expect(pdfBytes[0], 0x25); // %
      expect(pdfBytes[1], 0x50); // P
      expect(pdfBytes[2], 0x44); // D
      expect(pdfBytes[3], 0x46); // F
    });

    test('renders graceful placeholder when video thumbnail is missing', () async {
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_video_missing_poster',
          notebookId: 'default',
          templateId: 'template_grid_paper',
          title: const Value('Missing Poster Video'),
          contentDelta: jsonEncode([
            {'insert': 'Video with missing poster frame:\n'},
            {'insert': {'video': 'media/non_existent_clip.mp4'}},
            {'insert': '\nEnd of entry.\n'},
          ]),
          plainText: 'Video with missing poster frame:\n\nEnd of entry.',
          entryDate: DateTime(2026, 10, 16),
        ),
      );

      final entry = await db.getEntryById('entry_video_missing_poster');
      expect(entry, isNotNull);

      final pdfBytes = await PdfExportEngine.generatePdfForEntry(
        entry: entry!,
        database: db,
        mediaService: mediaService,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes[0], 0x25);
      expect(pdfBytes[1], 0x50);
      expect(pdfBytes[2], 0x44);
      expect(pdfBytes[3], 0x46);
    });
  });
}

