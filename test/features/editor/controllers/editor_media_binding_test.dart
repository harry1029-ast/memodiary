import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/controllers/editor_autosave_manager.dart';
import 'package:memodiary/features/editor/controllers/editor_media_binding.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/services/editor_pagination_coordinator.dart';

import '../../../helpers/editor_test_harness.dart';

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;
  late EditorPaginationCoordinator coordinator;
  late EditorAutosaveManager autosaveManager;
  late EditorMediaBinding binding;
  late int stateChangedCount;

  const entryId = 'media_binding_entry';
  const stagedMediaId = 'staged_photo';
  const mountedMediaId = 'mounted_photo';

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('media_binding_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
    stateChangedCount = 0;

    await database.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            contentDelta: jsonEncode((Delta()..insert('春江花月夜\n')).toJson()),
            plainText: '春江花月夜\n',
            entryDate: DateTime(2026, 11, 14, 10),
          ),
        );
    await database.mediaOcrDao.attachMediaToEntry(
      id: stagedMediaId,
      entryId: entryId,
      relativePath: 'media/staged.webp',
    );
    await database.mediaOcrDao.attachMediaToEntry(
      id: mountedMediaId,
      entryId: entryId,
      relativePath: 'media/mounted.webp',
    );

    final attachments = await database.mediaOcrDao.getMediaForEntry(entryId);
    coordinator = EditorPaginationCoordinator()
      ..initializeFromDelta(
        jsonEncode((Delta()..insert('春江花月夜\n')).toJson()),
        attachments: attachments,
      );
    expect(coordinator.mountOnActiveSheet(mountedMediaId), isTrue);

    autosaveManager = EditorAutosaveManager(
      database: database,
      entryId: entryId,
      coordinator: coordinator,
    );
    binding = EditorMediaBinding(
      database: database,
      mediaSandboxService: sandboxService,
      entryId: entryId,
      imagePicker: StubEditorImagePicker(),
      coordinator: coordinator,
      autosaveManager: autosaveManager,
      onStateChanged: () => stateChangedCount++,
    );
  });

  tearDown(() async {
    binding.dispose();
    autosaveManager.dispose();
    coordinator.dispose();
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  group('EditorMediaBinding.updateCaption', () {
    test('updates staged item in coordinator, triggers onStateChanged, and persists to SQLite', () async {
      await binding.updateCaption(stagedMediaId, '画卷新题');

      expect(stateChangedCount, 1);
      expect(
        coordinator.stagedItems.firstWhere((item) => item.id == stagedMediaId).caption,
        equals('画卷新题'),
      );
      final persisted = (await database.mediaOcrDao.getMediaForEntry(entryId))
          .firstWhere((row) => row.id == stagedMediaId);
      expect(persisted.caption, equals('画卷新题'));
    });

    test('updates mounted item in coordinator, triggers onStateChanged, and persists to SQLite', () async {
      await binding.updateCaption(mountedMediaId, '已贴影札题跋');

      expect(stateChangedCount, 1);
      final opening = coordinator.sheets.first as OpeningSheet;
      expect(
        opening.mediaAttachments.firstWhere((item) => item.id == mountedMediaId).caption,
        equals('已贴影札题跋'),
      );
      final persisted = (await database.mediaOcrDao.getMediaForEntry(entryId))
          .firstWhere((row) => row.id == mountedMediaId);
      expect(persisted.caption, equals('已贴影札题跋'));
    });

    test('does not invoke onStateChanged when mediaId is absent from coordinator', () async {
      await binding.updateCaption('nonexistent_id', '无此影札');

      expect(stateChangedCount, 0);
    });
  });
}
