import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Layout widget that dynamically clamps its child's outer layout height to an
/// exact integer multiple of [lineStridePx], distributing any surplus vertical
/// space symmetrically across top and bottom padding.
///
/// Eliminates fractional vertical phase shifts on ruled, squared-grid, and
/// dot-matrix paper substrates across single-line and wrapped multi-line titles.
class IntegerSnappedLetterhead extends SingleChildRenderObjectWidget {
  /// The active line stride / row height in pixels.
  final double lineStridePx;

  const IntegerSnappedLetterhead({
    super.key,
    required this.lineStridePx,
    required Widget super.child,
  });

  /// Pure static utility to compute integer-snapped height for a given raw height and stride.
  static double calculateSnappedHeight(double rawHeight, double lineStridePx) {
    if (lineStridePx <= 0.0) return rawHeight;
    final rowCount = math.max(1, (rawHeight / lineStridePx).ceil());
    return rowCount * lineStridePx;
  }

  /// Pure static utility to compute top/bottom padding for a given raw height and stride.
  static double calculatePaddingTop(double rawHeight, double lineStridePx) {
    final snappedHeight = calculateSnappedHeight(rawHeight, lineStridePx);
    final delta = math.max(0.0, snappedHeight - rawHeight);
    return delta / 2.0;
  }

  @override
  RenderIntegerSnappedLetterhead createRenderObject(BuildContext context) {
    return RenderIntegerSnappedLetterhead(lineStridePx: lineStridePx);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderIntegerSnappedLetterhead renderObject,
  ) {
    renderObject.lineStridePx = lineStridePx;
  }
}

/// RenderObject for [IntegerSnappedLetterhead] that measures its child unconstrained
/// vertically, snaps outer box height to an integer multiple of [lineStridePx], and
/// symmetrically centers the child vertically.
class RenderIntegerSnappedLetterhead extends RenderShiftedBox {
  double _lineStridePx;

  RenderIntegerSnappedLetterhead({
    RenderBox? child,
    required double lineStridePx,
  })  : _lineStridePx = lineStridePx,
        super(child);

  double get lineStridePx => _lineStridePx;

  set lineStridePx(double value) {
    if (_lineStridePx != value) {
      _lineStridePx = value;
      markNeedsLayout();
    }
  }

  double _snapHeight(double rawHeight) {
    return IntegerSnappedLetterhead.calculateSnappedHeight(rawHeight, _lineStridePx);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final rawHeight = child?.getMinIntrinsicHeight(width) ?? 0.0;
    return _snapHeight(rawHeight);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final rawHeight = child?.getMaxIntrinsicHeight(width) ?? 0.0;
    return _snapHeight(rawHeight);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return child?.getMinIntrinsicWidth(height) ?? 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return child?.getMaxIntrinsicWidth(height) ?? 0.0;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final currentChild = child;
    if (currentChild == null) {
      final snappedHeight = _snapHeight(0.0);
      return constraints.constrain(Size(constraints.minWidth, snappedHeight));
    }
    final childConstraints = constraints.copyWith(
      minHeight: 0.0,
      maxHeight: double.infinity,
    );
    final childSize = currentChild.getDryLayout(childConstraints);
    final snappedHeight = _snapHeight(childSize.height);
    final layoutWidth = constraints.constrainWidth(childSize.width);
    return constraints.constrain(Size(layoutWidth, snappedHeight));
  }

  @override
  void performLayout() {
    final currentChild = child;
    if (currentChild == null) {
      final snappedHeight = _snapHeight(0.0);
      size = constraints.constrain(Size(constraints.minWidth, snappedHeight));
      return;
    }

    // Measure child with incoming horizontal constraints but unconstrained height
    currentChild.layout(
      constraints.copyWith(
        minHeight: 0.0,
        maxHeight: double.infinity,
      ),
      parentUsesSize: true,
    );

    final rawHeight = currentChild.size.height;
    final snappedHeight = _snapHeight(rawHeight);
    final delta = math.max(0.0, snappedHeight - rawHeight);
    final paddingTop = delta / 2.0;

    final childParentData = currentChild.parentData! as BoxParentData;
    final layoutWidth = constraints.constrainWidth(currentChild.size.width);
    final offsetX = math.max(0.0, (layoutWidth - currentChild.size.width) / 2.0);
    childParentData.offset = Offset(offsetX, paddingTop);

    size = constraints.constrain(Size(layoutWidth, snappedHeight));
  }
}
