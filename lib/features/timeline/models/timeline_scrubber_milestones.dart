import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/features/timeline/models/timeline_date_index_entry.dart';

/// Adaptive grouping level for `Timeline Scrubber` milestone nodes and chips.
enum ScrubberMilestoneGranularity { year, quarter, month }

/// A single milestone stop along the chromatic `Timeline Scrubber` rail.
@immutable
class ScrubberMilestone {
  final int entryIndex;
  final double progress;
  final String label;
  final Color color;

  const ScrubberMilestone({
    required this.entryIndex,
    required this.progress,
    required this.label,
    required this.color,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScrubberMilestone &&
        other.entryIndex == entryIndex &&
        other.progress == progress &&
        other.label == label &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(entryIndex, progress, label, color);
}

/// Filtered subsets of milestones that satisfy vertical node and label spacing.
@immutable
class VisibleScrubberMilestones {
  final List<ScrubberMilestone> nodes;
  final List<ScrubberMilestone> labels;

  const VisibleScrubberMilestones({required this.nodes, required this.labels});
}

/// Builds a 5-stop muted mineral/ink progression curated per [AtmospherePalette]
/// and calibrated for light and dark contrast while excluding `sealAccent`.
List<Color> buildScrubberChromaticPalette(AtmospherePalette palette) {
  switch (palette.id) {
    case 'yunhaoDay':
      return const <Color>[
        Color(0xFF4A7A9C), // Cerulean porcelain
        Color(0xFF5D89A3), // Misty glaze blue
        Color(0xFF4E8782), // Celadon verdigris
        Color(0xFF6B9691), // Soft misty jade
        Color(0xFFB58E5B), // Warm brass grommet
      ];
    case 'classicWalnut':
      return const <Color>[
        Color(0xFFA65443), // Muted terracotta
        Color(0xFFB07846), // Warm ochre
        Color(0xFF9A7432), // Antique bronze
        Color(0xFF7F6A4A), // Tea walnut
        Color(0xFF6B5847), // Walnut umber
      ];
    case 'mistyTwilight':
      return const <Color>[
        Color(0xFF5F6E7D), // Twilight slate
        Color(0xFF72808C), // Misty ink grey
        Color(0xFF848B88), // Rain-washed pebble
        Color(0xFF9E875E), // Pale dusk ochre
        Color(0xFFB08642), // Warm dusk gold
      ];
    case 'yunhaoNight':
      return const <Color>[
        Color(0xFFE2BA78), // Warm lantern gold
        Color(0xFFD8C292), // Pale champagne moonlight
        Color(0xFFB3C3CE), // Moonlit silver
        Color(0xFF8CB0CC), // Clear moonlight blue
        Color(0xFF638BAB), // Midnight cerulean
      ];
    case 'classicEbony':
      return const <Color>[
        Color(0xFFD4B478), // Antique gold
        Color(0xFFC29C63), // Burnished bronze
        Color(0xFFB57C5A), // Warm sandalwood
        Color(0xFF9E6B5A), // Muted clay terracotta
        Color(0xFF8A7D6B), // Stele taupe
      ];
    case 'silveryRain':
      return const <Color>[
        Color(0xFF8FB2C9), // Rain-silver blue
        Color(0xFF7FA8B4), // Misty blue-teal
        Color(0xFF84ABA3), // Soft rain jade
        Color(0xFFB6BDAE), // Cloud silver
        Color(0xFFDFC086), // Warm lamp gold
      ];
    case 'blossomLantern':
      return const <Color>[
        Color(0xFFE89AA4), // Blossom pink
        Color(0xFFE2AF8E), // Warm peach-apricot
        Color(0xFFE2BC7E), // Lantern amber
        Color(0xFF9CC0B4), // Bamboo jade
        Color(0xFF6FA0A6), // Night pine-teal
      ];
    default:
      return _buildLinearAccentFallback(palette);
  }
}

List<Color> _buildLinearAccentFallback(AtmospherePalette palette) {
  final stops = <Color>[];
  for (var index = 0; index < 5; index++) {
    var color = Color.lerp(
      palette.accentPrimary,
      palette.accentSecondary,
      index / 4.0,
    )!;
    if (color == palette.sealAccent || stops.contains(color)) {
      color = Color.lerp(color, palette.textSecondary, 0.14 + index * 0.08)!;
    }
    stops.add(color);
  }
  return List<Color>.unmodifiable(stops);
}

/// Resolves adaptive milestone granularity from the ordered [dateIndex].
ScrubberMilestoneGranularity resolveScrubberMilestoneGranularity(
  List<TimelineDateIndexEntry> dateIndex,
) {
  if (dateIndex.isEmpty) return ScrubberMilestoneGranularity.month;
  final distinctYears = <int>{};
  final distinctMonths = <(int, int)>{};
  for (final entry in dateIndex) {
    distinctYears.add(entry.entryDate.year);
    if (distinctYears.length >= 2) return ScrubberMilestoneGranularity.year;
    distinctMonths.add((entry.entryDate.year, entry.entryDate.month));
  }
  return distinctMonths.length <= 6
      ? ScrubberMilestoneGranularity.month
      : ScrubberMilestoneGranularity.quarter;
}

/// Groups [dateIndex] into adaptive Year (`YYYY`) or Month/Quarter (`M月`)
/// milestones with exact fractional progress and harmonized chromatic colors.
List<ScrubberMilestone> buildScrubberMilestones(
  List<TimelineDateIndexEntry> dateIndex,
  List<Color> chromaticPalette,
) {
  if (dateIndex.isEmpty) return const [];
  final paletteColors =
      chromaticPalette.isEmpty ? const [Color(0xFF4A7A9C)] : chromaticPalette;
  final granularity = resolveScrubberMilestoneGranularity(dateIndex);
  final seenKeys = <int>{};
  final rawStops = <({int entryIndex, String label})>[];

  for (var index = 0; index < dateIndex.length; index++) {
    final date = dateIndex[index].entryDate;
    final (bucketKey, label) = switch (granularity) {
      ScrubberMilestoneGranularity.year => (date.year, '${date.year}'),
      ScrubberMilestoneGranularity.month => (
          date.year * 100 + date.month,
          '${date.month}月',
        ),
      ScrubberMilestoneGranularity.quarter => (
          date.year * 10 + (date.month - 1) ~/ 3,
          '${date.month}月',
        ),
    };
    if (seenKeys.add(bucketKey)) {
      rawStops.add((entryIndex: index, label: label));
    }
  }

  final total = dateIndex.length;
  final stopCount = rawStops.length;
  return List<ScrubberMilestone>.unmodifiable([
    for (var stopIndex = 0; stopIndex < stopCount; stopIndex++)
      ScrubberMilestone(
        entryIndex: rawStops[stopIndex].entryIndex,
        progress: total <= 1
            ? 0.0
            : (rawStops[stopIndex].entryIndex / (total - 1)).clamp(0.0, 1.0),
        label: rawStops[stopIndex].label,
        color: _sampleChromaticColor(
          paletteColors,
          stopCount <= 1 ? 0.0 : stopIndex / (stopCount - 1),
        ),
      ),
  ]);
}

Color _sampleChromaticColor(List<Color> colors, double t) {
  if (colors.length == 1) return colors.first;
  final scaled = t.clamp(0.0, 1.0) * (colors.length - 1);
  final lowerIndex = scaled.floor().clamp(0, colors.length - 1);
  final upperIndex = scaled.ceil().clamp(0, colors.length - 1);
  if (lowerIndex == upperIndex) return colors[lowerIndex];
  return Color.lerp(colors[lowerIndex], colors[upperIndex], scaled - lowerIndex)!;
}

/// Selects node-visible and label-visible milestones while enforcing minimum
/// vertical spacing and prioritizing the first and last boundary milestones.
VisibleScrubberMilestones selectVisibleMilestones(
  List<ScrubberMilestone> milestones,
  double usableHeight, {
  double minNodeSpacing = 12.0,
  double minLabelSpacing = 28.0,
}) {
  return VisibleScrubberMilestones(
    nodes: _filterBySpacing(milestones, usableHeight, minNodeSpacing),
    labels: _filterBySpacing(milestones, usableHeight, minLabelSpacing),
  );
}

List<ScrubberMilestone> _filterBySpacing(
  List<ScrubberMilestone> milestones,
  double usableHeight,
  double minSpacing,
) {
  if (milestones.isEmpty) return const [];
  if (milestones.length == 1) return List<ScrubberMilestone>.unmodifiable(milestones);

  final safeHeight = usableHeight < 0 ? 0.0 : usableHeight;
  double yFor(ScrubberMilestone milestone) =>
      milestone.progress.clamp(0.0, 1.0) * safeHeight;

  final first = milestones.first;
  final last = milestones.last;
  final firstY = yFor(first);
  final lastY = yFor(last);
  final includeLast = (lastY - firstY).abs() >= minSpacing;

  final selected = <ScrubberMilestone>[first];
  var prevY = firstY;
  for (var index = 1; index < milestones.length - 1; index++) {
    final candidate = milestones[index];
    final candidateY = yFor(candidate);
    if ((candidateY - prevY).abs() >= minSpacing &&
        (!includeLast || (lastY - candidateY).abs() >= minSpacing)) {
      selected.add(candidate);
      prevY = candidateY;
    }
  }
  if (includeLast) selected.add(last);
  return List<ScrubberMilestone>.unmodifiable(selected);
}

/// Smoothly interpolates the chromatic color at [progress] along [milestones].
Color colorForScrubberProgress(
  double progress,
  List<ScrubberMilestone> milestones,
  Color fallback,
) {
  if (milestones.isEmpty) return fallback;
  if (milestones.length == 1) return milestones.first.color;
  final clamped = progress.clamp(0.0, 1.0);
  if (clamped <= milestones.first.progress) return milestones.first.color;
  if (clamped >= milestones.last.progress) return milestones.last.color;
  for (var index = 0; index < milestones.length - 1; index++) {
    final start = milestones[index];
    final end = milestones[index + 1];
    if (clamped <= end.progress) {
      final span = end.progress - start.progress;
      if (span <= 0) return start.color;
      return Color.lerp(
        start.color,
        end.color,
        ((clamped - start.progress) / span).clamp(0.0, 1.0),
      )!;
    }
  }
  return milestones.last.color;
}
