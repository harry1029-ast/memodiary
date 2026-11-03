import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_cinnabar_seal_widget.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_content_leaf_page.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_frontispiece_page.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_leaf_model.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_reading_perspective.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_shanshui_art_painter.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_silk_ruling_painter.dart';

void main() {
  const dummyAtmosphere = ShanshuiAtmosphereState(
    realm: ShanshuiRealm.nature,
    season: ShanshuiSeason.spring,
    timeOfDay: ShanshuiTimeOfDay.day,
    weather: ShanshuiWeather.sunny,
  );

  group('FolioSilkRulingPainter Canvas Tests', () {
    test('paints vermilion vertical columns and double outer border', () {
      final painter = FolioSilkRulingPainter(
        layout: FolioRulingLayout.vermilionVertical,
        ruleColor: const Color(0xFFB83B2E),
        frameColor: const Color(0xFFB83B2E),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(320, 448));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('paints genko manuscript grid and fishtail mark', () {
      final painter = FolioSilkRulingPainter(
        layout: FolioRulingLayout.genkoVertical,
        ruleColor: const Color(0xFFB83B2E),
        frameColor: const Color(0xFFB83B2E),
        showFishtail: true,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(320, 448));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('paints horizontal rules with left red margin rule', () {
      final painter = FolioSilkRulingPainter(
        layout: FolioRulingLayout.faithfulHorizontal,
        ruleColor: const Color(0xFF70675E),
        frameColor: const Color(0xFFB83B2E),
        isDark: false,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(320, 448));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('FolioShanshuiArtPainter Canvas Tests', () {
    test('paints procedural artwork across all 3 realms and dark theme', () {
      for (final realm in ShanshuiRealm.values) {
        for (final isDark in [false, true]) {
          final painter = FolioShanshuiArtPainter(
            realm: realm,
            isDark: isDark,
            atmosphere: dummyAtmosphere.copyWith(realm: realm),
          );

          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          painter.paint(canvas, const Size(280, 200));
          final picture = recorder.endRecording();
          expect(picture, isNotNull);
        }
      }
    });
  });

  group('FolioCinnabarSealWidget Widget Tests', () {
    testWidgets('renders 4 characters and restamps on tap', (tester) async {
      bool stampedFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FolioCinnabarSealWidget(
                sealText: '拾光',
                theme: FolioSubstrateTheme.xuan,
                sealStyle: SealCarvingStyle.zhuwen,
                onStamped: () {
                  stampedFired = true;
                },
              ),
            ),
          ),
        ),
      );

      // Padded to 4 characters: 拾, 光, 印, 印
      expect(find.text('拾'), findsOneWidget);
      expect(find.text('光'), findsOneWidget);
      expect(find.text('印'), findsNWidgets(2));
      expect(find.byKey(const Key('folio_seal_stamp')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(stampedFired, isTrue);

      // Tap restamps
      stampedFired = false;
      await tester.tap(find.byKey(const Key('folio_seal_stamp')));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(stampedFired, isTrue);
    });

    testWidgets('renders Baiwen carving style with solid background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FolioCinnabarSealWidget(
                sealText: '松烟夜墨',
                theme: FolioSubstrateTheme.obsidian,
                sealStyle: SealCarvingStyle.baiwen,
                animateOnMount: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('松'), findsOneWidget);
      expect(find.text('烟'), findsOneWidget);
      expect(find.text('夜'), findsOneWidget);
      expect(find.text('墨'), findsOneWidget);
    });
  });

  group('FolioFrontispiecePage Widget Tests', () {
    testWidgets('renders procedural artwork when heroPhotoPath is null', (tester) async {
      const coverLeaf = FolioFrontispieceCoverLeaf(
        leafIndex: 0,
        totalLeaves: 3,
        entryTitle: '山中雨歇',
        lunarDate: '甲辰年二月十六',
        gregorianDate: '2026.03.25',
        weather: '雨过天晴',
        mood: 4,
        isWeeklyReview: false,
        sceneryAtmosphere: dummyAtmosphere,
        openingReflection: '竹窗听雨，泥炉温茶，忽见远山出岫。',
      );

      bool forwardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FolioFrontispiecePage(
              leaf: coverLeaf,
              theme: FolioSubstrateTheme.xuan,
              onTurnForward: () {
                forwardTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('山中雨歇'), findsOneWidget);
      expect(find.text('甲辰年二月十六'), findsOneWidget);
      expect(find.text('2026.03.25'), findsOneWidget);
      expect(find.text('雨过天晴'), findsOneWidget);
      expect(find.text('愉快'), findsOneWidget);
      expect(find.text('竹窗听雨，泥炉温茶，忽见远山出岫。'), findsOneWidget);
      expect(find.text('泥金和纸胶带 · 拾光·珍藏拓影'), findsOneWidget);
      expect(find.text('轻翻展读正文 ⇢'), findsOneWidget);

      await tester.tap(find.text('轻翻展读正文 ⇢'));
      expect(forwardTapped, isTrue);
    });

    testWidgets('renders weekly review badge and zero-word draft placeholder', (tester) async {
      const zeroWordLeaf = FolioFrontispieceCoverLeaf(
        leafIndex: 0,
        totalLeaves: 1,
        entryTitle: '第12周工作与生活复盘',
        lunarDate: '甲辰年二月廿二',
        gregorianDate: '2026.03.31',
        isWeeklyReview: true,
        weekNumber: 12,
        isZeroWordDraft: true,
        sceneryAtmosphere: dummyAtmosphere,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FolioFrontispiecePage(
              leaf: zeroWordLeaf,
              theme: FolioSubstrateTheme.coldGold,
            ),
          ),
        ),
      );

      expect(find.text('第12周工作与生活复盘'), findsOneWidget);
      expect(find.text('周报 · 第12周'), findsOneWidget);
      expect(find.text('「此卷留白，静待泼墨」'), findsOneWidget);
      expect(find.text('卷末 · 静候落笔'), findsOneWidget);
    });

    testWidgets('gracefully renders hero image when heroPhotoPath is provided', (tester) async {
      const coverWithPhoto = FolioFrontispieceCoverLeaf(
        leafIndex: 0,
        totalLeaves: 2,
        entryTitle: '故宫初雪',
        lunarDate: '甲辰年腊月廿五',
        gregorianDate: '2026.01.15',
        heroPhotoPath: '/tmp/non_existent_hero_photo.jpg',
        sceneryAtmosphere: dummyAtmosphere,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FolioFrontispiecePage(
              leaf: coverWithPhoto,
              theme: FolioSubstrateTheme.obsidian,
            ),
          ),
        ),
      );

      expect(find.text('故宫初雪'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('FolioContentLeafPage Widget Tests', () {
    testWidgets('renders horizontal body leaf with jiazhu notes and todos', (tester) async {
      final bodyLeaf = FolioContentBodyLeaf(
        leafIndex: 1,
        totalLeaves: 3,
        pageIndexInContent: 1,
        totalContentPages: 2,
        layout: FolioRulingLayout.faithfulHorizontal,
        title: '西湖记游',
        lunarDate: '甲辰年三月初三',
        horizontalRows: [
          const FolioHorizontalRow(
            segments: [
              FolioHorizontalSegment(text: '苏堤春晓，'),
              FolioHorizontalSegment(text: '六桥烟柳', isJiazhuNote: true),
              FolioHorizontalSegment(text: '游人如织。', isBold: true),
            ],
          ),
          const FolioHorizontalRow(
            segments: [
              FolioHorizontalSegment(text: '品龙井茶', isTodo: true, isChecked: true),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FolioContentLeafPage(
              leaf: bodyLeaf,
              theme: FolioSubstrateTheme.xuan,
            ),
          ),
        ),
      );

      expect(find.text('《西湖记游》 · 第 2 页'), findsOneWidget);
      expect(find.text('乌丝栏 · 横排'), findsOneWidget);
      expect(find.text('六桥烟柳'), findsOneWidget);
      expect(find.textContaining('苏堤春晓'), findsOneWidget);
    });

    testWidgets('renders vertical columns with dual-char jiazhu and rotated marks', (tester) async {
      final verticalLeaf = FolioContentBodyLeaf(
        leafIndex: 2,
        totalLeaves: 3,
        pageIndexInContent: 2,
        totalContentPages: 2,
        layout: FolioRulingLayout.vermilionVertical,
        title: '兰亭序录',
        lunarDate: '甲辰年三月初三',
        sealText: '右军真迹',
        sealStyle: SealCarvingStyle.zhuwen,
        isConcludingLeaf: true,
        verticalColumns: [
          const FolioVerticalColumn(
            cells: [
              FolioVerticalCell(mainChar: '永'),
              FolioVerticalCell(mainChar: '和'),
              FolioVerticalCell(mainChar: '岁', secondChar: '在', isJiazhuPair: true),
              FolioVerticalCell(mainChar: '—', requiresQuarterTurnRotation: true),
              FolioVerticalCell(mainChar: '。', isCornerPunctuation: true),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FolioContentLeafPage(
              leaf: verticalLeaf,
              theme: FolioSubstrateTheme.coldGold,
            ),
          ),
        ),
      );

      expect(find.text('《兰亭序录》 · 第 3 页'), findsOneWidget);
      expect(find.text('朱丝栏 · 竖排'), findsOneWidget);
      expect(find.text('永'), findsOneWidget);
      expect(find.text('和'), findsOneWidget);
      expect(find.text('岁'), findsOneWidget);
      expect(find.text('在'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('。'), findsOneWidget);

      // Concluding seal should be present
      expect(find.byType(FolioCinnabarSealWidget), findsOneWidget);
      expect(find.text('右'), findsOneWidget);
      expect(find.text('军'), findsOneWidget);
      expect(find.text('真'), findsOneWidget);
      expect(find.text('迹'), findsOneWidget);
    });

    testWidgets('renders tipped-in ephemera leaf with photo and video indicators', (tester) async {
      const ephemeraPhoto = FolioTippedInEphemeraLeaf(
        leafIndex: 1,
        totalLeaves: 3,
        mediaType: 'image',
        sandboxedRelativePath: '/tmp/sandboxed_photo.jpg',
        caption: '晨曦中的断桥残雪',
        title: '西湖记游',
        lunarDate: '甲辰年三月初三',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FolioContentLeafPage(
              leaf: ephemeraPhoto,
              theme: FolioSubstrateTheme.xuan,
            ),
          ),
        ),
      );

      expect(find.text('晨曦中的断桥残雪'), findsOneWidget);
      expect(find.text('珍藏拓影 · 插页'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      // Ephemera Video
      const ephemeraVideo = FolioTippedInEphemeraLeaf(
        leafIndex: 2,
        totalLeaves: 3,
        mediaType: 'video',
        sandboxedRelativePath: '/tmp/sandboxed_video.mp4',
        caption: '南屏晚钟实录',
        title: '西湖记游',
        lunarDate: '甲辰年三月初三',
        isConcludingLeaf: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FolioContentLeafPage(
              leaf: ephemeraVideo,
              theme: FolioSubstrateTheme.obsidian,
            ),
          ),
        ),
      );

      expect(find.text('南屏晚钟实录'), findsOneWidget);
      expect(find.text('动态拓片 · 影印'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byType(FolioCinnabarSealWidget), findsOneWidget);
    });

    testWidgets('triggers turn callbacks on footer navigation buttons', (tester) async {
      bool backwardFired = false;
      bool forwardFired = false;

      final leaf = FolioContentBodyLeaf(
        leafIndex: 1,
        totalLeaves: 3,
        pageIndexInContent: 1,
        totalContentPages: 2,
        layout: FolioRulingLayout.faithfulHorizontal,
        title: '游记',
        lunarDate: '甲辰年三月初三',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FolioContentLeafPage(
              leaf: leaf,
              theme: FolioSubstrateTheme.xuan,
              onTurnBackward: () {
                backwardFired = true;
              },
              onTurnForward: () {
                forwardFired = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('◂ 上一页'), findsOneWidget);
      expect(find.text('下一页 ▸'), findsOneWidget);

      await tester.tap(find.text('◂ 上一页'));
      expect(backwardFired, isTrue);

      await tester.tap(find.text('下一页 ▸'));
      expect(forwardFired, isTrue);
    });
  });
}
