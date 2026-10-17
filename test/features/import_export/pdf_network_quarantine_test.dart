import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/services/pdf_export_engine.dart';

/// Firewall that intercepts and fails any outbound network activity.
class QuarantinedHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('NETWORK_QUARANTINE_VIOLATION: Outbound HTTP/HTTPS requests are strictly forbidden');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = QuarantinedHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('PDF Engine Network Quarantine Tests', () {
    late AppDatabase db;
    late Directory tempDir;
    late MediaSandboxService mediaService;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      tempDir = await Directory.systemTemp.createTemp('pdf_quarantine_test_');
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

    test('HttpOverrides firewall proactively trips on any outbound call', () async {
      expect(
        () => HttpClient().getUrl(Uri.parse('https://example.com/telemetry')),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('NETWORK_QUARANTINE_VIOLATION'),
        )),
      );
    });

    test('Single-entry PDF export executes in 100% offline quarantine with zero network calls', () async {
      // 1. Embed an image into sandbox
      final mediaSubdir = Directory('${tempDir.path}/media');
      await mediaSubdir.create(recursive: true);

      final pngBytes = <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ];
      final imageFile = File('${mediaSubdir.path}/photo.png');
      await imageFile.writeAsBytes(pngBytes);

      // 2. Insert diary entry with text, headers, and media embed
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'quarantine_entry_1',
          notebookId: 'default',
          templateId: 'template_retro_kraft',
          title: const Value('Offline Forest Walk'),
          contentDelta: jsonEncode([
            {'insert': 'Hiking in the woods without cell service.\n'},
            {
              'insert': {'image': 'media/photo.png'}
            },
            {'insert': '\nTotal tranquility.\n'},
          ]),
          plainText: 'Hiking in the woods without cell service.\nTotal tranquility.',
          entryDate: DateTime(2026, 10, 17),
          mood: const Value(5),
          weather: const Value('cloudy'),
        ),
      );

      final entry = await db.getEntryById('quarantine_entry_1');
      expect(entry, isNotNull);

      // 3. Generate PDF - must not trigger any HTTP/network call
      final bytes = await PdfExportEngine.generatePdfForEntry(
        entry: entry!,
        database: db,
        mediaService: mediaService,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('Consolidated journal book export executes in 100% offline quarantine', () async {
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_offline_1',
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('Day 1'),
          contentDelta: jsonEncode([{'insert': 'Clean offline thought.\n'}]),
          plainText: 'Clean offline thought.',
          entryDate: DateTime(2026, 10, 1),
        ),
      );

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_offline_2',
          notebookId: 'default',
          templateId: 'template_lined_paper',
          title: const Value('Day 2'),
          contentDelta: jsonEncode([{'insert': 'Second offline thought.\n'}]),
          plainText: 'Second offline thought.',
          entryDate: DateTime(2026, 10, 2),
        ),
      );

      final entries = await db.getTimelineEntries(limit: 10);
      final bytes = await PdfExportEngine.generateConsolidatedPdf(
        entries: entries,
        database: db,
        mediaService: mediaService,
        bookTitle: 'Offline Journal Book',
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });
  });
}

