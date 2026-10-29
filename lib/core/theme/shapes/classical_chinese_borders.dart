import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 1. Begonia Cut-Corner Plaque ShapeBorder (海棠切角匾额边框)
///
/// An 8-point polygon border that chamfers the 4 corners of a rectangle by [cutSize],
/// reminiscent of imperial Chinese architectural plaques, porcelain window frames,
/// and classic seal tablets.
class BegoniaPlaqueBorder extends ShapeBorder {
  final double cutSize;
  final Color borderColor;
  final double borderWidth;
  final double innerBorderInset;
  final Color? innerBorderColor;
  final double innerBorderWidth;

  const BegoniaPlaqueBorder({
    this.cutSize = 7.0,
    this.borderColor = Colors.transparent,
    this.borderWidth = 1.0,
    this.innerBorderInset = 0.0,
    this.innerBorderColor,
    this.innerBorderWidth = 1.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  Path _buildPolygon(Rect rect, double cut) {
    final effectiveCut = math.min(cut, math.min(rect.width, rect.height) / 2);
    final left = rect.left;
    final top = rect.top;
    final right = rect.right;
    final bottom = rect.bottom;

    return Path()
      ..moveTo(left + effectiveCut, top)
      ..lineTo(right - effectiveCut, top)
      ..lineTo(right, top + effectiveCut)
      ..lineTo(right, bottom - effectiveCut)
      ..lineTo(right - effectiveCut, bottom)
      ..lineTo(left + effectiveCut, bottom)
      ..lineTo(left, bottom - effectiveCut)
      ..lineTo(left, top + effectiveCut)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _buildPolygon(rect, cutSize);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final deflated = rect.deflate(borderWidth);
    return _buildPolygon(deflated, math.max(0, cutSize - borderWidth));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (borderWidth > 0 && borderColor.a > 0) {
      final paint = Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(getOuterPath(rect), paint);
    }

    if (innerBorderInset > 0 && innerBorderColor != null && innerBorderColor!.a > 0) {
      final innerRect = rect.deflate(innerBorderInset);
      final innerCut = math.max(2.0, cutSize - innerBorderInset);
      final innerPath = _buildPolygon(innerRect, innerCut);

      final innerPaint = Paint()
        ..color = innerBorderColor!
        ..strokeWidth = innerBorderWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(innerPath, innerPaint);
    }
  }

  @override
  ShapeBorder scale(double t) {
    return BegoniaPlaqueBorder(
      cutSize: cutSize * t,
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      innerBorderInset: innerBorderInset * t,
      innerBorderColor: innerBorderColor,
      innerBorderWidth: innerBorderWidth * t,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is BegoniaPlaqueBorder) {
      return BegoniaPlaqueBorder(
        cutSize: (1.0 - t) * a.cutSize + t * cutSize,
        borderColor: Color.lerp(a.borderColor, borderColor, t) ?? borderColor,
        borderWidth: (1.0 - t) * a.borderWidth + t * borderWidth,
        innerBorderInset: (1.0 - t) * a.innerBorderInset + t * innerBorderInset,
        innerBorderColor: Color.lerp(a.innerBorderColor, innerBorderColor, t),
        innerBorderWidth: (1.0 - t) * a.innerBorderWidth + t * innerBorderWidth,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is BegoniaPlaqueBorder) {
      return BegoniaPlaqueBorder(
        cutSize: (1.0 - t) * cutSize + t * b.cutSize,
        borderColor: Color.lerp(borderColor, b.borderColor, t) ?? borderColor,
        borderWidth: (1.0 - t) * borderWidth + t * b.borderWidth,
        innerBorderInset: (1.0 - t) * innerBorderInset + t * b.innerBorderInset,
        innerBorderColor: Color.lerp(innerBorderColor, b.innerBorderColor, t),
        innerBorderWidth: (1.0 - t) * innerBorderWidth + t * b.innerBorderWidth,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BegoniaPlaqueBorder &&
          runtimeType == other.runtimeType &&
          cutSize == other.cutSize &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          innerBorderInset == other.innerBorderInset &&
          innerBorderColor == other.innerBorderColor &&
          innerBorderWidth == other.innerBorderWidth;

  @override
  int get hashCode => Object.hash(
        cutSize,
        borderColor,
        borderWidth,
        innerBorderInset,
        innerBorderColor,
        innerBorderWidth,
      );
}

/// 2. Octagonal Medallion ShapeBorder (八角青玉古铜罗盘边框)
///
/// An 8-point octagon chamfering each side symmetrically by [chamferRatio] (default 0.28).
/// Emulates antique bronze compasses, jade tokens, and carved stone seal medallions.
class OctagonalMedallionBorder extends ShapeBorder {
  final double chamferRatio;
  final Color borderColor;
  final double borderWidth;
  final Color? bevelHighlightColor;

  const OctagonalMedallionBorder({
    this.chamferRatio = 0.28,
    this.borderColor = Colors.transparent,
    this.borderWidth = 1.0,
    this.bevelHighlightColor,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  Path _buildOctagon(Rect rect, double ratio) {
    final w = rect.width;
    final h = rect.height;
    final chamferX = w * ratio;
    final chamferY = h * ratio;

    final left = rect.left;
    final top = rect.top;
    final right = rect.right;
    final bottom = rect.bottom;

    return Path()
      ..moveTo(left + chamferX, top)
      ..lineTo(right - chamferX, top)
      ..lineTo(right, top + chamferY)
      ..lineTo(right, bottom - chamferY)
      ..lineTo(right - chamferX, bottom)
      ..lineTo(left + chamferX, bottom)
      ..lineTo(left, bottom - chamferY)
      ..lineTo(left, top + chamferY)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _buildOctagon(rect, chamferRatio);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final deflated = rect.deflate(borderWidth);
    return _buildOctagon(deflated, chamferRatio);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (borderWidth > 0 && borderColor.a > 0) {
      final paint = Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(getOuterPath(rect), paint);
    }

    if (bevelHighlightColor != null && bevelHighlightColor!.a > 0) {
      final bevelRect = rect.deflate(1.5);
      final bevelPath = _buildOctagon(bevelRect, chamferRatio);
      final bevelPaint = Paint()
        ..color = bevelHighlightColor!
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(bevelPath, bevelPaint);
    }
  }

  @override
  ShapeBorder scale(double t) {
    return OctagonalMedallionBorder(
      chamferRatio: chamferRatio,
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      bevelHighlightColor: bevelHighlightColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OctagonalMedallionBorder &&
          runtimeType == other.runtimeType &&
          chamferRatio == other.chamferRatio &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          bevelHighlightColor == other.bevelHighlightColor;

  @override
  int get hashCode => Object.hash(
        chamferRatio,
        borderColor,
        borderWidth,
        bevelHighlightColor,
      );
}

/// 3. Ancient Chinese Waist-Tally ShapeBorder (古风腰牌边框)
///
/// Chamfered waist-tally seal silhouette with top cord-hole perforation (穿绳孔),
/// representing traditional wooden, bronze, or cinnabar tokens strung along a silk cord.
class WaistTallyBorder extends ShapeBorder {
  final double cutSize;
  final double cordHoleRadius;
  final Color borderColor;
  final double borderWidth;
  final Color? innerBorderColor;

  const WaistTallyBorder({
    this.cutSize = 8.0,
    this.cordHoleRadius = 2.5,
    this.borderColor = Colors.transparent,
    this.borderWidth = 1.0,
    this.innerBorderColor,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  Path _buildTallyPath(Rect rect, double cut) {
    final effectiveCut = math.min(cut, math.min(rect.width, rect.height) / 2);
    final left = rect.left;
    final top = rect.top;
    final right = rect.right;
    final bottom = rect.bottom;

    return Path()
      ..moveTo(left + effectiveCut, top)
      ..lineTo(right - effectiveCut, top)
      ..lineTo(right, top + effectiveCut)
      ..lineTo(right, bottom - effectiveCut * 0.75)
      ..lineTo(right - effectiveCut * 0.75, bottom)
      ..lineTo(left + effectiveCut * 0.75, bottom)
      ..lineTo(left, bottom - effectiveCut * 0.75)
      ..lineTo(left, top + effectiveCut)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _buildTallyPath(rect, cutSize);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final deflated = rect.deflate(borderWidth);
    return _buildTallyPath(deflated, math.max(0, cutSize - borderWidth));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final outerPath = getOuterPath(rect);

    if (borderWidth > 0 && borderColor.a > 0) {
      final paint = Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(outerPath, paint);
    }

    if (innerBorderColor != null && innerBorderColor!.a > 0) {
      final innerRect = rect.deflate(2.0);
      final innerPath = _buildTallyPath(innerRect, math.max(2.0, cutSize - 2.0));
      final innerPaint = Paint()
        ..color = innerBorderColor!
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(innerPath, innerPaint);
    }

    // Top Cord-Hole Perforation (穿绳孔)
    if (cordHoleRadius > 0) {
      final holeCenter = Offset(rect.center.dx, rect.top + cordHoleRadius + 3.0);
      final holePaint = Paint()
        ..color = (innerBorderColor ?? borderColor).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(holeCenter, cordHoleRadius, holePaint);
    }
  }

  @override
  ShapeBorder scale(double t) {
    return WaistTallyBorder(
      cutSize: cutSize * t,
      cordHoleRadius: cordHoleRadius * t,
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      innerBorderColor: innerBorderColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaistTallyBorder &&
          runtimeType == other.runtimeType &&
          cutSize == other.cutSize &&
          cordHoleRadius == other.cordHoleRadius &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          innerBorderColor == other.innerBorderColor;

  @override
  int get hashCode => Object.hash(
        cutSize,
        cordHoleRadius,
        borderColor,
        borderWidth,
        innerBorderColor,
      );
}
