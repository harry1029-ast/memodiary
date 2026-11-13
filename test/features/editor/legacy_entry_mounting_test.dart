import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/tucked_prints_test_helpers.dart';

const _entryId = 'legacy_entry';
const _viewport = Size(360.0, 780.0);

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUpAll(() {
    VideoPlayerPlatform.instance = FakeEditorVideoPlatform();
  });

  Future<void> seedEntry({required bool legacyMountsPending}) async {
    await database.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: _entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('孤山访梅'),
            contentDelta: jsonEncode((Delta()..insert('孤山梅开。\n')).toJson()),
            plainText: '孤山梅开。',
            entryDate: DateTime(2026, 2, 14, 9),
            legacyMountsPending: Value(legacyMountsPending),
          ),
        );
    final mediaDir = Directory('${tempDirectory.path}/media')..createSync(recursive: true);
    for (final id in const ['plum', 'pavilion']) {
      File('${mediaDir.path}/$id.webp').writeAsBytesSync(kValid1x1PngBytes);
      await database.mediaOcrDao.attachMediaToEntry(
        id: id,
        entryId: _entryId,
        relativePath: 'media/$id.webp',
      );
    }
  }

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('legacy_entry_mounting_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> openEditor(WidgetTester tester) => pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: _entryId,
        viewportSize: _viewport,
      );

  Future<void> reopenEditor(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await openEditor(tester);
  }


  const mountedOps = [
    {'insert': '孤山梅开。'},
    {
      'insert': {'mount': 'plum'},
    },
    {
      'insert': {'mount': 'pavilion'},
    },
    {'insert': '\n'},
  ];

  group('Existing entries: legacy mounting pass', () {
    testWidgets('opening a pre-SPEC-010 entry mounts its attachments first-come and persists markers', (tester) async {
      await seedEntry(legacyMountsPending: true);

      await openEditor(tester);

      expect(tuckedPrint('plum'), findsOneWidget);
      expect(tuckedPrint('pavilion'), findsOneWidget);
      expect(find.byKey(const Key('staging_handscroll')), findsNothing);

      final entry = (await database.entriesDao.getEntryById(_entryId))!;
      expect(jsonDecode(entry.contentDelta), mountedOps);
      expect(entry.plainText, '孤山梅开。');
      expect(entry.legacyMountsPending, isFalse);
    });

    testWidgets('reopening a migrated entry leaves its mounts unchanged', (tester) async {
      await seedEntry(legacyMountsPending: true);
      await openEditor(tester);
      final migrated = (await database.entriesDao.getEntryById(_entryId))!;

      await reopenEditor(tester);

      expect(tuckedPrint('plum'), findsOneWidget);
      expect(tuckedPrint('pavilion'), findsOneWidget);
      expect(await database.entriesDao.getEntryById(_entryId), migrated);
    });

    testWidgets('an entry not pending the pass keeps its unanchored items staged', (tester) async {
      await seedEntry(legacyMountsPending: false);

      await openEditor(tester);

      expect(find.byKey(const Key('handscroll_item_plum')), findsOneWidget);
      expect(find.byKey(const Key('handscroll_item_pavilion')), findsOneWidget);
      expect(tuckedPrintsFan, findsNothing);
      expect(
        jsonDecode((await database.entriesDao.getEntryById(_entryId))!.contentDelta),
        [
          {'insert': '孤山梅开。\n'},
        ],
      );
    });
  });
}
