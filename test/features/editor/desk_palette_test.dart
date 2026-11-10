import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/widgets/desk_workstation/desk_palette.dart';
import 'package:memodiary/features/editor/widgets/desk_workstation/scholar_desk_painter.dart';
import '../../helpers/editor_test_harness.dart';

const _templates = ['template_minimalist_white', 'template_lined_paper'];
const _viewport = Size(360.0, 780.0);

/// The Scholar's Desk follows the app's brightness and never the template.
void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('desk_palette_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
    for (final templateId in _templates) {
      await database.into(database.entries).insert(
            EntriesCompanion.insert(
              id: 'entry_$templateId',
              notebookId: 'notebook_default',
              templateId: templateId,
              title: const Value('案头'),
              contentDelta: jsonEncode((Delta()..insert('砚池墨痕\n')).toJson()),
              plainText: '砚池墨痕',
              entryDate: DateTime(2026, 11, 10, 20),
            ),
          );
    }
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  ScholarDeskPainter painterOf(WidgetTester tester, Key key) =>
      tester.widget<CustomPaint>(find.byKey(key)).painter! as ScholarDeskPainter;

  for (final templateId in _templates) {
    for (final (theme, expected) in [
      (InkDiaryTheme.light, DeskPalette.walnut),
      (InkDiaryTheme.dark, DeskPalette.ebony),
    ]) {
      testWidgets(
        'with $templateId the desk and the workstation mat use the ${theme.brightness.name} palette',
        (tester) async {
          await pumpEntryEditorScreen(
            tester,
            database: database,
            mediaSandboxService: sandboxService,
            entryId: 'entry_$templateId',
            viewportSize: _viewport,
            theme: theme,
          );

          expect(painterOf(tester, const Key('editor_scholar_desk')).palette, same(expected));
          expect(painterOf(tester, const Key('desk_workstation')).palette, same(expected));
        },
      );
    }
  }

  test('the ebony desk is deeper than the walnut desk', () {
    expect(
      DeskPalette.ebony.base.computeLuminance(),
      lessThan(DeskPalette.walnut.base.computeLuminance()),
    );
    expect(DeskPalette.forBrightness(Brightness.dark), same(DeskPalette.ebony));
    expect(DeskPalette.forBrightness(Brightness.light), same(DeskPalette.walnut));
  });
}
