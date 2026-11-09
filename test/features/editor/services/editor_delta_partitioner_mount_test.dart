import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/models/mount_marker.dart';
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

extension on Delta {
  void insertMarkers(Iterable<String> mediaIds) {
    for (final mediaId in mediaIds) {
      insert({'mount': mediaId});
    }
  }
}

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

  group('EditorDeltaPartitioner mount overflow and reflow', () {

    List<List<String>> mountedIdsPerSheet(List<StationerySheetDescriptor> sheets) => [
          for (final sheet in sheets.whereType<TextStationerySheet>())
            sheet.mediaAttachments.map((item) => item.id).toList(),
        ];

    test('more than three markers on a sheet cascade the extras onto the following text sheet', () {
      final media = [for (final id in ['a', 'b', 'c', 'd', 'e', 'f']) _photo(id)];
      final delta = Delta()
        ..insert(_lines('首页', 10))
        ..insertMarkers(['a', 'b', 'c', 'd', 'e'])
        ..insert('\n')
        ..insert('次页')
        ..insert({'mount': 'f'})
        ..insert('\n')
        ..insert('${_lines('三页', 14)}\n');

      final result = _partition(delta, media);

      expect(result.sheets.whereType<TextStationerySheet>(), hasLength(3));
      expect(mountedIdsPerSheet(result.sheets), [
        ['a', 'b', 'c'],
        ['d', 'e', 'f'],
        [],
      ]);
      expect(result.stagedItems, isEmpty);
    });

    test('opening an entry never unmounts: extras beyond the last sheet stay there, tolerated', () {
      final media = [for (final id in ['a', 'b', 'c', 'd', 'e']) _photo(id)];
      final delta = Delta()
        ..insert('一页')
        ..insertMarkers(['a', 'b', 'c', 'd', 'e'])
        ..insert('\n');

      final result = _partition(delta, media);

      expect(mountedIdsPerSheet(result.sheets), [
        ['a', 'b', 'c', 'd', 'e'],
      ]);
      expect(result.stagedItems, isEmpty);
      expect(result.toleratedOverflowIds, {'d', 'e'});
    });

    test('reflow overflow at the last sheet unmounts the extras and removes their markers', () {
      final media = [for (final id in ['a', 'b', 'c', 'd', 'e']) _photo(id)];
      final sheets = _partition(
        Delta()
          ..insert('一页')
          ..insertMarkers(['a', 'b', 'c', 'd', 'e'])
          ..insert('\n'),
        media,
      ).sheets;

      final resolution = SheetMountResolver.resolveMounts(
        sheets: sheets,
        media: media,
        unmountLastSheetOverflow: true,
      );

      expect(mountedIdsPerSheet(sheets), [
        ['a', 'b', 'c'],
      ]);
      expect(resolution.unmountedByOverflow.map((item) => item.id), ['d', 'e']);
      expect(resolution.stagedItems.map((item) => item.id), ['d', 'e']);
      expect(
        (sheets.single as TextStationerySheet).delta.toJson(),
        (Delta()
              ..insert('一页')
              ..insertMarkers(['a', 'b', 'c'])
              ..insert('\n'))
            .toJson(),
      );
      expect(sheets, hasLength(1), reason: 'no media-only sheet is allocated');
    });

    test('tolerated legacy overflow stays on the last sheet while reflow unmounts only new extras', () {
      final media = [for (final id in ['a', 'b', 'c', 'd', 'e']) _photo(id)];
      final sheets = _partition(
        Delta()
          ..insert('一页')
          ..insertMarkers(['a', 'b', 'c', 'd', 'e'])
          ..insert('\n'),
        media,
      ).sheets;

      final resolution = SheetMountResolver.resolveMounts(
        sheets: sheets,
        media: media,
        unmountLastSheetOverflow: true,
        toleratedOverflowIds: const {'e'},
      );

      expect(mountedIdsPerSheet(sheets), [
        ['a', 'b', 'c', 'e'],
      ]);
      expect(resolution.unmountedByOverflow.map((item) => item.id), ['d']);
      expect(resolution.toleratedOverflowIds, {'e'});
    });

    test('a deleted marker leaves its item staged; undo restores the marker and remounts it', () {
      final media = [_photo('a'), _photo('b')];
      final sheets = _partition(
        Delta()
          ..insert('春')
          ..insert({'mount': 'a'})
          ..insert('夏')
          ..insert({'mount': 'b'})
          ..insert('\n'),
        media,
      ).sheets;
      final sheet = sheets.single as TextStationerySheet;

      sheet.controller.replaceText(0, 2, '', const TextSelection.collapsed(offset: 0));
      final afterDelete = SheetMountResolver.resolveMounts(sheets: sheets, media: media);
      expect(mountedIdsPerSheet(sheets), [
        ['b'],
      ]);
      expect(afterDelete.stagedItems.map((item) => item.id), ['a']);

      sheet.controller.undo();
      final afterUndo = SheetMountResolver.resolveMounts(sheets: sheets, media: media);
      expect(mountedIdsPerSheet(sheets), [
        ['a', 'b'],
      ]);
      expect(afterUndo.stagedItems, isEmpty);
    });

    test('a duplicated marker is removed, keeping the occurrence on the sheet that already held it', () {
      final media = [_photo('a')];
      final sheets = _partition(
        Delta()
          ..insert('${_lines('首页', 10)}\n')
          ..insert('次页')
          ..insert({'mount': 'a'})
          ..insert('\n'),
        media,
      ).sheets;
      final opening = sheets[0] as TextStationerySheet;
      final continuation = sheets[1] as TextStationerySheet;

      opening.controller.replaceText(0, 0, Delta()..insert({'mount': 'a'}), null);
      SheetMountResolver.resolveMounts(
        sheets: sheets,
        media: media,
        previousMarkerHomes: {'a': continuation.controller},
      );

      expect(mountedIdsPerSheet(sheets), [
        [],
        ['a'],
      ]);
      expect(MountMarker.mediaIdsIn(opening.delta), isEmpty);
      expect(MountMarker.mediaIdsIn(continuation.delta), ['a']);
    });

    test('stripOrphanMarkers removes markers referencing a missing attachment, and duplicates', () {
      final delta = Delta()
        ..insert('秋')
        ..insert({'mount': 'a'})
        ..insert({'mount': 'ghost'})
        ..insert('冬')
        ..insert({'mount': 'a'})
        ..insert('\n');

      final stripped = SheetMountResolver.stripOrphanMarkers(delta, knownMediaIds: {'a'});

      expect(
        stripped.toJson(),
        (Delta()
              ..insert('秋')
              ..insert({'mount': 'a'})
              ..insert('冬\n'))
            .toJson(),
      );
    });
  });
}
