import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Layout widget that dynamically clamps its child's outer layout height to an
/// exact integer multiple of [lineStridePx], enforcing at least [minRows] integer rows
/// and distributing surplus vertical space symmetrically across top and bottom padding.
class IntegerSnappedLetterhead extends SingleChildRenderObjectWidget {
  /// The active line stride / row height in pixels.
  final double lineStridePx;

  /// Minimum integer row count reserved for the letterhead (4 rows on Sheet 1).
  final int minRows;

  const IntegerSnappedLetterhead({
    super.key,
    required this.lineStridePx,
    this.minRows = 1,
    required Widget super.child,
  });

  /// Pure static utility to compute integer-snapped height for a given raw height and stride.
  static double calculateSnappedHeight(
    double rawHeight,
    double lineStridePx, {
    int minRows = 1,
  }) {
    if (lineStridePx <= 0.0) return rawHeight;
    final effectiveMinRows = math.max(1, minRows);
    final rowCount = math.max(effectiveMinRows, (rawHeight / lineStridePx).ceil());
    return rowCount * lineStridePx;
  }

  /// Pure static utility to compute top/bottom padding for a given raw height and stride.
  static double calculatePaddingTop(
    double rawHeight,
    double lineStridePx, {
    int minRows = 1,
  }) {
    final snappedHeight = calculateSnappedHeight(
      rawHeight,
      lineStridePx,
      minRows: minRows,
    );
    final delta = math.max(0.0, snappedHeight - rawHeight);
    return delta / 2.0;
  }

  @override
  RenderIntegerSnappedLetterhead createRenderObject(BuildContext context) {
    return RenderIntegerSnappedLetterhead(
      lineStridePx: lineStridePx,
      minRows: minRows,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderIntegerSnappedLetterhead renderObject,
  ) {
    renderObject
      ..lineStridePx = lineStridePx
      ..minRows = minRows;
  }
}

/// RenderObject for [IntegerSnappedLetterhead] that measures its child unconstrained
/// vertically, snaps outer box height to an integer multiple of [lineStridePx], and
/// symmetrically centers the child vertically.
class RenderIntegerSnappedLetterhead extends RenderShiftedBox {
  double _lineStridePx;
  int _minRows;

  RenderIntegerSnappedLetterhead({
    RenderBox? child,
    required double lineStridePx,
    int minRows = 1,
  })  : _lineStridePx = lineStridePx,
        _minRows = minRows,
        super(child);

  double get lineStridePx => _lineStridePx;

  set lineStridePx(double value) {
    if (_lineStridePx != value) {
      _lineStridePx = value;
      markNeedsLayout();
    }
  }

  int get minRows => _minRows;

  set minRows(int value) {
    if (_minRows != value) {
      _minRows = value;
      markNeedsLayout();
    }
  }

  double _snapHeight(double rawHeight) {
    return IntegerSnappedLetterhead.calculateSnappedHeight(
      rawHeight,
      _lineStridePx,
      minRows: _minRows,
    );
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
