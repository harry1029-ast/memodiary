import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/controllers/editor_autosave_manager.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.entries).insert(
          EntriesCompanion.insert(
            id: 'entry_autosave_1',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Original Title'),
            contentDelta: '[]',
            plainText: '',
            entryDate: DateTime.now(),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('EditorAutosaveManager Tests', () {
    test('initial state is saved', () {
      final controller = QuillController.basic();
      final autosave = EditorAutosaveManager(
        database: db,
        entryId: 'entry_autosave_1',
        controller: controller,
      );

      expect(autosave.statusNotifier.value, AutosaveStatus.saved);
      autosave.dispose();
      controller.dispose();
    });

    test('document changes mark status as unsaved and trigger debounced save', () async {
      final controller = QuillController.basic();
      final autosave = EditorAutosaveManager(
        database: db,
        entryId: 'entry_autosave_1',
        controller: controller,
        debounceDuration: const Duration(milliseconds: 100),
        periodicDuration: const Duration(seconds: 1),
      );

      // Mutate document
      controller.document.insert(0, 'Hello Autosave World\n');
      await Future.delayed(Duration.zero);

      // Status is unsaved
      expect(autosave.statusNotifier.value, AutosaveStatus.unsaved);

      // Wait for debounce timer to fire
      await Future.delayed(const Duration(milliseconds: 180));

      // Status should now be saved
      expect(autosave.statusNotifier.value, AutosaveStatus.saved);

      // Verify database reflects changes
      final entry = await db.getEntryById('entry_autosave_1');
      expect(entry, isNotNull);
      expect(entry!.plainText, contains('Hello Autosave World'));
      expect(jsonDecode(entry.contentDelta), isA<List>());

      autosave.dispose();
      controller.dispose();
    });

    test('force saveDraft immediately writes to database', () async {
      final controller = QuillController.basic();
      final autosave = EditorAutosaveManager(
        database: db,
        entryId: 'entry_autosave_1',
        controller: controller,
        debounceDuration: const Duration(minutes: 10),
      );

      controller.document.insert(0, 'Immediate Text\n');
      await autosave.saveDraft(force: true);

      expect(autosave.statusNotifier.value, AutosaveStatus.saved);

      final entry = await db.getEntryById('entry_autosave_1');
      expect(entry!.plainText, contains('Immediate Text'));

      autosave.dispose();
      controller.dispose();
    });

    test('title changes trigger debounced autosave of title to database', () async {
      final controller = QuillController.basic();
      final titleController = TextEditingController(text: 'Original Title');
      final autosave = EditorAutosaveManager(
        database: db,
        entryId: 'entry_autosave_1',
        controller: controller,
        titleController: titleController,
        debounceDuration: const Duration(milliseconds: 100),
        periodicDuration: const Duration(seconds: 1),
      );

      // Mutate title
      titleController.text = 'Updated Autumn Reverie';
      await Future.delayed(Duration.zero);

      expect(autosave.statusNotifier.value, AutosaveStatus.unsaved);

      // Wait for debounce timer
      await Future.delayed(const Duration(milliseconds: 180));

      expect(autosave.statusNotifier.value, AutosaveStatus.saved);

      final entry = await db.getEntryById('entry_autosave_1');
      expect(entry, isNotNull);
      expect(entry!.title, equals('Updated Autumn Reverie'));

      autosave.dispose();
      controller.dispose();
      titleController.dispose();
    });

    test('force saveDraft immediately writes title and document together', () async {
      final controller = QuillController.basic();
      final titleController = TextEditingController(text: 'Initial Title');
      final autosave = EditorAutosaveManager(
        database: db,
        entryId: 'entry_autosave_1',
        controller: controller,
        titleController: titleController,
        debounceDuration: const Duration(minutes: 10),
      );

      titleController.text = 'Forced Saved Title';
      controller.document.insert(0, 'Forced Content\n');

      await autosave.saveDraft(force: true);

      expect(autosave.statusNotifier.value, AutosaveStatus.saved);

      final entry = await db.getEntryById('entry_autosave_1');
      expect(entry!.title, equals('Forced Saved Title'));
      expect(entry.plainText, contains('Forced Content'));

      autosave.dispose();
      controller.dispose();
      titleController.dispose();
    });
  });
}
