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

EditorPartition _partition(Delta delta, List<SheetMediaItem> media) {
  return EditorDeltaPartitioner.partition(
    unifiedDelta: delta,
    media: media,
    typography: const TypographySettings(),
    contentWidth: 300,
    templateStyle: _templateStyle,
  );
}

/// Builds a long multi-paragraph prose run that overflows the opening sheet.
String _lines(String prefix, int count) =>
    List.generate(count, (index) => '$prefix$index').join('\n');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EditorDeltaPartitioner mount markers', () {
    test('an attachment referenced by a marker is mounted on the sheet holding the marker', () {
      final delta = Delta()
        ..insert('春山如笑')
        ..insert({'mount': 'photo_a'})
        ..insert('\n');

      final result = _partition(delta, [_photo('photo_a')]);

      expect(result.sheets, hasLength(1));
      final sheet = result.sheets.single as TextStationerySheet;
      expect(sheet.mediaAttachments.map((item) => item.id), ['photo_a']);
      expect(result.stagedItems, isEmpty);
    });

    test('an attachment without a marker is staged, never mounted', () {
      final delta = Delta()..insert('夏山如滴\n');

      final result = _partition(delta, [_photo('photo_a'), _photo('photo_b')]);

      final sheet = result.sheets.single as TextStationerySheet;
      expect(sheet.mediaAttachments, isEmpty);
      expect(result.stagedItems.map((item) => item.id), ['photo_a', 'photo_b']);
    });

    test('a marker on an otherwise empty sheet mounts the item', () {
      final delta = Delta()
        ..insert({'mount': 'photo_a'})
        ..insert('\n');

      final result = _partition(delta, [_photo('photo_a')]);

      final sheet = result.sheets.single as OpeningSheet;
      expect(sheet.mediaAttachments.map((item) => item.id), ['photo_a']);
    });

    test('markers resolve to the sheet their passage lands on, in marker order', () {
      final delta = Delta()
        ..insert('${_lines('首页', 10)}\n')
        ..insert('次页开篇')
        ..insert({'mount': 'photo_b'})
        ..insert({'mount': 'photo_a'})
        ..insert('\n');

      final result = _partition(delta, [_photo('photo_a'), _photo('photo_b')]);

      expect(result.sheets, hasLength(2));
      final opening = result.sheets[0] as TextStationerySheet;
      final continuation = result.sheets[1] as TextStationerySheet;
      expect(opening.mediaAttachments, isEmpty);
      expect(continuation.mediaAttachments.map((item) => item.id), ['photo_b', 'photo_a']);
      expect(result.stagedItems, isEmpty);
    });

    test('a marker never consumes a ruled row of line capacity', () {
      final withoutMarker = Delta()..insert('${_lines('行', 10)}\n');
      final withMarker = Delta()
        ..insert(_lines('行', 10))
        ..insert({'mount': 'photo_a'})
        ..insert('\n');

      expect(_partition(withoutMarker, const []).sheets, hasLength(1));
      expect(_partition(withMarker, [_photo('photo_a')]).sheets, hasLength(1));
    });

    test('an attachment backing a legacy inline embed is neither staged nor mounted', () {
      final delta = Delta()
        ..insert('旧日游记\n')
        ..insert({'image': 'media/legacy.webp'})
        ..insert('\n');
      const legacy = SheetMediaItem(
        id: 'legacy',
        mediaType: EphemeraMediaType.image,
        relativePath: 'media/legacy.webp',
      );

      final result = _partition(delta, [legacy, _photo('photo_a')]);

      expect(result.sheets.whereType<EphemeraSheet>(), hasLength(1));
      expect(
        result.sheets.whereType<TextStationerySheet>().expand((sheet) => sheet.mediaAttachments),
        isEmpty,
      );
      expect(result.stagedItems.map((item) => item.id), ['photo_a']);
    });
  });
}
