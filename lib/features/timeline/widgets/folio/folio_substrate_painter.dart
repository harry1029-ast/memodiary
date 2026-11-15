import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paints raw Xuan paper fibers (`生宣纸肌理`), shimmering Cold Gold flecks (`冷金笺泥金洒粉`),
/// and the left spine gutter crease shadow.
///
/// Ambient shimmering animations are guarded by [enableShimmer], which defaults to false
/// in widget test environments (`Platform.environment['FLUTTER_TEST'] == 'true'`) so
/// `pumpAndSettle()` settles deterministically.
class FolioSubstratePainter extends CustomPainter {
  /// Whether to render dispersed gold dust flecks across the paper surface.
  final bool showGoldFlecks;

  /// Normalized breathing shimmer progress (0.0 to 1.0).
  final double shimmerProgress;

  /// Whether the substrate represents a dark night palette (e.g. Obsidian).
  final bool isDark;

  /// Whether breathing shimmer animation is active.
  final bool enableShimmer;

  /// Whether to paint the left spine gutter crease shadow.
  final bool drawGutterShadow;

  /// Whether to paint warm Retro Kraft radial vignette and paper fibers.
  final bool showKraftTexture;

  FolioSubstratePainter({
    required this.showGoldFlecks,
    this.shimmerProgress = 0.0,
    required this.isDark,
    bool? enableShimmer,
    this.drawGutterShadow = true,
    this.showKraftTexture = false,
  }) : enableShimmer = enableShimmer ??
            (Platform.environment['FLUTTER_TEST'] != 'true');

  @override
  void paint(Canvas canvas, Size size) {
    // Seeded random for deterministic fiber & gold particle distribution
    final random = math.Random(108);

    // 1. Paper surface texture (Retro Kraft fibers/vignette or raw Xuan specks)
    if (showKraftTexture) {
      _paintKraftTexture(canvas, size);
    } else {
      final fiberPaint = Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.025)
            : const Color(0xFF785F41).withValues(alpha: 0.06);

      for (int fiberIndex = 0; fiberIndex < 65; fiberIndex++) {
        final dxCoordinate = random.nextDouble() * size.width;
        final dyCoordinate = random.nextDouble() * size.height;
        canvas.drawCircle(Offset(dxCoordinate, dyCoordinate), 0.9, fiberPaint);
      }
    }

    // 2. Shimmering Cold Gold Flecks (`冷金笺洒粉`)
    if (showGoldFlecks) {
      final effectiveShimmer = enableShimmer ? shimmerProgress : 0.0;
      final opacityBase = 0.35 + 0.45 * effectiveShimmer;
      final goldPaint = Paint()
        ..color = const Color(0xFFD4A537).withValues(alpha: opacityBase);

      for (int goldIndex = 0; goldIndex < 28; goldIndex++) {
        final dxCoordinate = random.nextDouble() * size.width;
        final dyCoordinate = random.nextDouble() * size.height;
        final radius = 1.0 + random.nextDouble() * 1.6;
        canvas.drawCircle(Offset(dxCoordinate, dyCoordinate), radius, goldPaint);
      }
    }

    // 3. Left Spine Gutter Crease Shadow
    if (drawGutterShadow) {
      final gutterRect = Rect.fromLTWH(0, 0, 26, size.height);
      canvas.drawRect(
        gutterRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0x52000000),
              Color(0x1F000000),
              Colors.transparent,
            ],
            stops: [0.0, 0.45, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(gutterRect),
      );
    }
  }

  void _paintKraftTexture(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final vignettePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: [
          Colors.transparent,
          Color(0x184E342E),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);

    final fiberPaint = Paint()
      ..color = const Color(0x0C3E2723)
      ..strokeWidth = 1.0;

    const step = 45.0;
    for (double y = 10; y < size.height; y += step) {
      for (double x = 10; x < size.width; x += step) {
        final dx = ((x * 17 + y * 31) % 15) - 7;
        final dy = ((x * 23 + y * 13) % 9) - 4;
        final length = ((x * 7 + y * 11) % 12) + 3;
        canvas.drawLine(
          Offset(x + dx, y + dy),
          Offset(x + dx + length, y + dy + (dx.abs() > 4 ? 1 : 0)),
          fiberPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant FolioSubstratePainter oldDelegate) {
    return oldDelegate.showGoldFlecks != showGoldFlecks ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.enableShimmer != enableShimmer ||
        oldDelegate.drawGutterShadow != drawGutterShadow ||
        oldDelegate.showKraftTexture != showKraftTexture;
  }
}
