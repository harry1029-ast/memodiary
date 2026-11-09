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
  });
}
