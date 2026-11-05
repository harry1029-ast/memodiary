import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/services/editor_delta_partitioner.dart';
import 'package:memodiary/features/templates/models/template_style.dart';

const _templateStyle = TemplateStyle(
  type: TemplateBackgroundType.lined,
  backgroundColor: Color(0xFFFBF8F1),
  lineSpacing: 1.5,
  marginHorizontal: 24.0,
);

SheetMediaItem _photo(String id) => SheetMediaItem(
      id: id,
      mediaType: EphemeraMediaType.image,
      relativePath: 'media/$id.webp',
    );

Delta _mountLegacy(Delta delta, List<SheetMediaItem> media) {
  return EditorDeltaPartitioner.mountLegacyAttachments(
    unifiedDelta: delta,
    media: media,
    typography: const TypographySettings(),
    contentWidth: 300,
    templateStyle: _templateStyle,
  );
}

EditorPartition _partition(Delta delta, List<SheetMediaItem> media) {
  return EditorDeltaPartitioner.partition(
    unifiedDelta: delta,
    media: media,
    typography: const TypographySettings(),
    contentWidth: 300,
    templateStyle: _templateStyle,
  );
}

List<List<String>> _mountedIdsPerSheet(EditorPartition partition) => [
      for (final sheet in partition.sheets.whereType<TextStationerySheet>())
        sheet.mediaAttachments.map((item) => item.id).toList(),
    ];

String _lines(String prefix, int count) =>
    List.generate(count, (index) => '$prefix$index').join('\n');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EditorDeltaPartitioner legacy mounting pass', () {
    test('mounts unanchored attachments first-come: three per sheet, in collect order', () {
      final delta = Delta()..insert('${_lines('山行', 20)}\n');
      final media = [for (final id in ['a', 'b', 'c', 'd', 'e']) _photo(id)];

      final mounted = _mountLegacy(delta, media);
      final result = _partition(mounted, media);

      expect(_mountedIdsPerSheet(result), [
        ['a', 'b', 'c'],
        ['d', 'e'],
      ]);
      expect(result.stagedItems, isEmpty);
    });

    test('is idempotent: a second pass leaves the Delta unchanged', () {
      final delta = Delta()..insert('${_lines('山行', 20)}\n');
      final media = [for (final id in ['a', 'b', 'c', 'd']) _photo(id)];

      final once = _mountLegacy(delta, media);
      final twice = _mountLegacy(once, media);

      expect(twice.toJson(), once.toJson());
    });

    test('keeps the prose intact and places markers at the end of each sheet\'s text', () {
      final delta = Delta()
        ..insert('春山', {'bold': true})
        ..insert('如笑\n');

      final mounted = _mountLegacy(delta, [_photo('a'), _photo('b')]);

      expect(mounted.toJson(), [
        {'insert': '春山', 'attributes': {'bold': true}},
        {'insert': '如笑'},
        {'insert': {'mount': 'a'}},
        {'insert': {'mount': 'b'}},
        {'insert': '\n'},
      ]);
    });

    test('an empty entry mounts its attachments at position 0 of the opening sheet', () {
      final mounted = _mountLegacy(Delta(), [_photo('a')]);

      expect(mounted.toJson(), [
        {'insert': {'mount': 'a'}},
        {'insert': '\n'},
      ]);
      expect(_partition(mounted, [_photo('a')]).stagedItems, isEmpty);
    });

    test('items beyond every sheet\'s capacity stay with the last sheet, never staged', () {
      final media = [for (final id in ['a', 'b', 'c', 'd']) _photo(id)];

      final mounted = _mountLegacy(Delta()..insert('一页\n'), media);
      final result = _partition(mounted, media);

      expect(_mountedIdsPerSheet(result), [
        ['a', 'b', 'c', 'd'],
      ]);
      expect(result.stagedItems, isEmpty);
    });

    test('legacy inline embeds and already-mounted items are left as they are', () {
      final delta = Delta()
        ..insert('前文')
        ..insert({'mount': 'a'})
        ..insert('\n')
        ..insert({'image': 'media/inline.webp'})
        ..insert('\n')
        ..insert('后文\n');
      final inline = SheetMediaItem(
        id: 'inline',
        mediaType: EphemeraMediaType.image,
        relativePath: 'media/inline.webp',
      );
      final media = [_photo('a'), inline, _photo('b')];

      final mounted = _mountLegacy(delta, media);
      final result = _partition(mounted, media);

      expect(mounted.toJson(), anyElement(equals({'insert': {'image': 'media/inline.webp'}})));
      expect(_mountedIdsPerSheet(result), [
        ['a', 'b'],
        [],
      ]);
      expect(result.stagedItems, isEmpty);
    });

    test('a sheet whose paragraph continues onto the next sheet keeps its items', () {
      final delta = Delta()..insert('${List.filled(60, '湖光山色').join()}\n');
      final media = [for (final id in ['a', 'b', 'c', 'd']) _photo(id)];

      final mounted = _mountLegacy(delta, media);
      final result = _partition(mounted, media);

      expect(result.sheets.whereType<TextStationerySheet>().length, greaterThan(1));
      expect(_mountedIdsPerSheet(result).take(2), [
        ['a', 'b', 'c'],
        ['d'],
      ]);
    });
  });
}
