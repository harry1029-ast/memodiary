import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../editor/models/typography_settings.dart';
import '../../editor/services/baseline_metrics_calculator.dart';
import '../models/template_style.dart';

/// Cache key for immutable static substrate vector recordings
class _SubstratePictureCacheKey {
  final double width;
  final double height;
  final PaperSubstrate substrate;
  final Color backgroundColor;

  const _SubstratePictureCacheKey({
    required this.width,
    required this.height,
    required this.substrate,
    required this.backgroundColor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SubstratePictureCacheKey &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height &&
          substrate == other.substrate &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode => Object.hash(width, height, substrate, backgroundColor);
}

/// Procedural CustomPainter rendering diary backgrounds, ruled lines, grids,
/// margins, and paper textures with baseline-locked typographic alignment.
class TemplateCanvasPainter extends CustomPainter {
  static final Map<_SubstratePictureCacheKey, ui.Picture> _substratePictureCache = {};

  final TemplateStyle style;
  final TypographySettings? typography;
  final double scrollOffset;
  final double headerHeight;

  const TemplateCanvasPainter({
    required this.style,
    this.typography,
    this.scrollOffset = 0.0,
    this.headerHeight = 0.0,
  });

  bool get _isDark =>
      ThemeData.estimateBrightnessForColor(style.backgroundColor) == Brightness.dark;

  double get _rowHeight {
    if (typography != null) {
      return BaselineMetricsCalculator.calculateLineHeight(typography!.toTextStyle());
    }
    return 28.0 * (style.lineSpacing / 1.5).clamp(0.8, 2.5);
  }

  double get _baselineOffset {
    if (typography != null) {
      return BaselineMetricsCalculator.calculateBaselineOffset(typography!.toTextStyle());
    }
    return _rowHeight * 0.78;
  }

  double get _effectiveHeaderY => headerHeight - scrollOffset;

  (double, int) _calculateLineBounds() {
    final clipY = _effectiveHeaderY > 0 ? _effectiveHeaderY : 0.0;
    final startY = _effectiveHeaderY + _baselineOffset;
    final minLineIndex = startY < clipY
        ? ((clipY - startY) / _rowHeight).ceil()
        : 0;
    return (startY, minLineIndex);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Draw base canvas background
    final bgPaint = Paint()..color = style.backgroundColor;
    canvas.drawRect(rect, bgPaint);

    // 2. Procedural substrate texture overlays
    _paintSubstrateTexture(canvas, size);

    // 3. Grid / Lined / Geometry layer
    switch (style.type) {
      case TemplateBackgroundType.color:
        // Plain solid background
        break;

      case TemplateBackgroundType.lined:
        _paintLinedPaper(canvas, size);
        break;

      case TemplateBackgroundType.grid:
        _paintGridPaper(canvas, size);
        break;

      case TemplateBackgroundType.dotGrid:
        _paintDotGridPaper(canvas, size);
        break;

      case TemplateBackgroundType.paperTexture:
        _paintPaperTexture(canvas, size);
        break;
    }
  }

  void _paintSubstrateTexture(Canvas canvas, Size size) {
    if (style.tokens.substrate == PaperSubstrate.minimal) return;

    final key = _SubstratePictureCacheKey(
      width: size.width,
      height: size.height,
      substrate: style.tokens.substrate,
      backgroundColor: style.backgroundColor,
    );

    var picture = _substratePictureCache[key];
    if (picture == null) {
      if (_substratePictureCache.length > 20) {
        _substratePictureCache.remove(_substratePictureCache.keys.first)?.dispose();
      }
      final recorder = ui.PictureRecorder();
      final recordCanvas = Canvas(recorder, Offset.zero & size);
      _drawProceduralSubstrate(recordCanvas, size);
      picture = recorder.endRecording();
      _substratePictureCache[key] = picture;
    }

    canvas.drawPicture(picture);
  }

  void _drawProceduralSubstrate(Canvas canvas, Size size) {
    switch (style.tokens.substrate) {
      case PaperSubstrate.coldGold:
        _paintColdGoldFlecks(canvas, size);
        break;
      case PaperSubstrate.xuan:
        _paintXuanFibers(canvas, size);
        break;
      case PaperSubstrate.kraft:
        if (style.type != TemplateBackgroundType.paperTexture) {
          _paintKraftTexture(canvas, size);
        }
        break;
      case PaperSubstrate.obsidian:
        _paintObsidianShade(canvas, size);
        break;
      case PaperSubstrate.minimal:
        break;
    }
  }

  void _paintColdGoldFlecks(Canvas canvas, Size size) {
    final fleckPaint = Paint()
      ..color = const Color(0x35E0B354)
      ..style = PaintingStyle.fill;

    final fleckAccentPaint = Paint()
      ..color = const Color(0x45D4AF37)
      ..style = PaintingStyle.fill;

    const step = 38.0;
    for (double y = 14; y < size.height; y += step) {
      for (double x = 12; x < size.width; x += step) {
        final hash = ((x * 37 + y * 53) % 100).toInt();
        if (hash > 42) continue; // Sparse distribution

        final offsetX = ((hash * 13) % 25) - 12.0;
        final offsetY = ((hash * 19) % 21) - 10.0;
        final radius = (hash % 3 == 0) ? 1.8 : 1.1;
        final paint = (hash % 2 == 0) ? fleckAccentPaint : fleckPaint;

        canvas.drawCircle(Offset(x + offsetX, y + offsetY), radius, paint);
      }
    }
  }

  void _paintXuanFibers(Canvas canvas, Size size) {
    final fiberPaint = Paint()
      ..color = const Color(0x074A3728)
      ..strokeWidth = 0.8;

    const step = 48.0;
    for (double y = 16; y < size.height; y += step) {
      for (double x = 16; x < size.width; x += step) {
        final hash = ((x * 19 + y * 41) % 100).toInt();
        if (hash > 35) continue;

        final dx = ((hash * 7) % 15) - 7.0;
        final dy = ((hash * 11) % 11) - 5.0;
        final len = ((hash * 13) % 10) + 4.0;
        canvas.drawLine(
          Offset(x + dx, y + dy),
          Offset(x + dx + len, y + dy + (hash % 2 == 0 ? 0.8 : -0.8)),
          fiberPaint,
        );
      }
    }
  }

  void _paintObsidianShade(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.1,
        colors: const [
          Colors.transparent,
          Color(0x28000000),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);
  }

  void _paintKraftTexture(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: const [
          Colors.transparent,
          Color(0x184E342E),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);
  }

  void _paintLinedPaper(Canvas canvas, Size size) {
    final rowHeight = _rowHeight;
    final clipY = _effectiveHeaderY > 0 ? _effectiveHeaderY : 0.0;
    final (startY, minLineIndex) = _calculateLineBounds();

    final linePaint = Paint()
      ..color = _isDark
          ? const Color(0x18FFFFFF)
          : style.tokens.ruleTint.color
      ..strokeWidth = 1.0;

    for (int lineIndex = minLineIndex; ; lineIndex++) {
      final y = startY + lineIndex * rowHeight;
      if (y > size.height) break;
      if (y < clipY) continue;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Left vertical margin line (classic notebook red rule or tint)
    final marginPaint = Paint()
      ..color = _isDark
          ? const Color(0x38EF9A9A)
          : (style.tokens.ruleTint == RuleInkTint.vermilion
              ? const Color(0x52C04851)
              : const Color(0x33E57373))
      ..strokeWidth = 1.2;

    final marginX = style.resolvedHorizontalMargin;
    final topY = math.max(0.0, _effectiveHeaderY);
    canvas.drawLine(
      Offset(marginX, topY),
      Offset(marginX, size.height),
      marginPaint,
    );
  }

  (List<double>, double, double) _computeSnappedGridX(double width, double marginX, double step) {
    final availWidth = width - 2 * marginX;
    final numCols = math.max(1, (availWidth / step).floor());
    final gridWidth = numCols * step;
    final xStart = marginX + (availWidth - gridWidth) / 2.0;

    final xCoords = <double>[];
    for (int i = 0; i <= numCols; i++) {
      xCoords.add(xStart + i * step);
    }
    return (xCoords, xStart, xStart + gridWidth);
  }

  void _paintGridPaper(Canvas canvas, Size size) {
    final rowHeight = _rowHeight;
    final marginX = style.resolvedHorizontalMargin;
    final clipY = _effectiveHeaderY > 0 ? _effectiveHeaderY : 0.0;

    final hGridPaint = Paint()
      ..color = _isDark ? const Color(0x18FFFFFF) : style.tokens.ruleTint.color
      ..strokeWidth = 0.8;

    final vGridPaint = Paint()
      ..color = _isDark
          ? const Color(0x12FFFFFF)
          : style.tokens.ruleTint.color.withValues(alpha: (style.tokens.ruleTint.color.a * 0.85))
      ..strokeWidth = 0.6;

    final topY = math.max(0.0, _effectiveHeaderY);
    final (xCoords, xStart, xEnd) = _computeSnappedGridX(size.width, marginX, rowHeight);

    // Vertical grid guidelines snapped within inner grid frame
    for (final x in xCoords) {
      canvas.drawLine(Offset(x, topY), Offset(x, size.height), vGridPaint);
    }

    // Horizontal grid rules forming uniform H x H squares starting below header
    final minRowIndex = math.max(1, ((clipY - _effectiveHeaderY) / rowHeight).ceil());
    for (int rowIndex = minRowIndex; ; rowIndex++) {
      final y = _effectiveHeaderY + rowIndex * rowHeight;
      if (y > size.height) break;
      canvas.drawLine(Offset(xStart, y), Offset(xEnd, y), hGridPaint);
    }
  }

  void _paintDotGridPaper(Canvas canvas, Size size) {
    final rowHeight = _rowHeight;
    final marginX = style.resolvedHorizontalMargin;
    final clipY = _effectiveHeaderY > 0 ? _effectiveHeaderY : 0.0;

    final dotPaint = Paint()
      ..color = _isDark ? const Color(0x24FFFFFF) : style.tokens.ruleTint.color
      ..style = PaintingStyle.fill;

    final (xCoords, _, _) = _computeSnappedGridX(size.width, marginX, rowHeight);
    final minRowIndex = math.max(1, ((clipY - _effectiveHeaderY) / rowHeight).ceil());

    for (int rowIndex = minRowIndex; ; rowIndex++) {
      final y = _effectiveHeaderY + rowIndex * rowHeight;
      if (y > size.height) break;

      for (final x in xCoords) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  void _paintPaperTexture(Canvas canvas, Size size) {
    // 1. Soft vignette aging effect around borders
    _paintKraftTexture(canvas, size);

    // 2. Procedural paper fibers & specks (deterministic pseudo-random loop)
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

    // 3. Faint warm kraft guidelines aligned to baseline
    final guidePaint = Paint()
      ..color = const Color(0x148D6E63)
      ..strokeWidth = 0.9;

    final rowHeight = _rowHeight;
    final marginX = style.marginHorizontal.clamp(16.0, 36.0);
    final clipY = _effectiveHeaderY > 0 ? _effectiveHeaderY : 0.0;
    final (startY, minLineIndex) = _calculateLineBounds();

    for (int lineIndex = minLineIndex; ; lineIndex++) {
      final y = startY + lineIndex * rowHeight;
      if (y > size.height) break;
      if (y < clipY) continue;
      canvas.drawLine(
        Offset(marginX, y),
        Offset(size.width - marginX, y),
        guidePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TemplateCanvasPainter oldDelegate) {
    return oldDelegate.style.type != style.type ||
        oldDelegate.style.backgroundColor != style.backgroundColor ||
        oldDelegate.style.lineSpacing != style.lineSpacing ||
        oldDelegate.style.marginHorizontal != style.marginHorizontal ||
        oldDelegate.style.tokens.substrate != style.tokens.substrate ||
        oldDelegate.style.tokens.ruleTint != style.tokens.ruleTint ||
        oldDelegate.style.tokens.sealStyle != style.tokens.sealStyle ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.headerHeight != headerHeight ||
        oldDelegate.typography?.fontId != typography?.fontId ||
        oldDelegate.typography?.fontFamily != typography?.fontFamily ||
        oldDelegate.typography?.fontSize != typography?.fontSize ||
        oldDelegate.typography?.lineSpacing != typography?.lineSpacing;
  }
}
