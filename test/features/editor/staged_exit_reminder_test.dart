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
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/widget_test_helpers.dart';

const _entryId = 'exit_reminder_entry';
const _viewport = Size(360.0, 780.0);

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('staged_exit_reminder_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: _entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('孤山访梅'),
            contentDelta: jsonEncode((Delta()..insert('疏影横斜。\n')).toJson()),
            plainText: '疏影横斜。',
            entryDate: DateTime(2026, 11, 6, 9),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  Future<void> seedStagedPhotos(int count) async {
    for (var index = 0; index < count; index++) {
      final relativePath = 'media/seeded_$index.webp';
      File('${tempDirectory.path}/$relativePath')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);
      await database.attachMediaToEntry(id: 'seeded_$index', entryId: _entryId, relativePath: relativePath);
    }
  }

  Future<void> launchEditor(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('launch_editor')));
    await tester.pumpAndSettle();
  }

  /// Opens the editor above a launcher page so leaving it is observable.
  Future<void> openEditor(WidgetTester tester) async {
    tester.view.physicalSize = _viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: InkDiaryTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('launch_editor'),
              onPressed: () => Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EntryEditorScreen(
                    database: database,
                    mediaSandboxService: sandboxService,
                    entryId: _entryId,
                  ),
                ),
              ),
              child: const Text('launch'),
            ),
          ),
        ),
      ),
    ));
    await launchEditor(tester);
  }

  final exitPaths = <String, Finder>{
    '← back': find.byTooltip('返回 · Back'),
    '✓ done': find.byKey(const Key('editor_seal_done_btn')),
  };

  Finder reminder() => find.byKey(const Key('staged_exit_reminder'));
  Finder editorScreen() => find.byType(EntryEditorScreen);
  Future<List<String>> attachmentIds() async => (await database.getMediaForEntry(_entryId)).map((row) => row.id).toList();

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
      });

      testWidgets('舍弃待贴 erases the staged items, rows and files, then leaves', (tester) async {
        await seedStagedPhotos(2);
        await openEditor(tester);
        await tapExit(tester, exitPath.value);
        await choose(tester, 'staged_exit_discard_button');

        expect(editorScreen(), findsNothing);
        expect(await attachmentIds(), isEmpty);
        expect(File('${tempDirectory.path}/media/seeded_0.webp').existsSync(), isFalse);
        expect(File('${tempDirectory.path}/media/seeded_1.webp').existsSync(), isFalse);
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
    expect(File('${tempDirectory.path}/media/seeded_0.webp').existsSync(), isTrue);
  });
}
