import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_quill/quill_delta.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'editor_test_harness.dart';

/// In-memory database, temp sandbox and one saved entry for tests that open
/// the editor over staged (unmounted) photos. Call [setUp] / [tearDown] from
/// the suite's own `setUp` / `tearDown`.
class StagedEditorFixture {
  final String entryId;
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  StagedEditorFixture({required this.entryId});

  Future<void> setUp() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('staged_editor_fixture_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('孤山访梅'),
            contentDelta: jsonEncode((Delta()..insert('疏影横斜。\n')).toJson()),
            plainText: '疏影横斜。',
            entryDate: DateTime(2026, 11, 6, 9),
          ),
        );
  }

  Future<void> tearDown() async {
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  }

  /// Seeds [count] staged photos (attachments without mount markers), ids
  /// `seeded_0` ... with files at `media/seeded_<n>.webp`.
  Future<void> seedStagedPhotos(int count) async {
    for (var index = 0; index < count; index++) {
      final relativePath = 'media/seeded_$index.webp';
      File('${tempDirectory.path}/$relativePath')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);
      await database.attachMediaToEntry(id: 'seeded_$index', entryId: entryId, relativePath: relativePath);
    }
  }
}
