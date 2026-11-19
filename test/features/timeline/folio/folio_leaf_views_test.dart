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
import 'package:memodiary/features/timeline/widgets/folio/folio_substrate_painter.dart';
import '../../../helpers/recording_canvas.dart';

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

    test('faithfulHorizontal respects backgroundType and showLeftMarginRule across all template types', () {
      const canvasSize = Size(320, 448);

      // Lined: 13 horizontal lines + 1 vertical margin line at x = 24
      final linedCanvas = RecordingCanvas();
      FolioSilkRulingPainter(
        layout: FolioRulingLayout.faithfulHorizontal,
        backgroundType: TemplateBackgroundType.lined,
        showLeftMarginRule: true,
        ruleColor: const Color(0x52C04851),
        frameColor: const Color(0xC7B83B2E),
      ).paint(linedCanvas, canvasSize);
      expect(linedCanvas.drawnRects, hasLength(2));
      expect(
        linedCanvas.drawnLines.where((line) => line.$1.dx == 24.0 && line.$2.dx == 24.0),
        hasLength(1),
      );
      expect(
        linedCanvas.drawnLines.where((line) => line.$1.dy == line.$2.dy),
        hasLength(13),
      );

      // PaperTexture (Retro Kraft): 13 horizontal lines, NO vertical margin line
      final kraftCanvas = RecordingCanvas();
      FolioSilkRulingPainter(
        layout: FolioRulingLayout.faithfulHorizontal,
        backgroundType: TemplateBackgroundType.paperTexture,
        showLeftMarginRule: false,
        ruleColor: const Color(0x148D6E63),
        frameColor: const Color(0xC7B83B2E),
      ).paint(kraftCanvas, canvasSize);
      expect(kraftCanvas.drawnRects, hasLength(2));
      expect(
        kraftCanvas.drawnLines.where((line) => line.$1.dx == line.$2.dx),
        isEmpty,
      );
      expect(
        kraftCanvas.drawnLines.where((line) => line.$1.dy == line.$2.dy),
        hasLength(13),
      );

      // Color: Double Outer Border only, zero ruling lines
      final colorCanvas = RecordingCanvas();
      FolioSilkRulingPainter(
        layout: FolioRulingLayout.faithfulHorizontal,
        backgroundType: TemplateBackgroundType.color,
        showLeftMarginRule: false,
        ruleColor: const Color(0x477A8B99),
        frameColor: const Color(0xC7B83B2E),
      ).paint(colorCanvas, canvasSize);
      expect(colorCanvas.drawnRects, hasLength(2));
      expect(colorCanvas.drawnLines, isEmpty);

      // Grid: 9 vertical + 13 horizontal lines, NO margin rule, NO fishtail mark
      final gridCanvas = RecordingCanvas();
      FolioSilkRulingPainter(
        layout: FolioRulingLayout.faithfulHorizontal,
        backgroundType: TemplateBackgroundType.grid,
        showLeftMarginRule: false,
        ruleColor: const Color(0x477A8B99),
        frameColor: const Color(0xC7B83B2E),
      ).paint(gridCanvas, canvasSize);
      expect(gridCanvas.drawnRects, hasLength(2));
      expect(gridCanvas.drawnPaths, isEmpty);
      expect(
        gridCanvas.drawnLines.where((line) => line.$1.dx == line.$2.dx),
        hasLength(9),
      );
      expect(
        gridCanvas.drawnLines.where((line) => line.$1.dy == line.$2.dy),
        hasLength(13),
      );

      // DotGrid: 9 * 13 = 117 dots, zero lines
      final dotCanvas = RecordingCanvas();
      FolioSilkRulingPainter(
        layout: FolioRulingLayout.faithfulHorizontal,
        backgroundType: TemplateBackgroundType.dotGrid,
        showLeftMarginRule: false,
        ruleColor: const Color(0x477A8B99),
        frameColor: const Color(0xC7B83B2E),
      ).paint(dotCanvas, canvasSize);
      expect(dotCanvas.drawnRects, hasLength(2));
      expect(dotCanvas.drawnLines, isEmpty);
      expect(dotCanvas.drawnCircles, hasLength(117));
    });

    test('FolioSubstratePainter renders kraft vignette and brown fibers when showKraftTexture is true', () {
      final kraftCanvas = RecordingCanvas();
      FolioSubstratePainter(
        showGoldFlecks: false,
        isDark: false,
        showKraftTexture: true,
        drawGutterShadow: false,
      ).paint(kraftCanvas, const Size(360, 560));

      expect(kraftCanvas.drawnRects, hasLength(1));
      expect(kraftCanvas.drawnLines, isNotEmpty);
      expect(kraftCanvas.drawnCircles, isEmpty);
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
      expect(find.text('开心'), findsOneWidget);
      expect(find.text('竹窗听雨，泥炉温茶，忽见远山出岫。'), findsOneWidget);
      expect(find.text('云皓日记'), findsOneWidget);
      expect(find.text('翻到正文 ›'), findsOneWidget);

      await tester.tap(find.text('翻到正文 ›'));
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
      expect(find.text('第12周复盘'), findsOneWidget);
      expect(find.text('这篇日记暂无正文'), findsOneWidget);
      expect(find.text('共 1 页'), findsOneWidget);
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
      expect(find.text('横线 · 横排'), findsOneWidget);
      expect(find.text('六桥烟柳'), findsOneWidget);
      expect(find.textContaining('苏堤春晓'), findsOneWidget);
    });

    testWidgets('applies margin clearance for lined/obsidian and symmetric 20px insets + matching labels across template types', (tester) async {
      final bodyLeaf = FolioContentBodyLeaf(
        leafIndex: 1,
        totalLeaves: 2,
        pageIndexInContent: 1,
        totalContentPages: 1,
        layout: FolioRulingLayout.faithfulHorizontal,
        title: '清秋记',
        lunarDate: '丙午年九月廿八',
        horizontalRows: const [
          FolioHorizontalRow(
            segments: [
              FolioHorizontalSegment(text: '首行正文不越红线。'),
            ],
          ),
        ],
      );

      final paperHeartFinder = find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.width == 320 && widget.height == 448,
      );

      Future<void> pumpBodyLeaf(FolioSubstrateTheme theme) => tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: FolioContentLeafPage(
                  leaf: bodyLeaf,
                  theme: theme,
                ),
              ),
            ),
          );

      // 1. Lined (with margin rule -> 32px left clearance)
      await pumpBodyLeaf(FolioSubstrateTheme.xuan);
      expect(find.text('横线 · 横排'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('首行正文不越红线。')).dx - tester.getTopLeft(paperHeartFinder).dx,
        equals(32.0),
      );

      // 2. Obsidian Night (with margin rule -> 32px left clearance)
      await pumpBodyLeaf(FolioSubstrateTheme.obsidian);
      expect(find.text('横线 · 横排'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('首行正文不越红线。')).dx - tester.getTopLeft(paperHeartFinder).dx,
        equals(32.0),
      );

      // 3. Other template background types in faithfulOriginal (20px symmetric padding + matching label)
      final expectedCases = <(TemplateBackgroundType, String)>[
        (TemplateBackgroundType.paperTexture, '牛皮纸 · 横排'),
        (TemplateBackgroundType.color, '纯色 · 横排'),
        (TemplateBackgroundType.grid, '方格 · 横排'),
        (TemplateBackgroundType.dotGrid, '点阵 · 横排'),
      ];

      for (final (bgType, expectedLabel) in expectedCases) {
        final theme = ReadingPerspective.faithfulOriginal.resolveTheme(
          templateStyle: TemplateStyle(
            type: bgType,
            backgroundColor: const Color(0xFFEFE6D5),
            lineSpacing: 1.6,
            marginHorizontal: 20.0,
          ),
        );
        await pumpBodyLeaf(theme);
        expect(find.text(expectedLabel), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('首行正文不越红线。')).dx - tester.getTopLeft(paperHeartFinder).dx,
          equals(20.0),
        );
      }

      // 4. Locks horizontal text scale to 1.0 under large OS textScaler so rows match pagination width
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: FolioContentLeafPage(
                leaf: bodyLeaf,
                theme: FolioSubstrateTheme.xuan,
              ),
            ),
          ),
        ),
      );
      final richTextWidget = tester.widget<RichText>(
        find.descendant(
          of: paperHeartFinder,
          matching: find.byWidgetPredicate(
            (widget) => widget is RichText && widget.text.toPlainText().contains('首行正文不越红线。'),
          ),
        ),
      );
      expect(richTextWidget.textScaler, equals(TextScaler.noScaling));
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
      expect(find.text('朱丝竖排'), findsOneWidget);
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
      expect(find.text('插图页'), findsOneWidget);
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
      expect(find.text('视频插页'), findsOneWidget);
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
