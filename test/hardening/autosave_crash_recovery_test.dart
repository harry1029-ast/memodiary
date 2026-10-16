import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/controllers/editor_autosave_manager.dart';

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

      // 1. Create an initial entry in SQLite
      await db.createEntry(
        EntriesCompanion.insert(
          id: entryId,
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('Original Title'),
          contentDelta: jsonEncode([
            {'insert': 'Initial paragraph text.\n'}
          ]),
          plainText: 'Initial paragraph text.',
          entryDate: DateTime(2026, 10, 16),
        ),
      );

      // 2. Initialize QuillController and EditorAutosaveManager
      final doc = Document.fromJson([
        {'insert': 'Initial paragraph text.\n'}
      ]);
      final controller = QuillController.basic()..document = doc;

      final autosaveManager = EditorAutosaveManager(
        database: db,
        entryId: entryId,
        controller: controller,
        debounceDuration: const Duration(milliseconds: 50),
        periodicDuration: const Duration(milliseconds: 200),
      );

      expect(autosaveManager.statusNotifier.value, equals(AutosaveStatus.saved));

      // 3. Simulate user typing new reflections into the editor
      controller.document.insert(
        controller.document.length - 1,
        ' Sudden thoughts written during a quiet evening walk.',
      );
      await Future<void>.delayed(Duration.zero);

      expect(autosaveManager.statusNotifier.value, equals(AutosaveStatus.unsaved));

      // 4. Wait for the debounce timer to fire and complete the save
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(autosaveManager.statusNotifier.value, equals(AutosaveStatus.saved));

      // 5. Simulate sudden process termination / crash:
      // Dispose the manager abruptly without explicit manual "Save" action
      autosaveManager.dispose();
      controller.dispose();

      // 6. Recovery verification: New session queries database for entryId
      final recoveredEntry = await db.getEntryById(entryId);
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

      await db.createEntry(
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

      final doc = Document();
      final controller = QuillController.basic()..document = doc;

      // Long debounce (5 seconds) to ensure debounce has NOT elapsed
      final autosaveManager = EditorAutosaveManager(
        database: db,
        entryId: entryId,
        controller: controller,
        debounceDuration: const Duration(seconds: 5),
        periodicDuration: const Duration(seconds: 10),
      );

      controller.document.insert(0, 'Urgent last second note before OS kill.\n');
      await Future<void>.delayed(Duration.zero);
      expect(autosaveManager.statusNotifier.value, equals(AutosaveStatus.unsaved));

      // App lifecycle hook triggers emergency saveDraft() on pause/inactive
      await autosaveManager.saveDraft();
      expect(autosaveManager.statusNotifier.value, equals(AutosaveStatus.saved));

      // Kill editor session abruptly
      autosaveManager.dispose();
      controller.dispose();

      // Verify draft was safely committed to SQLite
      final recovered = await db.getEntryById(entryId);
      expect(recovered, isNotNull);
      expect(recovered!.plainText, equals('Urgent last second note before OS kill.'));
    });
  });
}
