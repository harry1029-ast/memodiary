import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The curled Page Corner (折角) at the foot of a Stationery Sheet.
///
/// [PageCornerFold] is the drawn fold, painted on the sheet itself so it moves
/// with the paper when the diarist swipes. [PageCornerTargets] lays the 44×44
/// touch targets over the active sheet's corners, starting at the foot of the
/// Paper Heart and reaching down onto the desk, so they never steal a tap from
/// the last row of text.
abstract final class PageCorner {
  /// Leg of the folded triangle, kept within the sheet's Earth margin and
  /// clear of its border.
  static const double kFoldSize = 20.0;

  /// Minimum touch target.
  static const double kTargetSize = 44.0;

  /// Cinnabar crease along the fold, after the prototype's `.page-corner-curl`.
  static const Color kCreaseColor = Color(0x38B83B2E);
}

/// The folded-paper triangle at the bottom-left ([isNext] false) or
/// bottom-right ([isNext] true) corner of a sheet whose paper is [paperColor].
class PageCornerFold extends StatelessWidget {
  final bool isNext;
  final Color paperColor;

  const PageCornerFold({
    super.key,
    required this.isNext,
    required this.paperColor,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        key: Key(isNext ? 'editor_page_corner_fold_next' : 'editor_page_corner_fold_prev'),
        size: const Size.square(PageCorner.kFoldSize),
        painter: _PageCornerFoldPainter(isNext: isNext, paperColor: paperColor),
      ),
    );
  }
}

/// The folds at the foot of one sheet, filling its paper: the previous fold
/// unless it is the first sheet, the next fold unless it is the last.
class PageCornerFolds extends StatelessWidget {
  final bool hasPrevious;
  final bool hasNext;
  final Color paperColor;

  const PageCornerFolds({
    super.key,
    required this.hasPrevious,
    required this.hasNext,
    required this.paperColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasPrevious)
          Positioned(
            left: 0.0,
            bottom: 0.0,
            child: PageCornerFold(isNext: false, paperColor: paperColor),
          ),
        if (hasNext)
          Positioned(
            right: 0.0,
            bottom: 0.0,
            child: PageCornerFold(isNext: true, paperColor: paperColor),
          ),
      ],
    );
  }
}

/// Paints the fold from a [ui.Picture] recorded once per side and paper colour.
class _PageCornerFoldPainter extends CustomPainter {
  static final Map<(bool, int), ui.Picture> _pictures = {};

  final bool isNext;
  final Color paperColor;

  _PageCornerFoldPainter({required this.isNext, required this.paperColor});

  @override
  void paint(Canvas canvas, Size size) {
    final picture = _pictures.putIfAbsent(
      (isNext, paperColor.toARGB32()),
      () => _recordFold(isNext: isNext, paperColor: paperColor),
    );
    canvas.drawPicture(picture);
  }

  static ui.Picture _recordFold({required bool isNext, required Color paperColor}) {
    const side = PageCorner.kFoldSize;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (isNext) {
      // Mirror the bottom-left fold onto the bottom-right corner.
      canvas.translate(side, 0.0);
      canvas.scale(-1.0, 1.0);
    }

    // The folded flap: the triangle cut off the corner by the crease running
    // from the top-left to the bottom-right of the fold's square.
    final flap = Path()
      ..moveTo(0.0, 0.0)
      ..lineTo(0.0, side)
      ..lineTo(side, side)
      ..close();

    final isDarkPaper = paperColor.computeLuminance() < 0.3;
    final shade = Color.lerp(paperColor, Colors.black, isDarkPaper ? 0.25 : 0.12)!;
    final highlight = Color.lerp(paperColor, Colors.white, isDarkPaper ? 0.08 : 0.4)!;

    // A soft shadow the lifted flap casts on the paper beside the crease.
    canvas.drawPath(
      flap.shift(const Offset(1.5, -1.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );
    canvas.drawPath(
      flap,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0.0, side),
          const Offset(side / 2.0, side / 2.0),
          [shade, highlight],
          const [0.0, 0.96],
        ),
    );
    canvas.drawLine(
      Offset.zero,
      const Offset(side, side),
      Paint()
        ..color = PageCorner.kCreaseColor
        ..strokeWidth = 1.0,
    );
    return recorder.endRecording();
  }

  @override
  bool shouldRepaint(_PageCornerFoldPainter oldDelegate) =>
      oldDelegate.isNext != isNext || oldDelegate.paperColor != paperColor;
}

/// The previous and next corner targets over the active sheet, hidden on the
/// first and last sheet respectively. [top] is the foot of the active sheet's
/// Paper Heart, in the coordinates of the enclosing [Stack].
class PageCornerTargets extends StatelessWidget {
  final int currentSheetIndex;
  final int totalSheets;
  final double top;
  final VoidCallback? onPreviousSheet;
  final VoidCallback? onNextSheet;

  const PageCornerTargets({
    super.key,
    required this.currentSheetIndex,
    required this.totalSheets,
    required this.top,
    this.onPreviousSheet,
    this.onNextSheet,
  });

  @override
  Widget build(BuildContext context) {
    final sheetNumber = currentSheetIndex + 1;
    return Stack(
      children: [
        if (currentSheetIndex > 0)
          Positioned(
            left: 0.0,
            top: top,
            child: _PageCornerTarget(
              key: const Key('editor_page_corner_prev'),
              label: '上卷 · 第 ${sheetNumber - 1} 页',
              onTap: onPreviousSheet,
            ),
          ),
        if (currentSheetIndex < totalSheets - 1)
          Positioned(
            right: 0.0,
            top: top,
            child: _PageCornerTarget(
              key: const Key('editor_page_corner_next'),
              label: '下卷 · 第 ${sheetNumber + 1} 页',
              onTap: onNextSheet,
            ),
          ),
      ],
    );
  }
}

/// A transparent 44×44 touch target over a drawn fold. It never takes focus,
/// so the page-turn path alone decides where writing focus goes.
class _PageCornerTarget extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PageCornerTarget({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: const SizedBox.square(dimension: PageCorner.kTargetSize),
      ),
    );
  }
}
