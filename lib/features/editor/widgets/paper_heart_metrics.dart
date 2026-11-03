import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../templates/models/template_style.dart';
import 'cinnabar_signature_seal.dart';

/// Geometry utilities and positioning contracts for elements anchored strictly
/// inside the Paper Heart (版心, [StationeryLayoutMetrics.innerFrameRect]).
class PaperHeartMetrics {
  const PaperHeartMetrics._();

  /// Default inset clearance inside the Paper Heart border (12px).
  static const double kDefaultSealInset = 12.0;

  /// Default size of the Cinnabar Signature Seal (48px).
  static const double kDefaultSealSize = 48.0;

  /// Default stroke inflation of the classical Double Outer Border (4px).
  static const double kDoubleBorderInflation = 4.0;

  /// Computes the bounding [Rect] of the Cinnabar Signature Seal anchored strictly
  /// inside the bottom-right corner of [innerFrameRect] with [inset] clearance
  /// from the right and bottom frame edges.
  static Rect computeSealRect({
    required Rect innerFrameRect,
    double sealSize = kDefaultSealSize,
    double inset = kDefaultSealInset,
  }) {
    final left = innerFrameRect.right - inset - sealSize;
    final top = innerFrameRect.bottom - inset - sealSize;
    return Rect.fromLTWH(left, top, sealSize, sealSize);
  }

  /// Calculates the [Positioned] stack offsets (`right`, `bottom`, `width`, `height`)
  /// for placing the Cinnabar Signature Seal in a parent [Stack] of size [containerSize].
  static ({double right, double bottom, double width, double height}) computeSealStackOffsets({
    required Size containerSize,
    required Rect innerFrameRect,
    double sealSize = kDefaultSealSize,
    double inset = kDefaultSealInset,
  }) {
    final rightOffset = math.max(0.0, containerSize.width - innerFrameRect.right) + inset;
    final bottomOffset = math.max(0.0, containerSize.height - innerFrameRect.bottom) + inset;
    return (
      right: rightOffset,
      bottom: bottomOffset,
      width: sealSize,
      height: sealSize,
    );
  }

  /// Verifies whether [targetRect] is 100% contained within [innerFrameRect].
  static bool isContainedInside({
    required Rect innerFrameRect,
    required Rect targetRect,
  }) {
    return targetRect.left >= innerFrameRect.left &&
        targetRect.top >= innerFrameRect.top &&
        targetRect.right <= innerFrameRect.right &&
        targetRect.bottom <= innerFrameRect.bottom;
  }

  /// Verifies whether [targetRect] is 100% contained within the Double Outer Border
  /// (inflated by [borderInflation] around [innerFrameRect]).
  static bool isInsideDoubleOuterBorder({
    required Rect innerFrameRect,
    required Rect targetRect,
    double borderInflation = kDoubleBorderInflation,
  }) {
    final outerBorderRect = innerFrameRect.inflate(borderInflation);
    return isContainedInside(innerFrameRect: outerBorderRect, targetRect: targetRect);
  }
}

/// Renders a colophon [CinnabarSignatureSeal] positioned strictly inside the
/// bottom-right corner of the Paper Heart ([innerFrameRect]).
class BoundedCinnabarSeal extends StatelessWidget {
  final Rect innerFrameRect;
  final Size containerSize;
  final SealCarvingStyle sealStyle;
  final double sealSize;
  final double inset;
  final double opacity;
  final String? overrideText;

  const BoundedCinnabarSeal({
    super.key,
    required this.innerFrameRect,
    required this.containerSize,
    this.sealStyle = SealCarvingStyle.zhuwen,
    this.sealSize = PaperHeartMetrics.kDefaultSealSize,
    this.inset = PaperHeartMetrics.kDefaultSealInset,
    this.opacity = 0.38,
    this.overrideText,
  });

  @override
  Widget build(BuildContext context) {
    if (sealStyle == SealCarvingStyle.hidden) {
      return const SizedBox.shrink();
    }

    final offsets = PaperHeartMetrics.computeSealStackOffsets(
      containerSize: containerSize,
      innerFrameRect: innerFrameRect,
      sealSize: sealSize,
      inset: inset,
    );

    return Positioned(
      right: offsets.right,
      bottom: offsets.bottom,
      width: offsets.width,
      height: offsets.height,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: CinnabarSignatureSeal(
            sealStyle: sealStyle,
            size: sealSize,
            overrideText: overrideText,
          ),
        ),
      ),
    );
  }
}
