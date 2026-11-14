import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/controllers/editor_autosave_manager.dart';
import 'package:memodiary/features/editor/controllers/editor_pagination_handler.dart';
import 'package:memodiary/features/editor/services/editor_pagination_coordinator.dart';

void main() {
  late AppDatabase database;
  late EditorPaginationCoordinator coordinator;
  late EditorAutosaveManager autosaveManager;
  late PageController pageController;
  late EditorPaginationHandler handler;
  late int stateChangedCount;
  var controllersDisposed = false;

  const entryId = 'pagination_handler_entry';

  void disposeControllers() {
    if (controllersDisposed) return;
    controllersDisposed = true;
    handler.dispose();
    pageController.dispose();
    autosaveManager.dispose();
    coordinator.dispose();
  }

  setUp(() async {
    controllersDisposed = false;
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.entriesDao.createEntry(
      EntriesCompanion.insert(
        id: entryId,
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        contentDelta: jsonEncode((Delta()..insert('正文\n')).toJson()),
        plainText: '正文\n',
        entryDate: DateTime(2026, 11, 14, 12),
      ),
    );
    coordinator = EditorPaginationCoordinator();
    autosaveManager = EditorAutosaveManager(
      database: database,
      entryId: entryId,
      coordinator: coordinator,
    );
    pageController = PageController();
    stateChangedCount = 0;
  });

  tearDown(() async {
    disposeControllers();
    await database.close();
  });

  testWidgets(
    'syncs currentSheetIndex and PageController when trailing EphemeraSheet is removed',
    (tester) async {
      final deltaJson = jsonEncode(
        (Delta()
              ..insert('第一页墨迹。\n')
              ..insert({'image': 'media/trailing_ephemera.webp'})
              ..insert('\n'))
            .toJson(),
      );
      coordinator.initializeFromDelta(deltaJson);
      expect(coordinator.totalSheets, 2);

      late StateSetter rebuildHost;
      handler = EditorPaginationHandler(
        coordinator: coordinator,
        pageController: pageController,
        autosaveManager: autosaveManager,
        onStateChanged: () {
          stateChangedCount++;
          rebuildHost(() {});
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildHost = setState;
                return PageView.builder(
                  controller: pageController,
                  itemCount: coordinator.totalSheets,
                  onPageChanged: handler.handlePageChanged,
                  itemBuilder: (context, index) => Text('Sheet $index'),
                );
              },
            ),
          ),
        ),
      );

      handler.goToSheet(1);
      await tester.pumpAndSettle();
      expect(handler.currentSheetIndex, 1);
      expect(pageController.page?.round(), 1);

      // Remove the active trailing EphemeraSheet and align viewport.
      coordinator.removeEphemeraSheet(1);
      handler.syncViewportToActiveSheet();
      await tester.pumpAndSettle();

      expect(coordinator.totalSheets, 1);
      expect(handler.currentSheetIndex, 0);
      expect(pageController.page?.round(), 0);
      expect(stateChangedCount, greaterThan(0));

      // Cancel debounce/periodic autosave timers before testWidgets checks !timersPending.
      disposeControllers();
    },
  );
}
