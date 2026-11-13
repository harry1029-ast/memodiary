import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/controllers/editor_autosave_manager.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/services/editor_pagination_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Autosave Crash Recovery Hardening', () {
    test('Dirty drafts are persisted via debounce and recoverable after sudden termination', () async {
      const entryId = 'autosave_recovery_entry_1';
      final initialDeltaJson = jsonEncode([
        {'insert': 'Initial paragraph text.\n'}
      ]);

      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: entryId,
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('Original Title'),
          contentDelta: initialDeltaJson,
          plainText: 'Initial paragraph text.',
          entryDate: DateTime(2026, 10, 16),
        ),
      );

      final coordinator = EditorPaginationCoordinator();
      coordinator.initializeFromDelta(initialDeltaJson);

      final autosaveManager = EditorAutosaveManager(
        database: db,
        entryId: entryId,
        coordinator: coordinator,
        debounceDuration: const Duration(milliseconds: 50),
        periodicDuration: const Duration(milliseconds: 200),
      );

      expect(autosaveManager.statusNotifier.value, equals(AutosaveStatus.saved));

      final openingSheet = coordinator.sheets.first as TextStationerySheet;
      openingSheet.controller.document.insert(
        openingSheet.controller.document.length - 1,
        ' Sudden thoughts written during a quiet evening walk.',
      );
      await Future<void>.delayed(Duration.zero);

      expect(autosaveManager.statusNotifier.value, equals(AutosaveStatus.unsaved));

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(autosaveManager.statusNotifier.value, equals(AutosaveStatus.saved));

      autosaveManager.dispose();
      coordinator.dispose();

      final recoveredEntry = await db.entriesDao.getEntryById(entryId);
      expect(recoveredEntry, isNotNull);
      expect(
        recoveredEntry!.plainText,
        contains('Sudden thoughts written during a quiet evening walk.'),
      );

      final recoveredDelta = jsonDecode(recoveredEntry.contentDelta) as List<dynamic>;
      expect(recoveredDelta.isNotEmpty, isTrue);
      expect(
        recoveredDelta.first['insert'].toString(),
        contains('Sudden thoughts written during a quiet evening walk.'),
      );
    });

    test('Immediate flush on app pause/exit flushes buffer before process termination', () async {
      const entryId = 'autosave_recovery_entry_2';

      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: entryId,
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('Draft 2'),
          contentDelta: jsonEncode([{'insert': '\n'}]),
          plainText: '',
          entryDate: DateTime(2026, 10, 16),
        ),
      );

      final coordinator = EditorPaginationCoordinator();
      coordinator.initializeFromDelta('');

      final autosaveManager = EditorAutosaveManager(
        database: db,
        entryId: entryId,
        coordinator: coordinator,
        debounceDuration: const Duration(seconds: 5),
        periodicDuration: const Duration(seconds: 10),
      );

      final openingSheet = coordinator.sheets.first as TextStationerySheet;
      openingSheet.controller.document.insert(0, 'Urgent last second note before OS kill.\n');
      await Future<void>.delayed(Duration.zero);
      expect(autosaveManager.statusNotifier.value, equals(AutosaveStatus.unsaved));

      await autosaveManager.saveDraft();
      expect(autosaveManager.statusNotifier.value, equals(AutosaveStatus.saved));

      autosaveManager.dispose();
      coordinator.dispose();

      final recovered = await db.entriesDao.getEntryById(entryId);
      expect(recovered, isNotNull);
      expect(recovered!.plainText, equals('Urgent last second note before OS kill.'));
    });
  });
}
