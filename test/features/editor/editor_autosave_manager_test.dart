import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/controllers/editor_autosave_manager.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/services/editor_pagination_coordinator.dart';

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

  EditorPaginationCoordinator createInitializedCoordinator() {
    final coordinator = EditorPaginationCoordinator();
    coordinator.initializeFromDelta('');
    return coordinator;
  }

  group('EditorAutosaveManager Tests', () {
    test('initial state is saved', () {
      final coordinator = createInitializedCoordinator();
      final autosave = EditorAutosaveManager(
        database: db,
        entryId: 'entry_autosave_1',
        coordinator: coordinator,
      );

      expect(autosave.statusNotifier.value, AutosaveStatus.saved);
      autosave.dispose();
      coordinator.dispose();
    });

    test('document changes mark status as unsaved and trigger debounced save', () async {
      final coordinator = createInitializedCoordinator();
      final autosave = EditorAutosaveManager(
        database: db,
        entryId: 'entry_autosave_1',
        coordinator: coordinator,
        debounceDuration: const Duration(milliseconds: 100),
        periodicDuration: const Duration(seconds: 1),
      );

      final openingSheet = coordinator.sheets.first as TextStationerySheet;
      openingSheet.controller.document.insert(0, 'Hello Autosave World\n');
      await Future<void>.delayed(Duration.zero);

      expect(autosave.statusNotifier.value, AutosaveStatus.unsaved);

      await Future<void>.delayed(const Duration(milliseconds: 180));

      expect(autosave.statusNotifier.value, AutosaveStatus.saved);

      final entry = await db.getEntryById('entry_autosave_1');
      expect(entry, isNotNull);
      expect(entry!.plainText, contains('Hello Autosave World'));
      expect(jsonDecode(entry.contentDelta), isA<List>());

      autosave.dispose();
      coordinator.dispose();
    });

    test('force saveDraft immediately writes to database', () async {
      final coordinator = createInitializedCoordinator();
      final autosave = EditorAutosaveManager(
        database: db,
        entryId: 'entry_autosave_1',
        coordinator: coordinator,
        debounceDuration: const Duration(minutes: 10),
      );

      final openingSheet = coordinator.sheets.first as TextStationerySheet;
      openingSheet.controller.document.insert(0, 'Immediate Text\n');
      await autosave.saveDraft(force: true);

      expect(autosave.statusNotifier.value, AutosaveStatus.saved);

      final entry = await db.getEntryById('entry_autosave_1');
      expect(entry!.plainText, contains('Immediate Text'));

      autosave.dispose();
      coordinator.dispose();
    });

    test('title changes trigger debounced autosave of title to database', () async {
      final coordinator = createInitializedCoordinator();
      final titleController = TextEditingController(text: 'Original Title');
      final autosave = EditorAutosaveManager(
        database: db,
        entryId: 'entry_autosave_1',
        coordinator: coordinator,
        titleController: titleController,
        debounceDuration: const Duration(milliseconds: 100),
        periodicDuration: const Duration(seconds: 1),
      );

      titleController.text = 'Updated Autumn Reverie';
      await Future<void>.delayed(Duration.zero);

      expect(autosave.statusNotifier.value, AutosaveStatus.unsaved);

      await Future<void>.delayed(const Duration(milliseconds: 180));

      expect(autosave.statusNotifier.value, AutosaveStatus.saved);

      final entry = await db.getEntryById('entry_autosave_1');
      expect(entry, isNotNull);
      expect(entry!.title, equals('Updated Autumn Reverie'));

      autosave.dispose();
      coordinator.dispose();
      titleController.dispose();
    });

    test('force saveDraft immediately writes title and document together', () async {
      final coordinator = createInitializedCoordinator();
      final titleController = TextEditingController(text: 'Initial Title');
      final autosave = EditorAutosaveManager(
        database: db,
        entryId: 'entry_autosave_1',
        coordinator: coordinator,
        titleController: titleController,
        debounceDuration: const Duration(minutes: 10),
      );

      titleController.text = 'Forced Saved Title';
      final openingSheet = coordinator.sheets.first as TextStationerySheet;
      openingSheet.controller.document.insert(0, 'Forced Content\n');

      await autosave.saveDraft(force: true);

      expect(autosave.statusNotifier.value, AutosaveStatus.saved);

      final entry = await db.getEntryById('entry_autosave_1');
      expect(entry!.title, equals('Forced Saved Title'));
      expect(entry.plainText, contains('Forced Content'));

      autosave.dispose();
      coordinator.dispose();
      titleController.dispose();
    });

    test('ephemera caption edits and post-typography-rebalance text edits trigger debounced save via contentRevision', () async {
      final initialDelta = Delta()
        ..insert('湖心亭看雪\n')
        ..insert({'image': 'media/snow.webp'})
        ..insert('\n');
      final coordinator = EditorPaginationCoordinator()
        ..initializeFromDelta(jsonEncode(initialDelta.toJson()));
      final autosave = EditorAutosaveManager(
        database: db,
        entryId: 'entry_autosave_1',
        coordinator: coordinator,
        debounceDuration: const Duration(milliseconds: 80),
        periodicDuration: const Duration(seconds: 1),
      );

      final ephemeraSheet = coordinator.sheets[1] as EphemeraSheet;
      ephemeraSheet.captionController.text = '雾凇沆砀，天与云与山与水，上下一白';
      expect(autosave.statusNotifier.value, AutosaveStatus.unsaved);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(autosave.statusNotifier.value, AutosaveStatus.saved);

      var saved = await db.getEntryById('entry_autosave_1');
      expect(saved!.contentDelta, contains('雾凇沆砀'));

      // Re-balance via updateTypography (replaces all sheet instances) and then type on Sheet 1:
      coordinator.updateTypography(const TypographySettings(fontSize: 20.0, lineSpacing: 1.8));
      final openingAfterRebalance = coordinator.sheets.first as TextStationerySheet;
      openingAfterRebalance.controller.document.insert(0, '崇祯五年十二月，');
      await Future<void>.delayed(Duration.zero);
      expect(autosave.statusNotifier.value, AutosaveStatus.unsaved);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(autosave.statusNotifier.value, AutosaveStatus.saved);

      saved = await db.getEntryById('entry_autosave_1');
      expect(saved!.plainText, contains('崇祯五年十二月，湖心亭看雪'));

      autosave.dispose();
      coordinator.dispose();
    });

    test('coordinator media mutations mark autosave unsaved and persist via contentRevision', () async {
      final initialDelta = Delta()
        ..insert('西湖游记\n')
        ..insert({'image': 'media/legacy_ephemera.webp'})
        ..insert('\n');
      final coordinator = EditorPaginationCoordinator()
        ..initializeFromDelta(jsonEncode(initialDelta.toJson()));
      final autosave = EditorAutosaveManager(
        database: db,
        entryId: 'entry_autosave_1',
        coordinator: coordinator,
        debounceDuration: const Duration(minutes: 10),
      );

      Future<void> expectDirtyThenSave(void Function() mutate) async {
        expect(autosave.statusNotifier.value, AutosaveStatus.saved);
        mutate();
        expect(autosave.statusNotifier.value, AutosaveStatus.unsaved);
        await autosave.saveDraft(force: true);
        expect(autosave.statusNotifier.value, AutosaveStatus.saved);
      }

      const item = SheetMediaItem(
        id: 'print_1',
        mediaType: EphemeraMediaType.image,
        relativePath: 'media/print_1.webp',
        caption: '断桥残雪',
      );

      await expectDirtyThenSave(() {
        expect(coordinator.collectMedia(item), isTrue);
      });

      await expectDirtyThenSave(() {
        expect(coordinator.mountOnActiveSheet('print_1'), isTrue);
      });
      var saved = await db.getEntryById('entry_autosave_1');
      expect(saved!.contentDelta, contains('print_1'));

      await expectDirtyThenSave(() {
        expect(coordinator.updateCaption('print_1', '平湖秋月'), isTrue);
      });

      await expectDirtyThenSave(() {
        expect(coordinator.unmountMedia('print_1'), isTrue);
      });
      saved = await db.getEntryById('entry_autosave_1');
      expect(saved!.contentDelta, isNot(contains('print_1')));

      SheetMediaItem? removed;
      await expectDirtyThenSave(() {
        removed = coordinator.removeStaged('print_1');
        expect(removed, isNotNull);
      });

      await expectDirtyThenSave(() {
        coordinator.restoreStaged(removed!);
      });

      await expectDirtyThenSave(() {
        coordinator.removeEphemeraSheet(1);
      });
      saved = await db.getEntryById('entry_autosave_1');
      expect(saved!.contentDelta, isNot(contains('legacy_ephemera.webp')));

      autosave.dispose();
      coordinator.dispose();
    });
  });
}
