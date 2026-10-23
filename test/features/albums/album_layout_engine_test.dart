import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/albums/models/album_spread.dart';
import 'package:memodiary/features/albums/services/album_layout_engine.dart';

AlbumCollection _buildCollection({
  String id = 'col-1',
  String title = '江南春行',
  String? description = '烟雨入江南，山水如墨染。',
  String? destinationTag = '江南',
  String? routeSummary,
  String? coverImagePath,
  String layoutPreset = 'magazine',
}) {
  final timestamp = DateTime(2026, 4, 10);
  return AlbumCollection(
    id: id,
    title: title,
    description: description,
    destinationTag: destinationTag,
    routeSummary: routeSummary,
    coverImagePath: coverImagePath,
    startDate: DateTime(2026, 4, 1),
    endDate: DateTime(2026, 4, 5),
    layoutPreset: layoutPreset,
    sortIndex: 0,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

AlbumPhoto _buildPhoto({
  required String id,
  required int sortOrder,
  String? caption,
  String? locationTag,
  double aspectRatio = 1.0,
}) {
  return AlbumPhoto(
    id: id,
    collectionId: 'col-1',
    relativeImagePath: 'media/$id.webp',
    relativeThumbnailPath: 'media/${id}_thumb.webp',
    caption: caption,
    locationTag: locationTag,
    shotAt: DateTime(2026, 4, 2, 10, sortOrder),
    sortOrder: sortOrder,
    aspectRatio: aspectRatio,
    createdAt: DateTime(2026, 4, 2, 10, sortOrder),
  );
}

void main() {
  group('AlbumLayoutEngine.synthesize', () {
    test('empty collection produces CoverSpread and EpilogueSpread (2 pages)',
        () {
      final collection = _buildCollection();
      final spreads = AlbumLayoutEngine.synthesize(
        collection: collection,
        photos: const [],
      );

      expect(spreads.length, 2);
      expect(spreads[0], isA<CoverSpread>());
      expect(spreads[0].pageNumber, 1);
      final cover = spreads[0] as CoverSpread;
      expect(cover.title, '江南春行');
      expect(cover.photoCount, 0);
      expect(cover.coverImagePath, isNull);

      expect(spreads[1], isA<EpilogueSpread>());
      expect(spreads[1].pageNumber, 2);
      final epilogue = spreads[1] as EpilogueSpread;
      expect(epilogue.totalPhotos, 0);
      expect(epilogue.sealText, '江南');
    });

    test('single photo collection produces Cover, SingleHero, and Epilogue',
        () {
      final collection = _buildCollection();
      final photo = _buildPhoto(
        id: 'p1',
        sortOrder: 0,
        caption: '西湖晨雾',
        locationTag: '杭州',
      );

      final spreads = AlbumLayoutEngine.synthesize(
        collection: collection,
        photos: [photo],
      );

      expect(spreads.length, 3);
      expect(spreads[0], isA<CoverSpread>());
      expect((spreads[0] as CoverSpread).coverImagePath, 'media/p1.webp');
      expect(spreads[1], isA<SingleHeroSpread>());
      expect((spreads[1] as SingleHeroSpread).photo.id, 'p1');
      expect(spreads[2], isA<EpilogueSpread>());
      expect((spreads[2] as EpilogueSpread).routeSummary, '杭州');
    });

    test('promotes extended captions (>= 60 chars) and panoramic photos to Hero',
        () {
      final collection = _buildCollection();
      final longCaption = '春雨微凉，沿着青石板路缓步前行，乌篷船摇橹声在河道间回荡，岸边垂柳依依，仿佛走进了千年前的江南水墨画卷之中，令人流连忘返。';
      expect(longCaption.length, greaterThanOrEqualTo(60));

      final photos = [
        _buildPhoto(id: 'p1', sortOrder: 0, caption: longCaption),
        _buildPhoto(
          id: 'p2',
          sortOrder: 1,
          caption: '宽幅远山',
          aspectRatio: 1.85,
        ),
      ];

      final spreads = AlbumLayoutEngine.synthesize(
        collection: collection,
        photos: photos,
      );

      expect(spreads.length, 4);
      expect(spreads[1], isA<SingleHeroSpread>());
      expect((spreads[1] as SingleHeroSpread).photo.id, 'p1');
      expect(spreads[2], isA<SingleHeroSpread>());
      expect((spreads[2] as SingleHeroSpread).photo.id, 'p2');
    });

    test('pairs portrait/square photos sideBySide and landscape photos stacked',
        () {
      final collection = _buildCollection();
      final photos = [
        _buildPhoto(
          id: 'p1',
          sortOrder: 0,
          caption: '古桥一隅，水波微澜，正是江南好风景，岸畔茶香袅袅，游人如织。', // >= 25 chars so not quad
          aspectRatio: 0.8,
        ),
        _buildPhoto(
          id: 'p2',
          sortOrder: 1,
          caption: '白墙黛瓦，曲径通幽，苔痕上阶绿，草色入帘青，静谧安然。',
          aspectRatio: 1.0,
        ),
        _buildPhoto(
          id: 'p3',
          sortOrder: 2,
          caption: '平湖秋月，远山含黛，扁舟一叶横渡烟波之上，暮色渐起。',
          aspectRatio: 1.35,
        ),
        _buildPhoto(
          id: 'p4',
          sortOrder: 3,
          caption: '渔舟唱晚，灯火初上，两岸人家炊烟袅袅升起，温暖柔和。',
          aspectRatio: 1.4,
        ),
      ];

      final spreads = AlbumLayoutEngine.synthesize(
        collection: collection,
        photos: photos,
      );

      expect(spreads.length, 4);
      expect(spreads[1], isA<DuoSpread>());
      final firstDuo = spreads[1] as DuoSpread;
      expect(firstDuo.orientation, DuoLayoutOrientation.sideBySide);
      expect(firstDuo.firstPhoto.id, 'p1');
      expect(firstDuo.secondPhoto.id, 'p2');

      expect(spreads[2], isA<DuoSpread>());
      final secondDuo = spreads[2] as DuoSpread;
      expect(secondDuo.orientation, DuoLayoutOrientation.stacked);
      expect(secondDuo.firstPhoto.id, 'p3');
      expect(secondDuo.secondPhoto.id, 'p4');
    });

    test('clusters 4 consecutive short-caption photos into QuadSpread', () {
      final collection = _buildCollection();
      final photos = [
        _buildPhoto(id: 'q1', sortOrder: 0, caption: '茶盏', locationTag: '杭州'),
        _buildPhoto(id: 'q2', sortOrder: 1, caption: '竹影', locationTag: '杭州'),
        _buildPhoto(id: 'q3', sortOrder: 2, caption: '石桥', locationTag: '乌镇'),
        _buildPhoto(id: 'q4', sortOrder: 3, caption: '花窗', locationTag: '苏州'),
      ];

      final spreads = AlbumLayoutEngine.synthesize(
        collection: collection,
        photos: photos,
      );

      expect(spreads.length, 3);
      expect(spreads[1], isA<QuadSpread>());
      final quad = spreads[1] as QuadSpread;
      expect(quad.photos.map((photo) => photo.id).toList(), [
        'q1',
        'q2',
        'q3',
        'q4',
      ]);

      final epilogue = spreads[2] as EpilogueSpread;
      expect(epilogue.routeSummary, '杭州 → 乌镇 → 苏州');
      expect(epilogue.totalLocations, 3);
      expect(epilogue.totalPhotos, 4);
    });

    test('editorial preset promotes first photo to opening SingleHeroSpread',
        () {
      final collection = _buildCollection(layoutPreset: 'editorial');
      final photos = [
        _buildPhoto(id: 'e1', sortOrder: 0, caption: '序章'),
        _buildPhoto(id: 'e2', sortOrder: 1, caption: '次章'),
        _buildPhoto(id: 'e3', sortOrder: 2, caption: '终章'),
      ];

      final spreads = AlbumLayoutEngine.synthesize(
        collection: collection,
        photos: photos,
      );

      expect(spreads.length, 4);
      expect(spreads[1], isA<SingleHeroSpread>());
      expect((spreads[1] as SingleHeroSpread).photo.id, 'e1');
      expect(spreads[2], isA<DuoSpread>());
    });
  });
}

