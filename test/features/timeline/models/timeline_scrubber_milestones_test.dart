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
              inInclusiveRange(0.28, 0.48),
              reason: '${palette.id} light stop $color should be ink/mineral dark enough for light paper',
            );
          } else {
            expect(
              hsl.lightness,
              inInclusiveRange(0.56, 0.78),
              reason: '${palette.id} dark stop $color should be luminous enough for dark paper',
            );
          }
          expect(
            hsl.saturation,
            lessThanOrEqualTo(0.62),
            reason: '${palette.id} stop $color should remain muted mineral/ink',
          );
        }
      }
    });

    test('anchors first stop hue near accentPrimary for chromatic palettes', () {
      final yunhaoColors = buildScrubberChromaticPalette(
        AtmospherePalettes.yunhaoDay,
      );
      final primaryHue =
          HSLColor.fromColor(AtmospherePalettes.yunhaoDay.accentPrimary).hue;
      final firstStopHue = HSLColor.fromColor(yunhaoColors.first).hue;
      final hueDelta = ((firstStopHue - primaryHue + 540) % 360 - 180).abs();
      expect(hueDelta, lessThanOrEqualTo(15.0));
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
