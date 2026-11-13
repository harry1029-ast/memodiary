import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/staged_editor_fixture.dart';
import '../../helpers/widget_test_helpers.dart';

const _entryId = 'exit_reminder_entry';
const _viewport = Size(360.0, 780.0);

void main() {
  final fixture = StagedEditorFixture(entryId: _entryId);

  setUp(fixture.setUp);
  tearDown(fixture.tearDown);

  Future<void> seedStagedPhotos(int count) => fixture.seedStagedPhotos(count);

  Future<void> launchEditor(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('launch_editor')));
    await tester.pumpAndSettle();
  }

  /// Opens the editor above a launcher page so leaving it is observable.
  Future<void> openEditor(WidgetTester tester) => pumpEntryEditorScreen(
        tester,
        database: fixture.database,
        mediaSandboxService: fixture.sandboxService,
        entryId: _entryId,
        viewportSize: _viewport,
        launchFromRoute: true,
      );

  final exitPaths = <String, Finder>{
    '← back': find.byTooltip('返回 · Back'),
    '✓ done': find.byKey(const Key('editor_seal_done_btn')),
  };

  Finder reminder() => find.byKey(const Key('staged_exit_reminder'));
  Finder editorScreen() => find.byType(EntryEditorScreen);
  Future<List<String>> attachmentIds() async => (await fixture.database.mediaOcrDao.getMediaForEntry(_entryId)).map((row) => row.id).toList();

  Future<void> tapExit(WidgetTester tester, Finder exitPath) async {
    await tester.tap(exitPath);
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  for (final exitPath in exitPaths.entries) {
    group('exit via ${exitPath.key}', () {
      testWidgets('with an empty handscroll leaves without a reminder', (tester) async {
        await openEditor(tester);
        await tapExit(tester, exitPath.value);

        expect(reminder(), findsNothing);
        expect(editorScreen(), findsNothing);
      });

      testWidgets('with staged items asks first, offering all three choices', (tester) async {
        await seedStagedPhotos(2);
        await openEditor(tester);
        await tapExit(tester, exitPath.value);

        expect(reminder(), findsOneWidget);
        expect(editorScreen(), findsOneWidget);
        expect(find.byKey(const Key('staged_exit_keep_button')), findsOneWidget);
        expect(find.byKey(const Key('staged_exit_discard_button')), findsOneWidget);
        expect(find.byKey(const Key('staged_exit_continue_button')), findsOneWidget);
        expect(find.textContaining('2'), findsWidgets);
        await expectAccessibleTapTargets(tester, within: reminder());
      });

      testWidgets('留在画卷 leaves and keeps the items staged for next time', (tester) async {
        await seedStagedPhotos(2);
        await openEditor(tester);
        await tapExit(tester, exitPath.value);
        await choose(tester, 'staged_exit_keep_button');

        expect(editorScreen(), findsNothing);
        expect(await attachmentIds(), ['seeded_0', 'seeded_1']);

        await launchEditor(tester);
        expect(find.byKey(const Key('handscroll_item_seeded_0')), findsOneWidget);
        expect(find.byKey(const Key('handscroll_item_seeded_1')), findsOneWidget);
        // Reopened items rest in full colour: no Brush Reveal replay.
        expect(find.byKey(const Key('brush_reveal_cover_seeded_0')), findsNothing);
        expect(find.byKey(const Key('brush_reveal_cover_seeded_1')), findsNothing);
        expect(find.byKey(const Key('brush_reveal_ink_wash_seeded_0')), findsNothing);
      });

      testWidgets('舍弃待贴 erases the staged items, rows and files, then leaves', (tester) async {
        await seedStagedPhotos(2);
        await openEditor(tester);
        await tapExit(tester, exitPath.value);
        await choose(tester, 'staged_exit_discard_button');

        expect(editorScreen(), findsNothing);
        expect(await attachmentIds(), isEmpty);
        expect(File('${fixture.tempDirectory.path}/media/seeded_0.webp').existsSync(), isFalse);
        expect(File('${fixture.tempDirectory.path}/media/seeded_1.webp').existsSync(), isFalse);
      });

      testWidgets('继续装裱 dismisses the reminder and stays in the editor', (tester) async {
        await seedStagedPhotos(2);
        await openEditor(tester);
        await tapExit(tester, exitPath.value);
        await choose(tester, 'staged_exit_continue_button');

        expect(reminder(), findsNothing);
        expect(editorScreen(), findsOneWidget);
        expect(await attachmentIds(), ['seeded_0', 'seeded_1']);
      });
    });
  }

  testWidgets('舍弃待贴 leaves mounted items untouched', (tester) async {
    await seedStagedPhotos(2);
    await openEditor(tester);
    await tester.tap(find.byKey(const Key('handscroll_mount_seeded_0')));
    await tester.pumpAndSettle();

    await tapExit(tester, exitPaths['✓ done']!);
    await choose(tester, 'staged_exit_discard_button');

    expect(editorScreen(), findsNothing);
    expect(await attachmentIds(), ['seeded_0']);
    expect(File('${fixture.tempDirectory.path}/media/seeded_0.webp').existsSync(), isTrue);
  });
}
