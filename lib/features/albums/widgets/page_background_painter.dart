import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/album_studio_models.dart';
import '../services/album_theme_catalog.dart';

/// Procedural vector background painter that renders a page's [PageBackgroundConfig]
/// including solid paper fills and delicate botanical, abstract, summer, rainbow,
/// or literati ink motifs.
class PageBackgroundPainter extends CustomPainter {
  final PageBackgroundConfig config;

  const PageBackgroundPainter({
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..color = Color(config.backgroundColorArgb)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, bgPaint);

    final patternId = config.graphicPatternId;
    if (patternId == null || patternId == 'none' || patternId.isEmpty) {
      return;
    }

    canvas.save();
    canvas.clipRect(rect);

    switch (patternId) {
      case 'ink_bamboo_mountains':
        _paintInkBambooMountains(canvas, size);
        break;
      case 'floral_allover':
        _paintFloralAllover(canvas, size);
        break;
      case 'corner_vines':
        _paintCornerVines(canvas, size);
        break;
      case 'bottom_left_sprig':
        _paintBottomLeftSprig(canvas, size);
        break;
      case 'bottom_right_bloom':
        _paintBottomRightBloom(canvas, size);
        break;
      case 'abstract_fluid':
        _paintAbstractFluid(canvas, size);
        break;
      case 'beach_lemon_palm':
        _paintBeachLemonPalm(canvas, size);
        break;
      case 'rainbow_paper_plane':
        _paintRainbowPaperPlane(canvas, size);
        break;
      default:
        break;
    }

    canvas.restore();
  }

  void _paintInkBambooMountains(Canvas canvas, Size size) {
    final accentColor = Color(config.textColorArgb);

    // Subtle double hairline literati frame
    final outerBorder = Paint()
      ..color = accentColor.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final innerBorder = Paint()
      ..color = accentColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final inset1 = size.shortestSide * 0.022;
    final inset2 = size.shortestSide * 0.030;
    canvas.drawRect(
      Rect.fromLTWH(
        inset1,
        inset1,
        size.width - inset1 * 2,
        size.height - inset1 * 2,
      ),
      outerBorder,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        inset2,
        inset2,
        size.width - inset2 * 2,
        size.height - inset2 * 2,
      ),
      innerBorder,
    );

    // Distant wash mountains along the bottom horizon
    final mountainPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.78,
        size.width * 0.45,
        size.height * 0.87,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.74,
        size.width,
        size.height * 0.85,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      mountainPath,
      Paint()
        ..color = accentColor.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );

    // Top-right ink bamboo sprig
    _drawSprigBranch(
      canvas,
      start: Offset(size.width * 0.94, size.height * 0.04),
      end: Offset(size.width * 0.78, size.height * 0.20),
      stemColor: accentColor.withValues(alpha: 0.22),
      leafColor: accentColor.withValues(alpha: 0.16),
      leafCount: 5,
    );
  }

  void _paintFloralAllover(Canvas canvas, Size size) {
    final vinePaint = Paint()
      ..color = const Color(0xFF5D7A68).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rows = 4;
    final cols = 4;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final centerX = (c + 0.5) * cellW;
        final centerY = (r + 0.5) * cellH;
        final path = Path()
          ..moveTo(centerX - cellW * 0.35, centerY + cellH * 0.25)
          ..cubicTo(
            centerX - cellW * 0.1,
            centerY - cellH * 0.3,
            centerX + cellW * 0.1,
            centerY + cellH * 0.3,
            centerX + cellW * 0.35,
            centerY - cellH * 0.25,
          );
        canvas.drawPath(path, vinePaint);

        final isRose = (r + c).isEven;
        _drawBlossom(
          canvas,
          center: Offset(centerX, centerY),
          radius: math.min(cellW, cellH) * 0.16,
          petalColor: isRose
              ? const Color(0xFFD97F76).withValues(alpha: 0.35)
              : const Color(0xFF6B8EA4).withValues(alpha: 0.35),
          coreColor: const Color(0xFFE6B85C).withValues(alpha: 0.55),
        );
      }
    }
  }

  void _paintCornerVines(Canvas canvas, Size size) {
    // Top-right vine & blossoms (Journi Image 8 tile 2)
    _drawSprigBranch(
      canvas,
      start: Offset(size.width * 0.98, size.height * 0.02),
      end: Offset(size.width * 0.72, size.height * 0.26),
      stemColor: const Color(0xFF4F6F64).withValues(alpha: 0.45),
      leafColor: const Color(0xFF5E8577).withValues(alpha: 0.35),
      leafCount: 6,
    );
    _drawBlossom(
      canvas,
      center: Offset(size.width * 0.86, size.height * 0.12),
      radius: size.shortestSide * 0.035,
      petalColor: const Color(0xFFD47A72).withValues(alpha: 0.45),
      coreColor: const Color(0xFFE5B95C).withValues(alpha: 0.65),
    );

    // Bottom-left vine & blossoms
    _drawSprigBranch(
      canvas,
      start: Offset(size.width * 0.02, size.height * 0.98),
      end: Offset(size.width * 0.28, size.height * 0.74),
      stemColor: const Color(0xFF4F6F64).withValues(alpha: 0.45),
      leafColor: const Color(0xFF5E8577).withValues(alpha: 0.35),
      leafCount: 6,
    );
    _drawBlossom(
      canvas,
      center: Offset(size.width * 0.14, size.height * 0.88),
      radius: size.shortestSide * 0.035,
      petalColor: const Color(0xFF728FB5).withValues(alpha: 0.45),
      coreColor: const Color(0xFFE5B95C).withValues(alpha: 0.65),
    );
  }

  void _paintBottomLeftSprig(Canvas canvas, Size size) {
    _drawSprigBranch(
      canvas,
      start: Offset(size.width * 0.02, size.height * 0.98),
      end: Offset(size.width * 0.24, size.height * 0.76),
      stemColor: const Color(0xFF59786C).withValues(alpha: 0.45),
      leafColor: const Color(0xFF789C8E).withValues(alpha: 0.38),
      leafCount: 5,
    );
    _drawBlossom(
      canvas,
      center: Offset(size.width * 0.11, size.height * 0.89),
      radius: size.shortestSide * 0.032,
      petalColor: const Color(0xFFD98279).withValues(alpha: 0.48),
      coreColor: const Color(0xFFE8BC61).withValues(alpha: 0.7),
    );
  }

  void _paintBottomRightBloom(Canvas canvas, Size size) {
    _drawSprigBranch(
      canvas,
      start: Offset(size.width * 0.98, size.height * 0.98),
      end: Offset(size.width * 0.74, size.height * 0.72),
      stemColor: const Color(0xFF4F6D62).withValues(alpha: 0.48),
      leafColor: const Color(0xFF6B8E80).withValues(alpha: 0.38),
      leafCount: 6,
    );
    _drawBlossom(
      canvas,
      center: Offset(size.width * 0.86, size.height * 0.85),
      radius: size.shortestSide * 0.045,
      petalColor: const Color(0xFFC96E78).withValues(alpha: 0.5),
      coreColor: const Color(0xFFEBC067).withValues(alpha: 0.75),
    );
  }

  void _paintAbstractFluid(Canvas canvas, Size size) {
    // Organic blue shapes (Journi Image 7 Abstract Blue)
    final topRightBlob = Path()
      ..moveTo(size.width * 0.55, 0)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.24,
        size.width * 0.75,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.30,
        size.width,
        size.height * 0.16,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(
      topRightBlob,
      Paint()
        ..color = const Color(0xFF5669AF).withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );

    final bottomLeftBlob = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.68,
        size.width * 0.32,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      bottomLeftBlob,
      Paint()
        ..color = const Color(0xFFAEC7DF).withValues(alpha: 0.32)
        ..style = PaintingStyle.fill,
    );

    // Delicate white/blue botanical line art over the blob
    _drawSprigBranch(
      canvas,
      start: Offset(size.width * 0.70, size.height * 0.25),
      end: Offset(size.width * 0.88, size.height * 0.06),
      stemColor: const Color(0xFF2E437A).withValues(alpha: 0.35),
      leafColor: const Color(0xFF2E437A).withValues(alpha: 0.25),
      leafCount: 4,
    );
  }

  void _paintBeachLemonPalm(Canvas canvas, Size size) {
    // Sunny yellow horizontal brush stripes on top-left (Journi Image 7 Day at the beach)
    final stripePaint = Paint()
      ..color = const Color(0xFFF7D038).withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.025;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.06 + i * 0.045);
      canvas.drawLine(
        Offset(size.width * 0.03, y),
        Offset(size.width * 0.26, y),
        stripePaint,
      );
    }

    // Citrus lemon oval
    canvas.save();
    canvas.translate(size.width * 0.22, size.height * 0.22);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.shortestSide * 0.14,
        height: size.shortestSide * 0.10,
      ),
      Paint()..color = const Color(0xFFF5C728).withValues(alpha: 0.45),
    );
    canvas.restore();

    // Aqua palm fronds at top-right
    final palmCenter = Offset(size.width * 0.76, size.height * 0.04);
    final frondPaint = Paint()
      ..color = const Color(0xFF5DC2B8).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    for (var angle = 0.3; angle <= 2.7; angle += 0.35) {
      final dx = math.cos(angle) * size.shortestSide * 0.18;
      final dy = math.sin(angle) * size.shortestSide * 0.18;
      canvas.drawLine(palmCenter, palmCenter + Offset(dx, dy), frondPaint);
    }
  }

  void _paintRainbowPaperPlane(Canvas canvas, Size size) {
    // Soft horizontal pastel rainbow lines (Journi Image 7 Playful Rainbow)
    final colors = [
      const Color(0xFFF7B2C4),
      const Color(0xFFFAD89E),
      const Color(0xFFA7D8F0),
    ];

    for (var i = 0; i < colors.length; i++) {
      final y = size.height * (0.14 + i * 0.025);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = colors[i].withValues(alpha: 0.45)
          ..strokeWidth = 2.2,
      );
    }

    // Paper plane silhouette in top-left
    final planePath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.07)
      ..lineTo(size.width * 0.26, size.height * 0.13)
      ..lineTo(size.width * 0.14, size.height * 0.16)
      ..lineTo(size.width * 0.11, size.height * 0.21)
      ..close();

    canvas.drawPath(
      planePath,
      Paint()
        ..color = const Color(0xFF7B90C9).withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      planePath,
      Paint()
        ..color = const Color(0xFF4B629E).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawSprigBranch(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required Color stemColor,
    required Color leafColor,
    required int leafCount,
  }) {
    final stemPaint = Paint()
      ..color = stemColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;

    final mid = Offset(
      (start.dx + end.dx) / 2 + (end.dy - start.dy) * 0.12,
      (start.dy + end.dy) / 2 - (end.dx - start.dx) * 0.12,
    );

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
    canvas.drawPath(path, stemPaint);

    final leafPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.fill;

    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final length = (end - start).distance;
    final leafSize = length * 0.14;

    for (var i = 1; i <= leafCount; i++) {
      final t = i / (leafCount + 1);
      final lx = start.dx + (end.dx - start.dx) * t;
      final ly = start.dy + (end.dy - start.dy) * t;
      final side = i.isEven ? 1.0 : -1.0;

      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(angle + side * 0.65);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(leafSize * 0.5, 0),
          width: leafSize,
          height: leafSize * 0.42,
        ),
        leafPaint,
      );
      canvas.restore();
    }
  }

  void _drawBlossom(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color petalColor,
    required Color coreColor,
  }) {
    final petalPaint = Paint()
      ..color = petalColor
      ..style = PaintingStyle.fill;

    const petals = 6;
    for (var i = 0; i < petals; i++) {
      final theta = (i * 2 * math.pi) / petals;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(theta);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(radius * 0.55, 0),
          width: radius * 0.9,
          height: radius * 0.55,
        ),
        petalPaint,
      );
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      radius * 0.28,
      Paint()..color = coreColor,
    );
  }

  @override
  bool shouldRepaint(covariant PageBackgroundPainter oldDelegate) {
    return oldDelegate.config != config;
  }
}

/// CustomPainter rendering individual vector stickers from [StickerCatalog].
class StickerElementPainter extends CustomPainter {
  final String stickerId;
  final int? colorOverrideArgb;

  const StickerElementPainter({
    required this.stickerId,
    this.colorOverrideArgb,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final preset = StickerCatalog.getById(stickerId);
    final color = Color(colorOverrideArgb ?? preset.defaultColorArgb);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.42;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(1.8, size.shortestSide * 0.055);

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    switch (preset.category) {
      case StickerCategory.flora:
        // 8-petal flower icon (matching Journi Image 9 bottom-left button)
        for (var i = 0; i < 8; i++) {
          final angle = (i * math.pi) / 4;
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(angle);
          final petalRect = Rect.fromCenter(
            center: Offset(radius * 0.48, 0),
            width: radius * 0.65,
            height: radius * 0.36,
          );
          canvas.drawOval(petalRect, fillPaint);
          canvas.drawOval(petalRect, strokePaint);
          canvas.restore();
        }
        canvas.drawCircle(center, radius * 0.20, strokePaint);
        break;

      case StickerCategory.travel:
        // Map pin card (matching Journi Image 9 bottom-center button)
        final cardRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: size.width * 0.84,
            height: size.height * 0.68,
          ),
          Radius.circular(size.shortestSide * 0.12),
        );
        canvas.drawRRect(cardRect, fillPaint);
        canvas.drawRRect(cardRect, strokePaint);
        canvas.drawCircle(
          Offset(center.dx, center.dy - radius * 0.14),
          radius * 0.24,
          strokePaint,
        );
        break;

      case StickerCategory.weather:
        // Weather & sun postcard (matching Journi Image 9 bottom-right button)
        final cardRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: size.width * 0.86,
            height: size.height * 0.68,
          ),
          Radius.circular(size.shortestSide * 0.12),
        );
        canvas.drawRRect(cardRect, fillPaint);
        canvas.drawRRect(cardRect, strokePaint);
        canvas.drawCircle(
          Offset(center.dx - radius * 0.32, center.dy - radius * 0.08),
          radius * 0.22,
          strokePaint,
        );
        break;

      case StickerCategory.washi:
        final tapeRect = Rect.fromCenter(
          center: center,
          width: size.width * 0.90,
          height: size.height * 0.38,
        );
        canvas.drawRect(
          tapeRect,
          Paint()
            ..color = color.withValues(alpha: 0.45)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(tapeRect, strokePaint);
        break;

      case StickerCategory.stamp:
        final sealRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: radius * 1.5,
            height: radius * 1.5,
          ),
          Radius.circular(radius * 0.18),
        );
        canvas.drawRRect(sealRect, fillPaint);
        canvas.drawRRect(sealRect, strokePaint);
        break;

      case StickerCategory.datePill:
        final pillRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: size.width * 0.90,
            height: size.height * 0.44,
          ),
          Radius.circular(size.height * 0.22),
        );
        canvas.drawRRect(pillRect, fillPaint);
        canvas.drawRRect(pillRect, strokePaint);
        canvas.drawCircle(
          Offset(center.dx - size.width * 0.30, center.dy),
          radius * 0.16,
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx - size.width * 0.16, center.dy),
          Offset(center.dx + size.width * 0.34, center.dy),
          strokePaint..strokeWidth = math.max(1.2, size.shortestSide * 0.04),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant StickerElementPainter oldDelegate) {
    return oldDelegate.stickerId != stickerId ||
        oldDelegate.colorOverrideArgb != colorOverrideArgb;
  }
}

