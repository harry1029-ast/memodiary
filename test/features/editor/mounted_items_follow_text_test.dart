// Drives Quill's (experimental) copy and paste entry points directly.
// ignore_for_file: experimental_member_use
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/models/mount_marker.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/tucked_prints_test_helpers.dart';

const _entryId = 'follow_text_entry';
const _viewport = Size(360.0, 780.0);

/// Ten short lines: exactly the opening sheet's row capacity.
String _openingLines() => List.generate(10, (index) => '湖上第$index行').join('\n');

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUpAll(() {
    VideoPlayerPlatform.instance = FakeEditorVideoPlatform();
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('follow_text_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> seedEntry(Delta delta, List<String> attachmentIds) async {
    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: _entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('苏堤春晓'),
            contentDelta: jsonEncode(delta.toJson()),
            plainText: '',
            entryDate: DateTime(2026, 11, 6, 9),
          ),
        );
    final mediaDir = Directory('${tempDirectory.path}/media')..createSync(recursive: true);
    for (final (index, id) in attachmentIds.indexed) {
      File('${mediaDir.path}/$id.webp').writeAsBytesSync(kValid1x1PngBytes);
      await database.into(database.mediaAttachments).insert(
            MediaAttachmentsCompanion.insert(
              id: id,
              entryId: _entryId,
              mediaType: 'image',
              relativePath: 'media/$id.webp',
              createdAt: Value(DateTime(2026, 11, 6, 9, index)),
            ),
          );
    }
  }

  Future<void> openEditor(WidgetTester tester) => pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: _entryId,
        viewportSize: _viewport,
      );

  Future<void> reopenEditor(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('editor_seal_done_btn')));
    await tester.pumpAndSettle();
    // Items still staged on exit raise the reminder; keep them for reopening.
    final keepButton = find.byKey(const Key('staged_exit_keep_button'));
    if (keepButton.evaluate().isNotEmpty) {
      await tester.tap(keepButton);
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await openEditor(tester);
  }

  QuillController openingController(WidgetTester tester) =>
      tester.widget<QuillEditor>(find.byType(QuillEditor).first).controller;

  Finder handscrollItem(String mediaId) => find.byKey(Key('handscroll_item_$mediaId'));

  Future<List<String>> savedMarkerIds() async {
    final entry = await database.getEntryById(_entryId);
    return MountMarker.mediaIdsIn(Delta.fromJson(jsonDecode(entry!.contentDelta) as List));
  }

  group('Mounted items follow their text in the editor', () {
    testWidgets('typing above a mounted passage until it spills moves the item to the next sheet', (tester) async {
      await seedEntry(
        Delta()
          ..insert(_openingLines())
          ..insert({'mount': 'plum'})
          ..insert('\n'),
        ['plum'],
      );
      await openEditor(tester);
      expect(find.text('第 1 / 1 页'), findsOneWidget);
      expect(tuckedPrint('plum'), findsOneWidget);

      openingController(tester).replaceText(0, 0, '晨起\n', const TextSelection.collapsed(offset: 3));
      await tester.pumpAndSettle();

      await goToSheet(tester, 1, 2);
      expect(tuckedPrint('plum'), findsNothing);
      await goToSheet(tester, 2, 2);
      expect(tuckedPrint('plum'), findsOneWidget);
      expect(handscrollItem('plum'), findsNothing);

      await reopenEditor(tester);
      await goToSheet(tester, 2, 2);
      expect(tuckedPrint('plum'), findsOneWidget);
    });

    testWidgets('deleting a passage unmounts its item; undo remounts it; redo unmounts again', (tester) async {
      await seedEntry(
        Delta()
          ..insert('断桥')
          ..insert('残雪')
          ..insert({'mount': 'plum'})
          ..insert('\n'),
        ['plum'],
      );
      await openEditor(tester);
      expect(tuckedPrint('plum'), findsOneWidget);
      final controller = openingController(tester);

      controller.replaceText(2, 3, '', const TextSelection.collapsed(offset: 2));
      await tester.pumpAndSettle();
      expect(tuckedPrint('plum'), findsNothing);
      expect(handscrollItem('plum'), findsOneWidget);
      expect(await database.getMediaForEntry(_entryId), hasLength(1), reason: 'never deleted');

      controller.undo();
      await tester.pumpAndSettle();
      expect(tuckedPrint('plum'), findsOneWidget);
      expect(handscrollItem('plum'), findsNothing);

      controller.redo();
      await tester.pumpAndSettle();
      expect(tuckedPrint('plum'), findsNothing);
      expect(handscrollItem('plum'), findsOneWidget);
    });

    testWidgets('copying and pasting a passage with a marker pastes no marker', (tester) async {
      String? clipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String?;
        } else if (call.method == 'Clipboard.getData') {
          return {'text': clipboardText};
        } else if (call.method == 'Clipboard.hasStrings') {
          return {'value': clipboardText != null};
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await seedEntry(
        Delta()
          ..insert('落花')
          ..insert({'mount': 'plum'})
          ..insert('流水\n'),
        ['plum'],
      );
      await openEditor(tester);
      final controller = openingController(tester);

      controller.updateSelection(const TextSelection(baseOffset: 0, extentOffset: 5), ChangeSource.local);
      controller.clipboardSelection(true);
      controller.updateSelection(const TextSelection.collapsed(offset: 5), ChangeSource.local);
      await tester.runAsync(controller.clipboardPaste);
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), startsWith('落花￼流水落花流水'));
      expect(tuckedPrint('plum'), findsOneWidget);
      await reopenEditor(tester);
      expect(await savedMarkerIds(), ['plum']);
    });

    testWidgets('reflow onto a full last sheet unmounts the extras with a message, adding no sheet', (tester) async {
      await seedEntry(
        Delta()
          ..insert(_openingLines())
          ..insert({'mount': 'a'})
          ..insert({'mount': 'b'})
          ..insert({'mount': 'c'})
          ..insert('\n次页')
          ..insert({'mount': 'd'})
          ..insert({'mount': 'e'})
          ..insert({'mount': 'f'})
          ..insert('\n'),
        ['a', 'b', 'c', 'd', 'e', 'f'],
      );
      await openEditor(tester);
      expect(find.text('第 1 / 2 页'), findsOneWidget);
      expect(find.byKey(const Key('staging_handscroll')), findsNothing);

      openingController(tester).replaceText(0, 0, '晨起\n', const TextSelection.collapsed(offset: 3));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('overflow_unmount_snackbar')), findsOneWidget);
      expect(find.textContaining('3 影已揭回画卷'), findsOneWidget);
      expect(find.textContaining(' / 2 页'), findsOneWidget, reason: 'no media-only sheet');
      await goToSheet(tester, 2, 2);
      for (final mediaId in ['a', 'b', 'c']) {
        expect(tuckedPrint(mediaId), findsOneWidget);
      }
      for (final mediaId in ['d', 'e', 'f']) {
        expect(handscrollItem(mediaId), findsOneWidget);
      }

      await reopenEditor(tester);
      expect(await savedMarkerIds(), ['a', 'b', 'c']);
    });

    testWidgets('auto-spill with markers present stays responsive to further typing', (tester) async {
      await seedEntry(
        Delta()
          ..insert(_openingLines())
          ..insert({'mount': 'plum'})
          ..insert('\n'),
        ['plum'],
      );
      await openEditor(tester);
      final controller = openingController(tester);

      final endOfText = controller.document.length - 1;
      controller.replaceText(endOfText, 0, '\n续', TextSelection.collapsed(offset: endOfText + 2));
      await tester.pumpAndSettle();
      expect(find.text('第 2 / 2 页'), findsOneWidget);

      final continuation = tester.widget<QuillEditor>(find.byType(QuillEditor).last).controller;
      continuation.replaceText(1, 0, '写', const TextSelection.collapsed(offset: 2));
      await tester.pumpAndSettle();
      expect(continuation.document.toPlainText(), startsWith('续写'));
      await goToSheet(tester, 1, 2);
      expect(tuckedPrint('plum'), findsOneWidget, reason: 'the marker stays with its passage on sheet 1');
    });
  });
}
