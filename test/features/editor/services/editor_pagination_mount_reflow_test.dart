// Drives Quill's (experimental) copy and paste entry points directly.
// ignore_for_file: experimental_member_use
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/models/mount_marker.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/services/editor_pagination_coordinator.dart';

const _typography = TypographySettings(fontSize: 16.0, lineSpacing: 1.5);

MediaAttachment _attachment(String id) => MediaAttachment(
      id: id,
      entryId: 'entry',
      mediaType: 'image',
      relativePath: 'media/$id.webp',
      createdAt: DateTime(2026, 11, 6),
    );

String _lines(String prefix, int count) =>
    List.generate(count, (index) => '$prefix${index.toString().padLeft(2, '0')}').join('\n');

List<List<String>> _mountedIdsPerSheet(EditorPaginationCoordinator coordinator) => [
      for (final sheet in coordinator.sheets.whereType<TextStationerySheet>())
        sheet.mediaAttachments.map((item) => item.id).toList(),
    ];

EditorPaginationCoordinator _open(Delta delta, List<String> attachmentIds) {
  final coordinator = EditorPaginationCoordinator(typography: _typography);
  coordinator.initializeFromDelta(
    jsonEncode(delta.toJson()),
    attachments: attachmentIds.map(_attachment).toList(),
  );
  return coordinator;
}

void main() {
  group('EditorPaginationCoordinator: mounted items follow their text', () {
    test('typing above a mounted passage until it spills moves the item to the next sheet', () {
      final coordinator = _open(
        Delta()
          ..insert(_lines('首页', 10))
          ..insert({'mount': 'a'})
          ..insert('\n'),
        ['a'],
      );
      expect(_mountedIdsPerSheet(coordinator), [
        ['a'],
      ]);
      final opening = coordinator.sheets.first as OpeningSheet;

      opening.controller.replaceText(0, 0, '新添一行\n', const TextSelection.collapsed(offset: 5));
      coordinator.checkAndPerformAutoSpill(0);

      expect(coordinator.totalSheets, 2);
      expect(_mountedIdsPerSheet(coordinator), [
        [],
        ['a'],
      ]);
      final continuation = coordinator.sheets[1] as TextStationerySheet;
      expect(continuation.plainText, contains('首页09'));
      expect(MountMarker.mediaIdsIn(continuation.delta), ['a']);
      coordinator.dispose();
    });

    test('spill-back brings the item back with its passage', () {
      final coordinator = _open(
        Delta()
          ..insert('${_lines('首页', 9)}\n')
          ..insert('次页')
          ..insert({'mount': 'a'})
          ..insert('\n'),
        ['a'],
      );
      // Force the passage onto sheet 2 by filling sheet 1, then free a row.
      final opening = coordinator.sheets.first as OpeningSheet;
      opening.controller.replaceText(0, 0, '满\n', const TextSelection.collapsed(offset: 0));
      coordinator.checkAndPerformAutoSpill(0);
      expect(_mountedIdsPerSheet(coordinator), [
        [],
        ['a'],
      ]);

      opening.controller.replaceText(0, 2, '', const TextSelection.collapsed(offset: 0));
      coordinator.handleSpillBack(1);

      final mounted = _mountedIdsPerSheet(coordinator);
      expect(mounted.first, ['a']);
      expect(mounted.skip(1).expand((ids) => ids), isEmpty);
      coordinator.dispose();
    });

    test('reflow that pushes a fourth item onto the last sheet unmounts it and reports it', () {
      final coordinator = _open(
        Delta()
          ..insert('甲')
          ..insert({'mount': 'a'})
          ..insert({'mount': 'b'})
          ..insert({'mount': 'c'})
          ..insert('\n'),
        ['a', 'b', 'c', 'd'],
      );
      final unmounted = <String>[];
      coordinator.onOverflowUnmount = (items) => unmounted.addAll(items.map((item) => item.id));
      final opening = coordinator.sheets.first as OpeningSheet;

      // A restored marker (e.g. undo of a deletion) lands a fourth item here;
      // the last one in document order no longer fits on the only sheet.
      opening.controller.replaceText(1, 0, Delta()..insert({'mount': 'd'}), null);
      coordinator.reflowMounts();

      expect(unmounted, ['c']);
      expect(_mountedIdsPerSheet(coordinator), [
        ['d', 'a', 'b'],
      ]);
      expect(coordinator.stagedItems.map((item) => item.id), ['c']);
      expect(coordinator.totalSheets, 1);
      coordinator.dispose();
    });

    test('legacy overflow present when the entry opens is never unmounted by editing', () {
      final coordinator = _open(
        Delta()
          ..insert('一页')
          ..insert({'mount': 'a'})
          ..insert({'mount': 'b'})
          ..insert({'mount': 'c'})
          ..insert({'mount': 'd'})
          ..insert('\n'),
        ['a', 'b', 'c', 'd'],
      );
      final unmounted = <SheetMediaItem>[];
      coordinator.onOverflowUnmount = unmounted.addAll;
      final opening = coordinator.sheets.first as OpeningSheet;

      opening.controller.replaceText(0, 0, '续写', const TextSelection.collapsed(offset: 2));
      coordinator.reflowMounts();

      expect(unmounted, isEmpty);
      expect(coordinator.stagedItems, isEmpty);
      expect(_mountedIdsPerSheet(coordinator), [
        ['a', 'b', 'c', 'd'],
      ]);
      coordinator.dispose();
    });

    test('deleting a passage holding a marker unmounts the item; undo remounts it; redo unmounts again', () {
      final coordinator = _open(
        Delta()
          ..insert('留')
          ..insert('删去此句')
          ..insert({'mount': 'a'})
          ..insert('\n'),
        ['a'],
      );
      final opening = coordinator.sheets.first as OpeningSheet;

      opening.controller.replaceText(1, 5, '', const TextSelection.collapsed(offset: 1));
      coordinator.reflowMounts();
      expect(_mountedIdsPerSheet(coordinator), [[]]);
      expect(coordinator.stagedItems.map((item) => item.id), ['a']);

      opening.controller.undo();
      coordinator.reflowMounts();
      expect(_mountedIdsPerSheet(coordinator), [
        ['a'],
      ]);
      expect(coordinator.stagedItems, isEmpty);

      opening.controller.redo();
      coordinator.reflowMounts();
      expect(coordinator.stagedItems.map((item) => item.id), ['a']);
      coordinator.dispose();
    });

    test('IME composition defers mount reflow during edit and reflows mounts upon IME commit notification', () async {
      final coordinator = _open(
        Delta()
          ..insert('留')
          ..insert('删去此句')
          ..insert({'mount': 'a'})
          ..insert('\n'),
        ['a'],
      );
      final opening = coordinator.sheets.first as OpeningSheet;

      coordinator.isImeComposing = true;
      opening.controller.replaceText(1, 5, '', const TextSelection.collapsed(offset: 1));
      await Future<void>.delayed(Duration.zero);

      // While IME composition is active, mount reflow is deferred.
      expect(_mountedIdsPerSheet(coordinator), [
        ['a'],
      ]);
      expect(coordinator.stagedItems, isEmpty);

      // Once IME composition commits and the controller notifies, mounts reflow without needing Auto-Spill.
      coordinator.isImeComposing = false;
      opening.controller.updateSelection(
        const TextSelection.collapsed(offset: 1),
        ChangeSource.local,
      );

      expect(_mountedIdsPerSheet(coordinator), [[]]);
      expect(coordinator.stagedItems.map((item) => item.id), ['a']);
      coordinator.dispose();
    });

    test('saving strips markers that reference a missing attachment and keeps markers out of plain text', () {
      final coordinator = _open(
        Delta()
          ..insert('秋水')
          ..insert({'mount': 'a'})
          ..insert({'mount': 'ghost'})
          ..insert('长天\n'),
        ['a'],
      );

      final (deltaJson, plainText) = coordinator.reSynthesize();

      expect(MountMarker.mediaIdsIn(Delta.fromJson(jsonDecode(deltaJson) as List)), ['a']);
      expect(plainText, '秋水长天');
      coordinator.dispose();
    });
  });

  group('Mount markers on the clipboard', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      final clipboard = <String, dynamic>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard['text'] = (call.arguments as Map)['text'];
        } else if (call.method == 'Clipboard.getData') {
          return {'text': clipboard['text']};
        } else if (call.method == 'Clipboard.hasStrings') {
          return {'value': clipboard['text'] != null};
        }
        return null;
      });
    });

    test('copying and pasting text containing a marker pastes no marker', () async {
      final coordinator = _open(
        Delta()
          ..insert('落花')
          ..insert({'mount': 'a'})
          ..insert('流水\n'),
        ['a'],
      );
      final opening = coordinator.sheets.first as OpeningSheet;
      final controller = opening.controller;

      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        ChangeSource.local,
      );
      controller.clipboardSelection(true);
      controller.updateSelection(const TextSelection.collapsed(offset: 5), ChangeSource.local);
      await controller.clipboardPaste();
      coordinator.reflowMounts();

      expect(opening.plainText, '落花￼流水落花流水\n');
      expect(MountMarker.mediaIdsIn(opening.delta), ['a']);
      expect(_mountedIdsPerSheet(coordinator), [
        ['a'],
      ]);
      coordinator.dispose();
    });

    test('typing empty rows after text with mount marker retains marker on source sheet', () {
      final coordinator = _open(
        Delta()
          ..insert('我的日记')
          ..insert({'mount': 'a'})
          ..insert('\n'),
        ['a'],
      );
      final opening = coordinator.sheets.first as OpeningSheet;
      final controller = opening.controller;

      for (int i = 0; i < 15; i++) {
        final len = controller.document.length;
        controller.replaceText(len - 1, 0, '\n', TextSelection.collapsed(offset: len));
        coordinator.checkAndPerformAutoSpill(0);
      }

      expect(_mountedIdsPerSheet(coordinator)[0], ['a']);
      coordinator.dispose();
    });

    test('mounting after typing empty rows retains marker on sheet 1 when more empty rows spill', () {
      final coordinator = _open(
        Delta()
          ..insert('我的日记\n\n\n\n\n\n\n\n\n\n'),
        ['a'],
      );
      coordinator.mountOnActiveSheet('a');

      final opening = coordinator.sheets.first as OpeningSheet;
      final controller = opening.controller;
      for (int i = 0; i < 15; i++) {
        final len = controller.document.length;
        controller.replaceText(len - 1, 0, '\n', TextSelection.collapsed(offset: len));
        coordinator.checkAndPerformAutoSpill(0);
      }

      expect(_mountedIdsPerSheet(coordinator)[0], ['a']);
      coordinator.dispose();
    });

    test('completely empty sheet 1, mount photo, typing empty rows retains marker on sheet 1', () {
      final coordinator = _open(
        Delta()..insert('\n'),
        ['a'],
      );
      coordinator.mountOnActiveSheet('a');

      final opening = coordinator.sheets.first as OpeningSheet;
      final controller = opening.controller;
      for (int i = 0; i < 15; i++) {
        final len = controller.document.length;
        controller.replaceText(len - 1, 0, '\n', TextSelection.collapsed(offset: len));
        coordinator.checkAndPerformAutoSpill(0);
      }

      expect(_mountedIdsPerSheet(coordinator)[0], ['a']);
      coordinator.dispose();
    });

    test('mount photo on empty sheet 1, press enter at offset 0 retains marker on sheet 1', () {
      final coordinator = _open(
        Delta()..insert('\n'),
        ['a'],
      );
      coordinator.mountOnActiveSheet('a');
      final opening = coordinator.sheets.first as OpeningSheet;
      final controller = opening.controller;
      for (int i = 0; i < 15; i++) {
        controller.replaceText(0, 0, '\n', const TextSelection.collapsed(offset: 1));
        coordinator.checkAndPerformAutoSpill(0);
      }

      expect(_mountedIdsPerSheet(coordinator)[0], ['a']);
      coordinator.dispose();
    });

    test('mount photo on empty sheet 2, typing empty rows retains marker on sheet 2', () {
      final coordinator = _open(
        Delta()..insert('Title\n'),
        ['a'],
      );
      coordinator.getOrCreateFollowingTextSheet(0);
      coordinator.activeSheetIndex = 1;
      coordinator.mountOnActiveSheet('a');

      final sheet2 = coordinator.sheets[1] as TextStationerySheet;
      for (int i = 0; i < 20; i++) {
        final cur = sheet2.controller.selection.baseOffset;
        final off = cur >= 0 ? cur : sheet2.document.length - 1;
        sheet2.controller.replaceText(off, 0, '\n', TextSelection.collapsed(offset: off + 1));
        coordinator.checkAndPerformAutoSpill(1);
      }

      expect(_mountedIdsPerSheet(coordinator)[1], ['a']);
      coordinator.dispose();
    });

    test('spill-back on a text-empty continuation sheet with Tucked Prints collapses the sheet and returns prints to the Staging Handscroll in collect order', () {
      final coordinator = _open(
        Delta()..insert('${_lines('首页', 10)}\n'),
        ['a', 'b', 'c'],
      );
      coordinator.getOrCreateFollowingTextSheet(0);
      coordinator.activeSheetIndex = 1;
      coordinator.mountOnActiveSheet('b');
      expect(coordinator.totalSheets, 2);
      expect(_mountedIdsPerSheet(coordinator), [
        [],
        ['b'],
      ]);
      expect(coordinator.stagedItems.map((item) => item.id), ['a', 'c']);

      final opening = coordinator.sheets.first as OpeningSheet;
      final expectedCaretOffset = opening.document.length - 1;

      final result = coordinator.handleSpillBack(1);

      expect(result, isNotNull);
      expect(result!.didCollapse, isTrue);
      expect(result.destinationSheetIndex, 0);
      expect(result.destinationCaretOffset, expectedCaretOffset);
      expect(coordinator.totalSheets, 1);
      expect(coordinator.activeSheetIndex, 0);
      expect(opening.controller.selection.baseOffset, expectedCaretOffset);
      expect(_mountedIdsPerSheet(coordinator), [[]]);
      expect(coordinator.stagedItems.map((item) => item.id), ['a', 'b', 'c']);
      coordinator.dispose();
    });
  });
}
