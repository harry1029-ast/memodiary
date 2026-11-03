import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_content_parser.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_desk_chrome.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_frontispiece_page.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_leaf_model.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_reading_perspective.dart';

void main() {
  const dummyAtmosphere = ShanshuiAtmosphereState(
    realm: ShanshuiRealm.nature,
    season: ShanshuiSeason.spring,
    timeOfDay: ShanshuiTimeOfDay.day,
    weather: ShanshuiWeather.sunny,
  );

  group('Folio Bug Diagnosis - Reproduction Tests', () {
    testWidgets('BUG 1: FolioFrontispiecePage and FolioContentLeafPage must render solid theme.pageBg substrate background', (tester) async {
      const xuanTheme = FolioSubstrateTheme.xuan; // pageBg: Color(0xFFFAF7F0) (Light Cream)

      final dummyLeaf = FolioFrontispieceCoverLeaf(
        leafIndex: 0,
        totalLeaves: 2,
        entryTitle: '测试手稿',
        lunarDate: '甲辰年冬月初三',
        gregorianDate: '2026.11.03',
        sceneryAtmosphere: dummyAtmosphere,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FolioFrontispiecePage(
              leaf: dummyLeaf,
              theme: xuanTheme,
            ),
          ),
        ),
      );

      // Verify page has a root or backdrop container painted with theme.pageBg (0xFFFAF7F0)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasPageBg = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == xuanTheme.pageBg;
        }
        return c.color == xuanTheme.pageBg;
      });

      expect(hasPageBg, isTrue, reason: 'FolioFrontispiecePage must have a solid substrate background matching theme.pageBg');
    });

    testWidgets('BUG 2: FolioBottomDock must not overflow horizontally on 360px viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF0A0908),
            bottomNavigationBar: FolioBottomDock(
              perspective: ReadingPerspective.faithfulOriginal,
              onOpenPerspective: () {},
              currentPageIndex: 0,
              totalPages: 2,
              onOpenPageJump: () {},
              onShare: () {},
              onEditEntry: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull, reason: 'Bottom dock must not throw RenderFlex overflow on 360px width');
    });

    test('BUG 3: Plain text without jiazhu must not steal first line as 眉批夹注', () {
      final reflection = FolioContentParser.extractOpeningReflection(
        plainText: 'test\n\nabcdefg',
        title: null,
      );

      expect(reflection, isNull, reason: 'Normal body text should not be labeled as 眉批夹注 unless {夹注:...} tag is used');
    });
  });
}
