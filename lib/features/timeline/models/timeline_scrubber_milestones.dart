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

/// Builds a 5-stop muted mineral/ink progression anchored to
/// `palette.accentPrimary` and `palette.accentSecondary`, calibrated for light
/// and dark [AtmospherePalette]s while strictly excluding `palette.sealAccent`.
List<Color> buildScrubberChromaticPalette(AtmospherePalette palette) {
  final isDark = palette.brightness == Brightness.dark;
  final primaryHsl = HSLColor.fromColor(palette.accentPrimary);
  final secondaryHsl = HSLColor.fromColor(palette.accentSecondary);
  final rawDelta = ((secondaryHsl.hue - primaryHsl.hue + 540.0) % 360.0) - 180.0;
  final effectiveDelta =
      rawDelta.abs() < 15.0 ? (rawDelta >= 0 ? 32.0 : -32.0) : rawDelta;
  final direction = effectiveDelta >= 0 ? 1.0 : -1.0;

  final baseSaturations = isDark
      ? const [0.46, 0.42, 0.48, 0.40, 0.36]
      : const [0.40, 0.36, 0.42, 0.34, 0.30];
  final targetLightnesses = isDark
      ? const [0.68, 0.66, 0.70, 0.64, 0.62]
      : const [0.38, 0.40, 0.37, 0.39, 0.35];
  final hues = <double>[
    primaryHsl.hue,
    (primaryHsl.hue + effectiveDelta * 0.5) % 360.0,
    (primaryHsl.hue + effectiveDelta) % 360.0,
    (primaryHsl.hue + effectiveDelta + direction * 34.0) % 360.0,
    (primaryHsl.hue + effectiveDelta + direction * 68.0) % 360.0,
  ];

  final stops = <Color>[];
  for (var index = 0; index < 5; index++) {
    final sourceSat = index < 2
        ? primaryHsl.saturation
        : (index == 2
            ? secondaryHsl.saturation
            : (primaryHsl.saturation + secondaryHsl.saturation) / 2);
    final saturation = ((sourceSat * 0.45) + (baseSaturations[index] * 0.55))
        .clamp(0.18, isDark ? 0.56 : 0.50);
    var color = HSLColor.fromAHSL(
      1.0,
      (hues[index] + 360.0) % 360.0,
      saturation,
      targetLightnesses[index],
    ).toColor();
    if (color == palette.sealAccent || stops.contains(color)) {
      color = Color.lerp(color, palette.textSecondary, 0.16)!;
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
