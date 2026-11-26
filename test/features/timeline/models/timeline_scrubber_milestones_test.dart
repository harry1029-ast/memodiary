import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/atmosphere_palettes.dart';
import 'package:memodiary/features/timeline/models/timeline_date_index_entry.dart';
import 'package:memodiary/features/timeline/models/timeline_scrubber_milestones.dart';

void main() {
  final allPalettes = <AtmospherePalette>[
    AtmospherePalettes.yunhaoDay,
    AtmospherePalettes.classicWalnut,
    AtmospherePalettes.mistyTwilight,
    AtmospherePalettes.yunhaoNight,
    AtmospherePalettes.classicEbony,
    AtmospherePalettes.silveryRain,
    AtmospherePalettes.blossomLantern,
  ];

  List<TimelineDateIndexEntry> makeEntries(List<DateTime> dates) {
    return [
      for (var index = 0; index < dates.length; index++)
        TimelineDateIndexEntry(id: 'entry_$index', entryDate: dates[index]),
    ];
  }

  group('buildScrubberChromaticPalette', () {
    test('produces 5 distinct muted colors excluding sealAccent for all 7 palettes', () {
      for (final palette in allPalettes) {
        final colors = buildScrubberChromaticPalette(palette);

        expect(
          colors,
          hasLength(5),
          reason: '${palette.id} should produce exactly 5 chromatic stops',
        );
        expect(
          colors.toSet(),
          hasLength(5),
          reason: '${palette.id} should produce 5 distinct colors',
        );
        expect(
          colors,
          isNot(contains(palette.sealAccent)),
          reason: '${palette.id} must never use sealAccent',
        );

        for (final color in colors) {
          final hsl = HSLColor.fromColor(color);
          if (palette.brightness == Brightness.light) {
            expect(
              hsl.lightness,
              inInclusiveRange(0.28, 0.56),
              reason: '${palette.id} light stop $color should maintain crisp contrast on light paper',
            );
          } else {
            expect(
              hsl.lightness,
              inInclusiveRange(0.46, 0.78),
              reason: '${palette.id} dark stop $color should remain luminous on dark paper',
            );
          }
          expect(
            hsl.saturation,
            lessThanOrEqualTo(0.68),
            reason: '${palette.id} stop $color should remain muted mineral/ink',
          );
        }
      }
    });

    test('keeps yunhaoDay in porcelain-celadon-brass and yunhaoNight free of purple overshoot', () {
      final dayStops = buildScrubberChromaticPalette(AtmospherePalettes.yunhaoDay);
      expect(dayStops.first, equals(AtmospherePalettes.yunhaoDay.accentPrimary));
      for (final color in dayStops) {
        final hue = HSLColor.fromColor(color).hue;
        // Exclude saturated yellow-green olive (65°..150°)
        expect(hue < 65.0 || hue > 150.0, isTrue, reason: 'yunhaoDay stop $color ($hue°) must not drift olive');
      }

      final nightStops = buildScrubberChromaticPalette(AtmospherePalettes.yunhaoNight);
      for (final color in nightStops) {
        final hue = HSLColor.fromColor(color).hue;
        // Exclude purple/magenta overshoot (250°..330°)
        expect(hue < 250.0 || hue > 330.0, isTrue, reason: 'yunhaoNight stop $color ($hue°) must not drift purple');
      }
    });

    test('interpolates unknown palette IDs linearly between accentPrimary and accentSecondary', () {
      const customSameAccents = AtmospherePalette(
        id: 'customMono',
        nameZh: '自定义',
        brightness: Brightness.light,
        ground: Color(0xFFFFFFFF),
        deskMat: Color(0xFFF5F5F5),
        deskTray: Color(0xFFEEEEEE),
        cardPaper: Color(0xFFFFFFFF),
        cardStackLip: Color(0xFFE0E0E0),
        agedFiberChip: Color(0xFFDDDDDD),
        deckleBorder: Color(0xFFCCCCCC),
        textPrimary: Color(0xFF111111),
        textSecondary: Color(0xFF333333),
        textMuted: Color(0xFF666666),
        textFaint: Color(0xFF999999),
        accentPrimary: Color(0xFF4A7A9C),
        onAccentPrimary: Colors.white,
        accentPrimaryDark: Color(0xFF355C78),
        accentPrimaryWash: Color(0xFFE2ECF3),
        accentSecondary: Color(0xFF4A7A9C),
        accentSecondaryDim: Color(0xFF6E9D99),
        sealAccent: Color(0xFFC24D43),
        sealAccentDark: Color(0xFF9A3830),
        sealAccentWash: Color(0xFFF5E5E3),
        chipActiveBg: Color(0x334A7A9C),
        chipActiveBorder: Color(0x8C4A7A9C),
        emeraldSaved: Color(0xFF059669),
        woodFrameDark: Color(0xFF48647A),
        woodFrameMid: Color(0xFF5B7B94),
        woodFrameHighlight: Color(0xFF89A8BF),
        headerTitleText: Color(0xFFF7F9FB),
        headerSubText: Color(0xFFCEDAE5),
        sillTop: Color(0xFF527087),
        sillBottom: Color(0xFF3B5265),
        lipTop: Color(0xFF65859E),
        lipBottom: Color(0xFF2D4050),
        deskSurroundTop: Color(0xFFE4EBF0),
        deskSurroundBottom: Color(0xFFDDE5EC),
        candleGlow: Color(0x33FFD282),
        slipRuleColor: Color(0x124A7A9C),
        slipInnerFrameColor: Color(0x244E8782),
        slipDividerColor: Color(0x2B4A7A9C),
        slipShadowColor: Color(0x140E1A26),
        spineCordTop: Color(0xFF4A7A9C),
        tallyBgTop: Color(0xFFFFFFFF),
        tallyBgBottom: Color(0xFFE7EEF4),
        tallyBorder: Color(0xFFB4C5D4),
        tallyFeaturedTop: Color(0xFF5285A8),
        tallyFeaturedBottom: Color(0xFF3A6685),
        tallyFeaturedBorder: Color(0xFF87B5D4),
        tallyFeaturedText: Colors.white,
        tallyFeaturedShadow: Color(0x4D3A6685),
        silkMountBg: Color(0xFFEBF1F5),
        silkMountBorder: Color(0xFFA8BDCE),
        silkInnerFrame: Color(0xFF68849B),
        silkMiterSeam: Color(0xFF8BA2B5),
        blindSlatTop: Color(0xFFDAE4EC),
        blindSlatMid: Color(0xFFEEF4F8),
        blindSlatBottom: Color(0xFFC4D4E0),
        blindSlit: Color(0xFF8DA1B2),
        blindRollerTop: Color(0xFF5B7B94),
        blindRollerMid: Color(0xFF48647A),
        blindRollerBottom: Color(0xFF334A5C),
        blindCordPrimary: Color(0xFF4A7A9C),
        blindCordSecondary: Color(0xFFC9975B),
        blindTagAccent: Color(0xFFC9975B),
        fabTop: Color(0xFF4E8782),
        fabMid: Color(0xFF427772),
        fabBottom: Color(0xFF376662),
        fabBorder: Color(0xFF8BC2BC),
        fabInnerBorder: Color(0x59E6F4F2),
        fabText: Color(0xFFF7FBFA),
        fabCapHighlight: Color(0xFFCBE6E3),
        fabCapMid: Color(0xFF8BC2BC),
        fabCapDark: Color(0xFF264845),
        fabShadow: Color(0x66376662),
      );

      final customStops = buildScrubberChromaticPalette(customSameAccents);
      expect(customStops, hasLength(5));
      expect(customStops.toSet(), hasLength(5));
      expect(customStops, isNot(contains(customSameAccents.sealAccent)));
    });

    test('interpolates scrubberRailStops cleanly in AtmospherePalette.lerp', () {
      final blended = AtmospherePalettes.yunhaoDay.lerp(
        AtmospherePalettes.yunhaoNight,
        0.5,
      );
      expect(blended.scrubberRailStops, hasLength(5));
      expect(
        blended.scrubberRailStops.first,
        equals(
          Color.lerp(
            AtmospherePalettes.yunhaoDay.scrubberRailStops.first,
            AtmospherePalettes.yunhaoNight.scrubberRailStops.first,
            0.5,
          ),
        ),
      );
    });
  });

  group('buildScrubberMilestones', () {
    final palette = buildScrubberChromaticPalette(AtmospherePalettes.yunhaoDay);

    test('returns empty list for empty dateIndex', () {
      expect(buildScrubberMilestones(const [], palette), isEmpty);
    });

    test('uses Year (YYYY) granularity when entries span >= 2 calendar years', () {
      final dateIndex = makeEntries([
        DateTime(2026, 11, 20),
        DateTime(2026, 5, 1),
        DateTime(2025, 12, 15),
        DateTime(2025, 3, 10),
        DateTime(2024, 8, 5),
      ]);

      expect(
        resolveScrubberMilestoneGranularity(dateIndex),
        equals(ScrubberMilestoneGranularity.year),
      );

      final milestones = buildScrubberMilestones(dateIndex, palette);
      expect(milestones.map((m) => m.label), equals(['2026', '2025', '2024']));
      expect(milestones.map((m) => m.entryIndex), equals([0, 2, 4]));
      expect(milestones[0].progress, closeTo(0.0, 1e-6));
      expect(milestones[1].progress, closeTo(2 / 4, 1e-6));
      expect(milestones[2].progress, closeTo(1.0, 1e-6));
    });

    test('uses Month (M月) granularity for single year with <= 6 distinct months', () {
      final dateIndex = makeEntries([
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 3),
        DateTime(2026, 9, 18),
        DateTime(2026, 6, 10),
        DateTime(2026, 4, 2),
        DateTime(2026, 1, 15),
      ]);

      expect(
        resolveScrubberMilestoneGranularity(dateIndex),
        equals(ScrubberMilestoneGranularity.month),
      );

      final milestones = buildScrubberMilestones(dateIndex, palette);
      expect(
        milestones.map((m) => m.label),
        equals(['11月', '9月', '6月', '4月', '1月']),
      );
      expect(milestones.map((m) => m.entryIndex), equals([0, 2, 3, 4, 5]));
      expect(milestones[1].progress, closeTo(2 / 5, 1e-6));
    });

    test('uses Quarter-bucketed Month (M月) for single year with > 6 distinct months', () {
      final dateIndex = makeEntries([
        DateTime(2026, 12, 10), // Q4 -> index 0
        DateTime(2026, 11, 5),  // Q4
        DateTime(2026, 9, 20),  // Q3 -> index 2
        DateTime(2026, 8, 12),  // Q3
        DateTime(2026, 7, 1),   // Q3
        DateTime(2026, 6, 15),  // Q2 -> index 5
        DateTime(2026, 5, 1),   // Q2
        DateTime(2026, 3, 18),  // Q1 -> index 7
      ]);

      expect(
        resolveScrubberMilestoneGranularity(dateIndex),
        equals(ScrubberMilestoneGranularity.quarter),
      );

      final milestones = buildScrubberMilestones(dateIndex, palette);
      expect(
        milestones.map((m) => m.label),
        equals(['12月', '9月', '6月', '3月']),
      );
      expect(milestones.map((m) => m.entryIndex), equals([0, 2, 5, 7]));
      expect(milestones[0].progress, closeTo(0.0, 1e-6));
      expect(milestones[1].progress, closeTo(2 / 7, 1e-6));
      expect(milestones[2].progress, closeTo(5 / 7, 1e-6));
      expect(milestones[3].progress, closeTo(1.0, 1e-6));
    });

    test('assigns distinct progress-ordered chromatic colors from palette', () {
      final dateIndex = makeEntries([
        DateTime(2026, 1, 1),
        DateTime(2025, 1, 1),
        DateTime(2024, 1, 1),
        DateTime(2023, 1, 1),
        DateTime(2022, 1, 1),
      ]);
      final milestones = buildScrubberMilestones(dateIndex, palette);
      expect(milestones.map((m) => m.color).toSet(), hasLength(5));
    });
  });

  group('selectVisibleMilestones', () {
    const c0 = Color(0xFF111111);
    const c1 = Color(0xFF222222);
    const c2 = Color(0xFF333333);
    const c3 = Color(0xFF444444);
    const c4 = Color(0xFF555555);

    test('preserves first and last milestones while enforcing 12dp node and 28dp label spacing', () {
      final milestones = <ScrubberMilestone>[
        const ScrubberMilestone(entryIndex: 0, progress: 0.0, label: '2026', color: c0),
        const ScrubberMilestone(entryIndex: 1, progress: 0.08, label: '2025', color: c1),
        const ScrubberMilestone(entryIndex: 5, progress: 0.50, label: '2024', color: c2),
        const ScrubberMilestone(entryIndex: 9, progress: 0.90, label: '2023', color: c3),
        const ScrubberMilestone(entryIndex: 10, progress: 1.0, label: '2022', color: c4),
      ];

      // Usable height = 200dp:
      // y positions: 0, 16, 100, 180, 200
      // Nodes (>= 12dp): 0, 16 (16>=12), 100, 180 (20>=12 to 200), 200 -> all 5!
      // Labels (>= 28dp): 0, 16 (<28 skipped), 100, 180 (20<28 to 200 skipped!), 200 -> [2026, 2024, 2022]!
      final visible = selectVisibleMilestones(milestones, 200.0);
      expect(visible.nodes.map((m) => m.label), equals(['2026', '2025', '2024', '2023', '2022']));
      expect(visible.labels.map((m) => m.label), equals(['2026', '2024', '2022']));

      // Tight height = 100dp:
      // y positions: 0, 8, 50, 90, 100
      // Nodes (>= 12dp): 0, 8 (<12 skipped), 50, 90 (10<12 to 100 skipped!), 100 -> [2026, 2024, 2022]
      final tightVisible = selectVisibleMilestones(milestones, 100.0);
      expect(tightVisible.nodes.map((m) => m.label), equals(['2026', '2024', '2022']));
      expect(tightVisible.labels.map((m) => m.label), equals(['2026', '2024', '2022']));
    });
  });

  group('colorForScrubberProgress', () {
    const fallback = Color(0xFF999999);
    const startColor = Color(0xFF000000);
    const midColor = Color(0xFF4080C0);
    const endColor = Color(0xFFFFFFFF);

    final milestones = <ScrubberMilestone>[
      const ScrubberMilestone(entryIndex: 0, progress: 0.0, label: 'A', color: startColor),
      const ScrubberMilestone(entryIndex: 5, progress: 0.5, label: 'B', color: midColor),
      const ScrubberMilestone(entryIndex: 10, progress: 1.0, label: 'C', color: endColor),
    ];

    test('returns fallback when milestones empty and smoothly interpolates between stops', () {
      expect(colorForScrubberProgress(0.5, const [], fallback), equals(fallback));
      expect(colorForScrubberProgress(0.0, milestones, fallback), equals(startColor));
      expect(colorForScrubberProgress(0.5, milestones, fallback), equals(midColor));
      expect(colorForScrubberProgress(1.0, milestones, fallback), equals(endColor));
      expect(
        colorForScrubberProgress(0.25, milestones, fallback),
        equals(Color.lerp(startColor, midColor, 0.5)),
      );
      expect(
        colorForScrubberProgress(0.75, milestones, fallback),
        equals(Color.lerp(midColor, endColor, 0.5)),
      );
    });
  });
}
