import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/theme/atmosphere_theme_models.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/widgets/cinnabar_seal_badge.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';
import 'package:memodiary/features/timeline/widgets/entry_summary_card.dart';
import 'package:memodiary/features/timeline/widgets/folded_xuan_slip.dart';
import 'package:memodiary/features/timeline/widgets/wet_mounted_thumbnail.dart';

import '../../helpers/editor_test_harness.dart';

TimelineEntryItem _buildItem({
  String id = 'entry_1',
  String? title = '暮秋听雨小记',
  String plainText = '晚来天欲雪，窗外梧桐叶落声渐密。于乌木书案前燃一炉青瓷沉香，展读旧年手卷，墨痕犹带江南烟雨之气。',
  DateTime? entryDate,
  int? mood,
  String? weather,
  bool isWeeklyReview = false,
  int? weekNumber,
  bool isLocked = false,
  MediaAttachment? primaryMedia,
}) {
  final date = entryDate ?? DateTime(2026, 11, 3, 21, 25);
  return TimelineEntryItem(
    entry: Entry(
      id: id,
      notebookId: 'notebook_default',
      templateId: 'template_minimalist_white',
      title: title,
      contentDelta: '[{"insert":"$plainText\\n"}]',
      plainText: plainText,
      entryDate: date,
      mood: mood,
      weather: weather,
      isWeeklyReview: isWeeklyReview,
      weekNumber: weekNumber,
      createdAt: date,
      updatedAt: date,
      isDeleted: false,
      isLocked: isLocked,
      legacyMountsPending: false,
    ),
    primaryMedia: primaryMedia,
  );
}

Future<void> _pumpEntryCard(
  WidgetTester tester, {
  required TimelineEntryItem item,
  required SyncTestMediaSandboxService mediaService,
  ThemeData? theme,
  double width = 360,
  double textScale = 1.0,
  VoidCallback? onTap,
}) async {
  tester.view.physicalSize = Size(width, 780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? InkDiaryTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(left: 68, right: 14),
          child: EntrySummaryCard(
            item: item,
            mediaService: mediaService,
            onTap: onTap ?? () {},
            customMargin: EdgeInsets.zero,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late Directory tempDir;
  late SyncTestMediaSandboxService mediaService;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('entry_summary_card_test_');
    mediaService = SyncTestMediaSandboxService(tempDir: tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('EntrySummaryCard folded slip & Tier 1 header', () {
    testWidgets('renders Light theme (云岚昼 default & 宣纸胡桃 classic) folded slip colors and Tier 1 header without cinnabar dot', (tester) async {
      final date = DateTime(2026, 11, 3, 21, 25);
      final item = _buildItem(
        title: '暮秋听雨小记',
        entryDate: date,
        mood: 4,
        weather: 'rainy',
        isWeeklyReview: true,
        weekNumber: 44,
      );

      await _pumpEntryCard(
        tester,
        item: item,
        mediaService: mediaService,
        theme: InkDiaryTheme.light,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FoldedXuanSlip), findsOneWidget);

      // Verify default yunhaoDay palette on FoldedXuanSlip
      final yunhaoSlipMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byType(FoldedXuanSlip),
          matching: find.byWidgetPredicate(
            (widget) => widget is Material && widget.color == const Color(0xFFFFFFFF),
          ),
        ),
      );
      final yunhaoShape = yunhaoSlipMaterial.shape as RoundedRectangleBorder;
      expect(yunhaoShape.side.color, const Color(0xFFCCD5DF));

      final yunhaoLipContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(FoldedXuanSlip),
          matching: find.byWidgetPredicate((widget) {
            if (widget is! Container) return false;
            final dec = widget.decoration;
            return dec is BoxDecoration && dec.color == const Color(0xFFD3DCE4);
          }),
        ),
      );
      expect(yunhaoLipContainer.padding, const EdgeInsets.only(bottom: 3));

      // Verify classicWalnut palette on FoldedXuanSlip
      await _pumpEntryCard(
        tester,
        item: item,
        mediaService: mediaService,
        theme: InkDiaryTheme.forLightPalette(LightAtmospherePaletteId.classicWalnut),
      );
      await tester.pumpAndSettle();

      final classicSlipMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byType(FoldedXuanSlip),
          matching: find.byWidgetPredicate(
            (widget) => widget is Material && widget.color == const Color(0xFFFAF6EE),
          ),
        ),
      );
      final classicShape = classicSlipMaterial.shape as RoundedRectangleBorder;
      expect(classicShape.side.color, const Color(0xFFC9B99E));

      final classicLipContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(FoldedXuanSlip),
          matching: find.byWidgetPredicate((widget) {
            if (widget is! Container) return false;
            final dec = widget.decoration;
            return dec is BoxDecoration && dec.color == const Color(0xFFD4C7B0);
          }),
        ),
      );
      expect(classicLipContainer.padding, const EdgeInsets.only(bottom: 3));

      // Verify Tier 1 title: 15.5sp serif bold, maxLines 2, no leading cinnabar dot
      final titleWidget = tester.widget<Text>(find.text('暮秋听雨小记'));
      expect(titleWidget.maxLines, 2);
      expect(titleWidget.style?.fontSize, 15.5);
      expect(titleWidget.style?.fontWeight, FontWeight.bold);

      final circleDots = find.descendant(
        of: find.byType(EntrySummaryCard),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final dec = widget.decoration;
          return dec is BoxDecoration && dec.shape == BoxShape.circle;
        }),
      );
      expect(circleDots, findsNothing);

      // Verify yyyy-MM-dd HH:mm timestamp and editor-matched Xuan charm metadata badges
      expect(find.text(DateFormat('yyyy-MM-dd HH:mm').format(date)), findsOneWidget);
      expect(find.byKey(const Key('entry_mood_charm')), findsOneWidget);
      expect(find.text('🙂'), findsOneWidget);
      expect(find.text('开心'), findsOneWidget);
      expect(find.byKey(const Key('entry_weather_charm')), findsOneWidget);
      expect(find.text('🌧️'), findsOneWidget);
      expect(find.text('下雨'), findsOneWidget);
      expect(find.byIcon(Icons.water_drop_outlined), findsNothing);
      expect(find.byType(CinnabarSealBadge), findsOneWidget);
      expect(find.text('W44'), findsOneWidget);
    });

    testWidgets('ignores unrecognized mood and weather values cleanly', (tester) async {
      final item = _buildItem(
        title: '未知气象测试',
        mood: 99,
        weather: 'hurricane',
      );

      await _pumpEntryCard(
        tester,
        item: item,
        mediaService: mediaService,
        theme: InkDiaryTheme.dark,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('entry_mood_charm')), findsNothing);
      expect(find.byKey(const Key('entry_weather_charm')), findsNothing);
    });

    testWidgets('renders Dark theme (皓月夜 default & 碑拓乌木 classic) folded slip colors', (tester) async {
      final item = _buildItem(title: '夜读书斋');

      await _pumpEntryCard(
        tester,
        item: item,
        mediaService: mediaService,
        theme: InkDiaryTheme.dark,
      );

      expect(tester.takeException(), isNull);
      final yunhaoSlipMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byType(FoldedXuanSlip),
          matching: find.byWidgetPredicate(
            (widget) => widget is Material && widget.color == const Color(0xFF1B2738),
          ),
        ),
      );
      final yunhaoShape = yunhaoSlipMaterial.shape as RoundedRectangleBorder;
      expect(yunhaoShape.side.color, const Color(0xFF2D4057));

      expect(
        find.descendant(
          of: find.byType(FoldedXuanSlip),
          matching: find.byWidgetPredicate((widget) {
            if (widget is! Container) return false;
            final dec = widget.decoration;
            return dec is BoxDecoration && dec.color == const Color(0xFF27374D);
          }),
        ),
        findsOneWidget,
      );

      await _pumpEntryCard(
        tester,
        item: item,
        mediaService: mediaService,
        theme: InkDiaryTheme.forDarkPalette(DarkAtmospherePaletteId.classicEbony),
      );
      await tester.pumpAndSettle();

      final classicSlipMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byType(FoldedXuanSlip),
          matching: find.byWidgetPredicate(
            (widget) => widget is Material && widget.color == const Color(0xFF242320),
          ),
        ),
      );
      final classicShape = classicSlipMaterial.shape as RoundedRectangleBorder;
      expect(classicShape.side.color, const Color(0xFF3D3A34));

      expect(
        find.descendant(
          of: find.byType(FoldedXuanSlip),
          matching: find.byWidgetPredicate((widget) {
            if (widget is! Container) return false;
            final dec = widget.decoration;
            return dec is BoxDecoration && dec.color == const Color(0xFF36332D);
          }),
        ),
        findsOneWidget,
      );
    });
  });

  group('EntrySummaryCard Tier 2 & WetMountedThumbnail', () {
    testWidgets('renders 3-line snippet and seal-free WetMountedThumbnail when primaryMedia is present', (tester) async {
      const relativePath = 'media/autumn_lake.webp';
      final mediaFile = File('${tempDir.path}/$relativePath')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);

      final media = MediaAttachment(
        id: 'media_1',
        entryId: 'entry_1',
        mediaType: 'image',
        relativePath: relativePath,
        createdAt: DateTime(2026, 11, 3, 21, 25),
      );
      final item = _buildItem(
        plainText: '第一行山水清音，第二行瓦檐细雨，第三行寒潭孤舟，第四行莫负良宵。',
        primaryMedia: media,
      );

      await _pumpEntryCard(tester, item: item, mediaService: mediaService);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(mediaFile.existsSync(), isTrue);

      final snippetWidget = tester.widget<Text>(find.textContaining('第一行山水清音'));
      expect(snippetWidget.maxLines, 3);
      expect(snippetWidget.overflow, TextOverflow.ellipsis);

      // Verify WetMountedThumbnail structure & colors
      final thumbFinder = find.byType(WetMountedThumbnail);
      expect(thumbFinder, findsOneWidget);

      final silkMatContainer = tester.widget<Container>(
        find.descendant(
          of: thumbFinder,
          matching: find.byWidgetPredicate((widget) {
            if (widget is! Container) return false;
            final dec = widget.decoration;
            if (dec is! BoxDecoration) return false;
            final border = dec.border;
            return dec.color == const Color(0xFFE8DFCE) &&
                border is Border &&
                border.top.color == const Color(0xFFB8A689);
          }),
        ),
      );
      expect(silkMatContainer, isNotNull);

      final innerFrameContainer = tester.widget<Container>(
        find.descendant(
          of: thumbFinder,
          matching: find.byWidgetPredicate((widget) {
            if (widget is! Container) return false;
            final dec = widget.decoration;
            if (dec is! BoxDecoration) return false;
            final border = dec.border;
            return border is Border && border.top.color == const Color(0xFF9A7B48);
          }),
        ),
      );
      expect(innerFrameContainer, isNotNull);

      // Verify miter seam CustomPaint exists & Image rendered
      expect(find.descendant(of: thumbFinder, matching: find.byType(CustomPaint)), findsAtLeastNWidgets(1));
      expect(find.descendant(of: thumbFinder, matching: find.byType(Image)), findsOneWidget);

      // Verify NO overlapping 2x2 red collector's seal
      expect(find.descendant(of: thumbFinder, matching: find.byType(CinnabarSealBadge)), findsNothing);
      expect(find.text('拾'), findsNothing);
      expect(find.text('光'), findsNothing);
      expect(find.text('珍'), findsNothing);
      expect(find.text('藏'), findsNothing);
    });

    testWidgets('omits WetMountedThumbnail when primaryMedia is null', (tester) async {
      final item = _buildItem(primaryMedia: null);

      await _pumpEntryCard(tester, item: item, mediaService: mediaService);

      expect(tester.takeException(), isNull);
      expect(find.byType(WetMountedThumbnail), findsNothing);
    });

    testWidgets('obscures snippet and hides WetMountedThumbnail when entry is locked', (tester) async {
      const relativePath = 'media/secret_photo.webp';
      File('${tempDir.path}/$relativePath')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(kValid1x1PngBytes);

      final media = MediaAttachment(
        id: 'media_secret',
        entryId: 'entry_locked',
        mediaType: 'image',
        relativePath: relativePath,
        createdAt: DateTime(2026, 11, 3, 21, 25),
      );
      final item = _buildItem(
        id: 'entry_locked',
        title: 'Secret Note',
        plainText: 'Confidential secret body text',
        isLocked: true,
        primaryMedia: media,
      );

      await _pumpEntryCard(tester, item: item, mediaService: mediaService);

      expect(tester.takeException(), isNull);
      expect(find.text('Secret Note'), findsOneWidget);
      expect(find.text('🔒 已加锁'), findsOneWidget);
      expect(find.textContaining('Confidential secret'), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byType(WetMountedThumbnail), findsNothing);
    });

    testWidgets('handles 320dp viewport and 2.0 text scaling without overflow and invokes onTap', (tester) async {
      var tapped = false;
      final media = MediaAttachment(
        id: 'media_2',
        entryId: 'entry_2',
        mediaType: 'image',
        relativePath: 'media/small_view.webp',
        createdAt: DateTime(2026, 11, 3, 21, 25),
      );
      final item = _buildItem(
        id: 'entry_2',
        title: '非常长的一段标题文字用来验证两行省略与窄屏适配效果',
        plainText: '这是一段很长的正文摘要，用来验证三行截断以及大号字体缩放下的布局稳定性。',
        mood: 5,
        weather: 'sunny',
        isWeeklyReview: true,
        weekNumber: 45,
        primaryMedia: media,
      );

      await _pumpEntryCard(
        tester,
        item: item,
        mediaService: mediaService,
        theme: InkDiaryTheme.dark,
        width: 320,
        textScale: 2.0,
        onTap: () => tapped = true,
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(WetMountedThumbnail), findsOneWidget);

      await tester.tap(find.byType(EntrySummaryCard));
      expect(tapped, isTrue);
    });

    test('preserves moodEmojis and weatherIcons public lookups', () {
      expect(EntrySummaryCard.moodEmojis[1], '😢');
      expect(EntrySummaryCard.moodEmojis[5], '😄');
      expect(EntrySummaryCard.weatherIcons['sunny'], Icons.wb_sunny_outlined);
      expect(EntrySummaryCard.weatherIcons['snowy'], Icons.ac_unit_outlined);
    });
  });
}
