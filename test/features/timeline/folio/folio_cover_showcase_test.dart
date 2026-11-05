import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_cover_showcase.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_frontispiece_page.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_leaf_model.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_photo_sleeve_modal.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_reading_perspective.dart';

void main() {
  const dummyAtmosphere = ShanshuiAtmosphereState(
    realm: ShanshuiRealm.nature,
    season: ShanshuiSeason.spring,
    timeOfDay: ShanshuiTimeOfDay.day,
    weather: ShanshuiWeather.sunny,
  );

  List<FolioPhotoAttachment> createMockPhotos(int count) {
    return List.generate(count, (index) {
      final pageNum = index + 1;
      return FolioPhotoAttachment(
        id: 'photo_$pageNum',
        relativePath: 'media/photo_$pageNum.webp',
        title: '西湖秋月 $pageNum',
        caption: '平湖秋月 · 荷塘微风 $pageNum',
        date: '2026.11.04 · 20:00',
        pageNumber: pageNum,
        targetLeafIndex: pageNum,
      );
    });
  }

  FolioFrontispieceCoverLeaf createMockCoverLeaf({required int photoCount}) {
    return FolioFrontispieceCoverLeaf(
      leafIndex: 0,
      totalLeaves: photoCount + 1,
      entryTitle: '断桥残雪',
      lunarDate: '丙午年孟冬廿三',
      gregorianDate: '2026.11.04',
      weather: '微雪',
      mood: 4,
      sceneryAtmosphere: dummyAtmosphere,
      photos: createMockPhotos(photoCount),
    );
  }

  Future<void> pumpCoverShowcase(
    WidgetTester tester, {
    required FolioFrontispieceCoverLeaf leaf,
    FolioSubstrateTheme theme = FolioSubstrateTheme.xuan,
    VoidCallback? onOpenSleeveModal,
    ValueChanged<FolioPhotoAttachment>? onPhotoTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FolioCoverShowcase(
            leaf: leaf,
            theme: theme,
            onOpenSleeveModal: onOpenSleeveModal,
            onPhotoTap: onPhotoTap,
          ),
        ),
      ),
    );
  }

  group('FolioCoverShowcase Adaptive Mounting Tests', () {
    testWidgets('renders Single Hero Artwork (单幅立轴画心) with brass pin for N = 1', (tester) async {
      final leaf = createMockCoverLeaf(photoCount: 1);
      await pumpCoverShowcase(tester, leaf: leaf);

      // Verify Washi Tape Label for N=1
      expect(find.text('泥金和纸胶带 · 拾光·单幅立轴画心'), findsOneWidget);

      // Verify Single Hero Mount widget and Antique Brass Pin
      expect(find.byKey(const Key('folio_cover_single_hero')), findsOneWidget);
      expect(find.byKey(const Key('folio_cover_antique_brass_pin')), findsOneWidget);
      expect(find.text('P1 · 独幅立轴'), findsOneWidget);
      expect(find.text('西湖秋月 1'), findsOneWidget);
      expect(find.text('平湖秋月 · 荷塘微风 1'), findsOneWidget);
    });

    testWidgets('renders Symmetrical Vertical Diptych (双屏对幅册页) with inner shadows for N = 2', (tester) async {
      final leaf = createMockCoverLeaf(photoCount: 2);
      await pumpCoverShowcase(tester, leaf: leaf, theme: FolioSubstrateTheme.coldGold);

      // Verify Washi Tape Label for N=2
      expect(find.text('泥金和纸胶带 · 拾光·双屏对幅册页'), findsOneWidget);

      // Verify Vertical Diptych container and two split leaves
      expect(find.byKey(const Key('folio_cover_vertical_diptych')), findsOneWidget);
      expect(find.byKey(const Key('folio_cover_diptych_p1')), findsOneWidget);
      expect(find.byKey(const Key('folio_cover_diptych_p2')), findsOneWidget);

      expect(find.text('P1 · 上卷'), findsOneWidget);
      expect(find.text('P2 · 下卷'), findsOneWidget);
      expect(find.text('西湖秋月 1'), findsOneWidget);
      expect(find.text('西湖秋月 2'), findsOneWidget);

      // Verify compact sleeve bar for N=2
      expect(find.text('🗂️ 拾光画匣 · 已收录 2 帧随文影札'), findsOneWidget);
    });

    testWidgets('renders Asymmetrical Album Collage (三景斗方拼贴) for N = 3', (tester) async {
      final leaf = createMockCoverLeaf(photoCount: 3);
      await pumpCoverShowcase(tester, leaf: leaf, theme: FolioSubstrateTheme.obsidian);

      // Verify Washi Tape Label for N=3
      expect(find.text('泥金和纸胶带 · 拾光·三景斗方册页'), findsOneWidget);

      // Verify Asymmetrical Collage container and 3 leaves
      expect(find.byKey(const Key('folio_cover_asymmetrical_collage')), findsOneWidget);
      expect(find.byKey(const Key('folio_cover_collage_hero')), findsOneWidget);
      expect(find.byKey(const Key('folio_cover_collage_p2')), findsOneWidget);
      expect(find.byKey(const Key('folio_cover_collage_p3')), findsOneWidget);

      expect(find.text('P1 · 首卷主景'), findsOneWidget);
      expect(find.text('P2 · 次卷'), findsOneWidget);
      expect(find.text('P3 · 终卷'), findsOneWidget);

      // Verify compact sleeve bar for N=3
      expect(find.text('🗂️ 拾光画匣 · 已收录 3 帧随文影札'), findsOneWidget);
    });

    testWidgets('renders Hero Artwork + Stationery Pocket Sleeve (*集锦匣*) for N >= 4', (tester) async {
      final leaf = createMockCoverLeaf(photoCount: 4);
      await pumpCoverShowcase(tester, leaf: leaf);

      // Verify Washi Tape Label for N>=4
      expect(find.text('泥金和纸胶带 · 拾光·主景与藏影集锦匣'), findsOneWidget);

      // Verify Pocket Sleeve layout
      expect(find.byKey(const Key('folio_cover_pocket_sleeve_layout')), findsOneWidget);
      expect(find.byKey(const Key('folio_cover_pocket_hero')), findsOneWidget);
      expect(find.text('P1 · 卷首主景画心'), findsOneWidget);

      // Verify Brocade Pocket Sleeve Container
      expect(find.byKey(const Key('folio_cover_pocket_sleeve_container')), findsOneWidget);
      expect(find.text('集锦匣'), findsOneWidget);
      expect(find.text('📷 拾光画匣 · 已收录 4 枚随文影札'), findsOneWidget);
      expect(find.text('开启画匣总览 ➔'), findsOneWidget);

      // Verify fanned miniature slips inside the sleeve
      expect(find.text('P1'), findsOneWidget);
      expect(find.text('P2'), findsOneWidget);
      expect(find.text('P3'), findsOneWidget);
      expect(find.text('P4'), findsOneWidget);
    });

    testWidgets('invokes onOpenSleeveModal when tapping pocket sleeve container', (tester) async {
      bool modalOpened = false;
      final leaf = createMockCoverLeaf(photoCount: 4);
      await pumpCoverShowcase(tester, leaf: leaf, onOpenSleeveModal: () => modalOpened = true);

      await tester.tap(find.byKey(const Key('folio_cover_pocket_sleeve_container')));
      await tester.pumpAndSettle();

      expect(modalOpened, isTrue);
    });

    testWidgets('invokes onPhotoTap callback when photo tile is tapped', (tester) async {
      FolioPhotoAttachment? tappedPhoto;
      final leaf = createMockCoverLeaf(photoCount: 1);
      await pumpCoverShowcase(tester, leaf: leaf, onPhotoTap: (photo) => tappedPhoto = photo);

      await tester.tap(find.byKey(const Key('folio_cover_single_hero')));
      await tester.pumpAndSettle();

      expect(tappedPhoto, isNotNull);
      expect(tappedPhoto!.pageNumber, equals(1));
      expect(tappedPhoto!.title, equals('西湖秋月 1'));
    });
  });

  group('FolioPhotoSleeveModal Overview Modal Tests', () {
    testWidgets('renders all attached photos with capture dates and captions', (tester) async {
      final photos = createMockPhotos(4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    FolioPhotoSleeveModal.show(
                      context: context,
                      entryTitle: '断桥残雪',
                      photos: photos,
                      theme: FolioSubstrateTheme.xuan,
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('🗂️ 拾光集锦匣 · 《断桥残雪》随文影札总览'), findsOneWidget);
      expect(find.text('共收录 4 帧影札 · 点击可展读大图或跳至对应正文页'), findsOneWidget);

      // Verify all 4 cards rendered in grid with title and date
      expect(find.text('P1 · 西湖秋月 1'), findsOneWidget);
      expect(find.text('P2 · 西湖秋月 2'), findsOneWidget);
      expect(find.text('P3 · 西湖秋月 3'), findsOneWidget);
      expect(find.text('P4 · 西湖秋月 4'), findsOneWidget);
      expect(find.text('2026.11.04 · 20:00'), findsNWidgets(4));

      // Verify lightbox and jump actions exist
      expect(find.byKey(const Key('folio_sleeve_lightbox_1')), findsOneWidget);
      expect(find.byKey(const Key('folio_sleeve_jump_1')), findsOneWidget);

      // Close modal
      await tester.tap(find.byKey(const Key('folio_sleeve_modal_close_button')));
      await tester.pumpAndSettle();
      expect(find.text('🗂️ 拾光集锦匣 · 《断桥残雪》随文影札总览'), findsNothing);
    });

    testWidgets('navigates to target page when Jump button is tapped in modal', (tester) async {
      final photos = createMockPhotos(3);
      int? jumpedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    FolioPhotoSleeveModal.show(
                      context: context,
                      entryTitle: '断桥残雪',
                      photos: photos,
                      theme: FolioSubstrateTheme.xuan,
                      onJumpToPage: (targetIndex) => jumpedIndex = targetIndex,
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Tap jump button for Photo 2 (which has targetLeafIndex = 2)
      await tester.tap(find.byKey(const Key('folio_sleeve_jump_2')));
      await tester.pumpAndSettle();

      expect(jumpedIndex, equals(2));
      // Modal should be closed
      expect(find.text('🗂️ 拾光集锦匣 · 《断桥残雪》随文影札总览'), findsNothing);
    });
  });

  group('FolioFrontispiecePage Adaptive Integration Tests', () {
    testWidgets('adapts title banner badge according to photo count N', (tester) async {
      for (final (count, expectedBadge) in [
        (1, '单幅画心 · 1帧'),
        (2, '双屏对幅 · 2帧'),
        (3, '三景册页 · 3帧'),
        (4, '集锦画匣 · 4帧'),
      ]) {
        final leaf = createMockCoverLeaf(photoCount: count);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FolioFrontispiecePage(
                leaf: leaf,
                theme: FolioSubstrateTheme.xuan,
              ),
            ),
          ),
        );

        expect(find.text(expectedBadge), findsOneWidget);
      }
    });

    testWidgets('tapping title banner badge opens photo sleeve modal', (tester) async {
      final leaf = createMockCoverLeaf(photoCount: 4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FolioFrontispiecePage(
              leaf: leaf,
              theme: FolioSubstrateTheme.xuan,
            ),
          ),
        ),
      );

      // Tap the adaptive badge in title banner
      await tester.tap(find.text('集锦画匣 · 4帧'));
      await tester.pumpAndSettle();

      expect(find.text('🗂️ 拾光集锦匣 · 《断桥残雪》随文影札总览'), findsOneWidget);
    });
  });
}
