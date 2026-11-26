import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/timeline/models/timeline_scrubber_milestones.dart';

/// Paints the `5.5dp` continuous chromatic mineral gradient rail, `0.5dp`
/// `deckleBorder` outline, and `7dp` hollow ring milestone nodes.
class ChromaticScrubberRailPainter extends CustomPainter {
  static const double railWidth = 5.5;
  static const double nodeRadius = 2.5;
  static const double nodeStrokeWidth = 2.0;
  static const double railCenterFromRight = 9.0;

  final List<Color> chromaticPalette;
  final List<ScrubberMilestone> allMilestones;
  final List<ScrubberMilestone> nodeMilestones;
  final AtmospherePalette palette;
  final double topInset;
  final double bottomInset;

  const ChromaticScrubberRailPainter({
    required this.chromaticPalette,
    required this.allMilestones,
    required this.nodeMilestones,
    required this.palette,
    required this.topInset,
    required this.bottomInset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final usableHeight = math.max(1.0, size.height - topInset - bottomInset);
    final centerX = size.width - railCenterFromRight;
    final railRect = Rect.fromLTWH(
      centerX - railWidth / 2,
      topInset - railWidth / 2,
      railWidth,
      usableHeight + railWidth,
    );
    final railRRect = RRect.fromRectAndRadius(railRect, const Radius.circular(railWidth / 2));
    final (colors, stops) = _resolveGradientStops();
    canvas.drawRRect(
      railRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(railRect),
    );
    canvas.drawRRect(
      railRRect,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5..color = palette.deckleBorder,
    );

    final nodeFill = Paint()..color = palette.cardPaper;
    final nodeRing = Paint()..style = PaintingStyle.stroke..strokeWidth = nodeStrokeWidth;
    for (final milestone in nodeMilestones) {
      final center = Offset(centerX, topInset + milestone.progress.clamp(0.0, 1.0) * usableHeight);
      canvas.drawCircle(center, nodeRadius, nodeFill);
      nodeRing.color = milestone.color;
      canvas.drawCircle(center, nodeRadius, nodeRing);
    }
  }

  (List<Color>, List<double>) _resolveGradientStops() {
    if (allMilestones.length >= 2) {
      final colors = <Color>[];
      final stops = <double>[];
      for (final milestone in allMilestones) {
        final stop = milestone.progress.clamp(0.0, 1.0);
        if (stops.isNotEmpty && stop < stops.last) continue;
        colors.add(milestone.color);
        stops.add(stop);
      }
      if (stops.isNotEmpty && stops.first > 0.0) {
        colors.insert(0, colors.first);
        stops.insert(0, 0.0);
      }
      if (stops.isNotEmpty && stops.last < 1.0) {
        colors.add(colors.last);
        stops.add(1.0);
      }
      if (colors.length >= 2) return (colors, stops);
    }
    if (chromaticPalette.length >= 2) {
      final count = chromaticPalette.length;
      return (chromaticPalette, [for (var index = 0; index < count; index++) index / (count - 1)]);
    }
    return ([palette.accentPrimary, palette.accentSecondary], const [0.0, 1.0]);
  }

  @override
  bool shouldRepaint(covariant ChromaticScrubberRailPainter oldDelegate) {
    return oldDelegate.palette != palette ||
        oldDelegate.topInset != topInset ||
        oldDelegate.bottomInset != bottomInset ||
        !listEquals(oldDelegate.chromaticPalette, chromaticPalette) ||
        !listEquals(oldDelegate.allMilestones, allMilestones) ||
        !listEquals(oldDelegate.nodeMilestones, nodeMilestones);
  }
}

/// Hollow ring bead thumb (`14dp` resting / `18dp` active) centered within the
/// `44dp` vertical scrubber thumb slot.
class ScrubberHollowRingThumb extends StatelessWidget {
  static const double restingSize = 14.0;
  static const double activeSize = 18.0;

  final bool isActive;
  final Color activeColor;
  final AtmospherePalette palette;
  final double thumbHeight;
  final Duration animationDuration;

  const ScrubberHollowRingThumb({
    super.key, required this.isActive, required this.activeColor,
    required this.palette, required this.thumbHeight, required this.animationDuration,
  });

  @override
  Widget build(BuildContext context) {
    final beadSize = isActive ? activeSize : restingSize;
    return SizedBox(
      key: const Key('timeline_scrubber_thumb'),
      height: thumbHeight,
      width: activeSize,
      child: Center(
        child: AnimatedContainer(
          key: const Key('timeline_scrubber_thumb_bead'),
          duration: animationDuration,
          width: beadSize,
          height: beadSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.cardPaper,
            border: Border.all(color: activeColor, width: 3.0),
            boxShadow: [BoxShadow(color: palette.slipShadowColor, blurRadius: 4, offset: const Offset(0, 1))],
          ),
        ),
      ),
    );
  }
}

/// Two-stage milestone orientation overlay rendered on press-hold or drag,
/// featuring a `~72dp` right-edge `deskMat` scrim and compact chips that fade
/// away when within `34dp` vertically of the active `YYYY年M月` plaque.
class ScrubberMilestoneOverlay extends StatelessWidget {
  static const double scrimWidth = 72.0;
  static const double chipHeight = 22.0;
  static const double collisionDistance = 34.0;

  final List<ScrubberMilestone> labelMilestones;
  final double trackHeight, topInset, usableHeight, hitStripWidth, rightEdgeInset;
  final bool isDragging;
  final double? plaqueCenterY;
  final AtmospherePalette palette;
  final Duration fadeDuration;

  const ScrubberMilestoneOverlay({
    super.key, required this.labelMilestones, required this.trackHeight,
    required this.topInset, required this.usableHeight, required this.hitStripWidth,
    required this.rightEdgeInset, required this.isDragging, required this.plaqueCenterY,
    required this.palette, required this.fadeDuration,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0, bottom: 0, right: -rightEdgeInset, width: scrimWidth + rightEdgeInset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [palette.deskMat.withValues(alpha: 0.65), palette.deskMat.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ),
          for (var index = 0; index < labelMilestones.length; index++)
            _buildMilestoneChip(index, labelMilestones[index]),
        ],
      ),
    );
  }

  Widget _buildMilestoneChip(int index, ScrubberMilestone milestone) {
    final targetY = topInset + milestone.progress.clamp(0.0, 1.0) * usableHeight;
    final chipTop = (targetY - chipHeight / 2).clamp(0.0, math.max(0.0, trackHeight - chipHeight)).toDouble();
    final isColliding = isDragging &&
        plaqueCenterY != null &&
        ((chipTop + chipHeight / 2) - plaqueCenterY!).abs() <= collisionDistance;

    return Positioned(
      right: hitStripWidth + 4.0,
      top: chipTop,
      child: AnimatedOpacity(
        opacity: isColliding ? 0.0 : 1.0,
        duration: fadeDuration,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80, minHeight: chipHeight),
            child: Container(
              key: Key('timeline_scrubber_milestone_chip_$index'),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: palette.cardPaper.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.deckleBorder, width: 0.8),
                boxShadow: [BoxShadow(color: palette.slipShadowColor, blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Text(
                milestone.label, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 11,
                  fontWeight: FontWeight.w600, color: milestone.color, height: 1.25,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating `YYYY年M月` date plaque paired with a matching chromatic hollow ring dot.
class FloatingMonthPlaque extends StatelessWidget {
  final String monthLabel;
  final Color activeColor;
  final AtmospherePalette palette;
  final double minHeight;

  const FloatingMonthPlaque({
    super.key, required this.monthLabel, required this.activeColor,
    required this.palette, required this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 160, minHeight: minHeight),
          child: Container(
            key: const Key('timeline_scrubber_plaque'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: palette.cardPaper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.deckleBorder, width: 1.0),
              boxShadow: [BoxShadow(color: palette.slipShadowColor, blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9, height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: palette.cardPaper,
                    border: Border.all(color: activeColor, width: 2.5),
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    monthLabel, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif, fontSize: 13,
                      fontWeight: FontWeight.w600, color: palette.textPrimary, letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
