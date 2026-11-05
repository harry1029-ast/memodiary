import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/timeline/services/folio_media_pairing.dart';

void main() {
  final createdAt = DateTime(2026, 11, 6);

  MediaAttachment photo(String id) => MediaAttachment(
        id: id,
        entryId: 'entry-1',
        mediaType: 'image',
        relativePath: 'media/$id.webp',
        createdAt: createdAt,
      );

  FolioMountPlan planOf(List<List<String>> sheetMounts) => FolioMountPlan([
        for (final mounts in sheetMounts)
          FolioSheetSection(
            isText: true,
            deltaOps: const [],
            mounted: [for (final id in mounts) photo(id)],
          ),
      ]);

  List<List<String>> idsByLeaf(FolioMountPlan plan, int leafCount) => [
        for (final leaf in plan.mountsByLeaf(leafCount))
          [for (final attachment in leaf) attachment.id],
      ];

  group('FolioMountPlan.mountsByLeaf', () {
    test('sheet N rides on leaf N when there are enough leaves', () {
      final plan = planOf([
        ['a'],
        ['b', 'c'],
        [],
      ]);

      expect(idsByLeaf(plan, 3), [
        ['a'],
        ['b', 'c'],
        [],
      ]);
    });

    test('sheets past the last leaf fold onto it up to three items', () {
      final plan = planOf([
        [],
        ['a'],
        ['b', 'c'],
      ]);

      expect(idsByLeaf(plan, 2), [
        [],
        ['a', 'b', 'c'],
      ]);
    });

    test('overflow past three goes to the nearest earlier leaf with room', () {
      final plan = planOf([
        ['a'],
        ['b', 'c', 'd'],
        ['e', 'f', 'g'],
        ['h'],
      ]);

      expect(idsByLeaf(plan, 3), [
        ['a', 'h'],
        ['b', 'c', 'd'],
        ['e', 'f', 'g'],
      ]);
    });

    test('a legacy sheet holding more than three spills onto later leaves when earlier ones are full', () {
      final plan = planOf([
        ['a', 'b', 'c', 'd', 'e'],
        [],
      ]);

      expect(idsByLeaf(plan, 2), [
        ['a', 'b', 'c'],
        ['d', 'e'],
      ]);
    });

    test('no leaf ever shows more than three items, even without room anywhere', () {
      final plan = planOf([
        ['a', 'b', 'c'],
        ['d', 'e', 'f'],
      ]);

      expect(idsByLeaf(plan, 1), [
        ['a', 'b', 'c'],
      ]);
    });

    test('no leaves means no mounts', () {
      expect(planOf([['a']]).mountsByLeaf(0), isEmpty);
    });
  });
}
