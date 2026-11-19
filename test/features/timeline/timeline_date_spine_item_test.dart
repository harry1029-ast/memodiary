import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/atmosphere_palettes.dart';
import 'package:memodiary/core/theme/atmosphere_theme_models.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/shapes/classical_chinese_borders.dart';
import 'package:memodiary/features/timeline/widgets/lunar_phase_glyph.dart';
import 'package:memodiary/features/timeline/widgets/timeline_date_spine_item.dart';

void main() {
  group('Timeline Date Spine Helpers', () {
    test('formatGregorianDay formats days with numeric 日 suffix', () {
      expect(formatGregorianDay(1), '1日');
      expect(formatGregorianDay(15), '15日');
      expect(formatGregorianDay(25), '25日');
      expect(formatGregorianDay(31), '31日');
    });

    test('formatTraditionalChineseDay formats days to traditional Chinese lunar style', () {
      expect(formatTraditionalChineseDay(1), '初一');
      expect(formatTraditionalChineseDay(5), '初五');
      expect(formatTraditionalChineseDay(10), '初十');
      expect(formatTraditionalChineseDay(15), '十五');
      expect(formatTraditionalChineseDay(20), '二十');
      expect(formatTraditionalChineseDay(25), '廿五');
      expect(formatTraditionalChineseDay(28), '廿八');
      expect(formatTraditionalChineseDay(30), '三十');
      expect(formatTraditionalChineseDay(31), '三十一');
    });

    test('formatChineseWeekday formats weekday index to Chinese weekday', () {
      expect(formatChineseWeekday(1), '周一');
      expect(formatChineseWeekday(2), '周二');
      expect(formatChineseWeekday(3), '周三');
      expect(formatChineseWeekday(4), '周四');
      expect(formatChineseWeekday(5), '周五');
      expect(formatChineseWeekday(6), '周六');
      expect(formatChineseWeekday(7), '周日');
    });
  });

  group('TimelineDateSpineItem Widget Tests', () {
    testWidgets('renders date stamp badge with month, numeric Gregorian day by default, and weekday', (tester) async {
      final testDate = DateTime(2026, 10, 25); // Sunday

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: TimelineDateSpineItem(
              date: testDate,
              isFirst: true,
              isHighlighted: true,
              child: const Text('Test Entry Card'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify date components are rendered
      expect(find.text('10月'), findsOneWidget);
      expect(find.text('25日'), findsOneWidget);
      expect(find.text('廿五'), findsNothing);
      expect(find.text('周日'), findsOneWidget);
      expect(find.text('Test Entry Card'), findsOneWidget);

      // Verify Tooltip on badge
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('renders traditional lunar day when useLunarDay is true', (tester) async {
      final testDate = DateTime(2026, 10, 20); // Tuesday

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: TimelineDateSpineItem(
              date: testDate,
              isFirst: false,
              isLast: true,
              isHighlighted: false,
              useLunarDay: true,
              child: const Text('Standard Entry Card'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('10月'), findsOneWidget);
      expect(find.text('二十'), findsOneWidget);
      expect(find.text('周二'), findsOneWidget);
      expect(find.text('Standard Entry Card'), findsOneWidget);
    });

    testWidgets('renders waist_tally_lunar_phase glyph above month label', (tester) async {
      final fullMoonDate = DateTime(2026, 11, 23); // Lunar 十月十五

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: TimelineDateSpineItem(
              date: fullMoonDate,
              isFirst: true,
              isHighlighted: true,
              child: const SizedBox(height: 100, child: Text('Full Moon Entry')),
            ),
          ),
        ),
      );

      final glyphFinder = find.byKey(const Key('waist_tally_lunar_phase'));
      expect(glyphFinder, findsOneWidget);

      final glyph = tester.widget<LunarPhaseGlyph>(glyphFinder);
      expect(glyph.bucket, LunarPhaseBucket.fullMoon);
      expect(glyph.color, AtmospherePalettes.yunhaoDay.tallyFeaturedText);

      final glyphCenter = tester.getCenter(glyphFinder);
      final monthCenter = tester.getCenter(find.text('11月'));
      expect(glyphCenter.dy, lessThan(monthCenter.dy));
    });

    testWidgets('applies AtmospherePalette tokens across yunhaoDay, yunhaoNight, and classicWalnut', (tester) async {
      Future<void> verifyPalette({
        required ThemeData theme,
        required AtmospherePalette expectedPalette,
        required bool isHighlighted,
        required bool isFirst,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: TimelineDateSpineItem(
                date: DateTime(2026, 11, 23),
                isFirst: isFirst,
                isHighlighted: isHighlighted,
                child: const SizedBox(height: 110, child: Text('Entry')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final spineLine = tester.widget<Container>(
          find.byKey(const Key('timeline_date_spine_line')),
        );
        final spineDec = spineLine.decoration! as BoxDecoration;
        if (isFirst) {
          expect(
            (spineDec.gradient! as LinearGradient).colors,
            equals([expectedPalette.spineCordTop, expectedPalette.deckleBorder]),
          );
        } else {
          expect(spineDec.gradient, isNull);
          expect(spineDec.color, expectedPalette.deckleBorder);
        }

        final knotContainer = tester.widget<Container>(
          find.descendant(
            of: find.byType(Transform),
            matching: find.byType(Container),
          ),
        );
        final knotDec = knotContainer.decoration! as BoxDecoration;
        expect(
          knotDec.color,
          isHighlighted ? expectedPalette.accentPrimary : expectedPalette.accentSecondaryDim,
        );
        expect(
          (knotDec.border! as Border).top.color,
          expectedPalette.deskMat,
        );

        final tallyContainer = tester.widget<Container>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is ShapeDecoration &&
                (widget.decoration! as ShapeDecoration).shape is WaistTallyBorder,
          ),
        );
        final tallyDec = tallyContainer.decoration! as ShapeDecoration;
        final tallyBorder = tallyDec.shape as WaistTallyBorder;
        final tallyGradient = tallyDec.gradient! as LinearGradient;

        if (isHighlighted) {
          expect(
            tallyGradient.colors,
            equals([expectedPalette.tallyFeaturedTop, expectedPalette.tallyFeaturedBottom]),
          );
          expect(tallyBorder.borderColor, expectedPalette.tallyFeaturedBorder);
          expect(
            tallyBorder.innerBorderColor,
            expectedPalette.tallyFeaturedText.withValues(alpha: 0.35),
          );
          expect(tallyDec.shadows!.single.color, expectedPalette.tallyFeaturedShadow);
        } else {
          expect(
            tallyGradient.colors,
            equals([expectedPalette.tallyBgTop, expectedPalette.tallyBgBottom]),
          );
          expect(tallyBorder.borderColor, expectedPalette.tallyBorder);
          expect(tallyBorder.innerBorderColor, expectedPalette.slipInnerFrameColor);
          expect(tallyDec.shadows!.single.color, expectedPalette.slipShadowColor);
        }

        final monthText = tester.widget<Text>(find.text('11月'));
        final dayText = tester.widget<Text>(find.text('23日'));
        final weekdayText = tester.widget<Text>(find.text('周一'));
        final glyph = tester.widget<LunarPhaseGlyph>(
          find.byKey(const Key('waist_tally_lunar_phase')),
        );

        if (isHighlighted) {
          expect(monthText.style?.color, expectedPalette.tallyFeaturedText.withValues(alpha: 0.88));
          expect(dayText.style?.color, expectedPalette.tallyFeaturedText);
          expect(weekdayText.style?.color, expectedPalette.tallyFeaturedText.withValues(alpha: 0.88));
          expect(glyph.color, expectedPalette.tallyFeaturedText);
        } else {
          expect(monthText.style?.color, expectedPalette.textMuted);
          expect(dayText.style?.color, expectedPalette.textPrimary);
          expect(weekdayText.style?.color, expectedPalette.textMuted);
          expect(glyph.color, expectedPalette.accentPrimary);
        }
      }

      await verifyPalette(
        theme: InkDiaryTheme.light,
        expectedPalette: AtmospherePalettes.yunhaoDay,
        isHighlighted: true,
        isFirst: true,
      );
      await verifyPalette(
        theme: InkDiaryTheme.light,
        expectedPalette: AtmospherePalettes.yunhaoDay,
        isHighlighted: false,
        isFirst: false,
      );
      await verifyPalette(
        theme: InkDiaryTheme.dark,
        expectedPalette: AtmospherePalettes.yunhaoNight,
        isHighlighted: true,
        isFirst: true,
      );
      await verifyPalette(
        theme: InkDiaryTheme.dark,
        expectedPalette: AtmospherePalettes.yunhaoNight,
        isHighlighted: false,
        isFirst: false,
      );
      await verifyPalette(
        theme: InkDiaryTheme.forLightPalette(LightAtmospherePaletteId.classicWalnut),
        expectedPalette: AtmospherePalettes.classicWalnut,
        isHighlighted: true,
        isFirst: true,
      );
      await verifyPalette(
        theme: InkDiaryTheme.forLightPalette(LightAtmospherePaletteId.classicWalnut),
        expectedPalette: AtmospherePalettes.classicWalnut,
        isHighlighted: false,
        isFirst: false,
      );
    });

    testWidgets('preserves useLunarDay toggle, onTapBadge, and renders at 1.3x text scale without exception', (tester) async {
      var tapped = false;
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(
            body: TimelineDateSpineItem(
              date: DateTime(2026, 10, 31),
              isFirst: true,
              isHighlighted: true,
              useLunarDay: true,
              onTapBadge: () => tapped = true,
              child: const SizedBox(height: 110, child: Text('Entry Card')),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('waist_tally_lunar_phase')), findsOneWidget);
      expect(find.text('10月'), findsOneWidget);
      expect(find.text('三十一'), findsOneWidget);
      expect(find.text('周六'), findsOneWidget);

      await tester.tap(find.byKey(const Key('waist_tally_lunar_phase')));
      expect(tapped, isTrue);
    });
  });

  group('Lunar Phase Resolution & Glyph', () {
    test('maps all 30 lunar days across the 7 phase buckets and clamps invalid values', () {
      const expectedByDay = <int, LunarPhaseBucket>{
        1: LunarPhaseBucket.newCrescent,
        2: LunarPhaseBucket.newCrescent,
        3: LunarPhaseBucket.newCrescent,
        4: LunarPhaseBucket.newCrescent,
        5: LunarPhaseBucket.newCrescent,
        6: LunarPhaseBucket.firstQuarter,
        7: LunarPhaseBucket.firstQuarter,
        8: LunarPhaseBucket.firstQuarter,
        9: LunarPhaseBucket.firstQuarter,
        10: LunarPhaseBucket.firstQuarter,
        11: LunarPhaseBucket.waxingGibbous,
        12: LunarPhaseBucket.waxingGibbous,
        13: LunarPhaseBucket.waxingGibbous,
        14: LunarPhaseBucket.fullMoon,
        15: LunarPhaseBucket.fullMoon,
        16: LunarPhaseBucket.fullMoon,
        17: LunarPhaseBucket.fullMoon,
        18: LunarPhaseBucket.waningGibbous,
        19: LunarPhaseBucket.waningGibbous,
        20: LunarPhaseBucket.waningGibbous,
        21: LunarPhaseBucket.waningGibbous,
        22: LunarPhaseBucket.thirdQuarter,
        23: LunarPhaseBucket.thirdQuarter,
        24: LunarPhaseBucket.thirdQuarter,
        25: LunarPhaseBucket.thirdQuarter,
        26: LunarPhaseBucket.waningCrescent,
        27: LunarPhaseBucket.waningCrescent,
        28: LunarPhaseBucket.waningCrescent,
        29: LunarPhaseBucket.waningCrescent,
        30: LunarPhaseBucket.waningCrescent,
      };

      for (var day = 1; day <= 30; day++) {
        expect(resolveLunarPhaseBucket(day), expectedByDay[day], reason: 'day=$day');
      }

      expect(resolveLunarPhaseBucket(null), LunarPhaseBucket.newCrescent);
      expect(resolveLunarPhaseBucket(0), LunarPhaseBucket.newCrescent);
      expect(resolveLunarPhaseBucket(-4), LunarPhaseBucket.newCrescent);
      expect(resolveLunarPhaseBucket(31), LunarPhaseBucket.waningCrescent);
      expect(resolveLunarPhaseBucket(35), LunarPhaseBucket.waningCrescent);
    });

    test('resolveLunarPhaseForDate resolves supported and out-of-range dates deterministically', () {
      expect(resolveLunarPhaseForDate(DateTime(2026, 11, 23)), LunarPhaseBucket.fullMoon);
      expect(resolveLunarPhaseForDate(DateTime(2026, 2, 17)), LunarPhaseBucket.newCrescent);
      expect(resolveLunarPhaseForDate(DateTime(2026, 11, 7)), LunarPhaseBucket.waningCrescent);
      expect(resolveLunarPhaseForDate(DateTime(1850, 6, 15)), LunarPhaseBucket.fullMoon);
    });

    testWidgets('LunarPhaseGlyph paints all 7 buckets cleanly with ExcludeSemantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: LunarPhaseBucket.values
                  .map(
                    (bucket) => LunarPhaseGlyph(
                      bucket: bucket,
                      color: Colors.amber,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(LunarPhaseGlyph), findsNWidgets(LunarPhaseBucket.values.length));
      expect(
        find.descendant(
          of: find.byType(LunarPhaseGlyph),
          matching: find.byType(ExcludeSemantics),
        ),
        findsNWidgets(LunarPhaseBucket.values.length),
      );
    });
  });
}

