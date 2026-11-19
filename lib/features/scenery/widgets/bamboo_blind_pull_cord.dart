import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/atmosphere_palette.dart';
import '../../../core/utils/ambient_animation_utils.dart';
import 'scenery_hud_controller.dart';

/// Interactive hanging braided-silk **Bamboo Blind Pull-Cord** (`竹帘流苏拉绳`)
/// anchored at the top-left of the `Shanshui Scenery Card` window.
///
/// Supports:
/// - Gentle `±1.5°` idle sway (`4.2s` period) gated by [enableAmbientAnimation]
///   and [isVisible].
/// - Tap (`< 5dp` displacement) or downward drag (`>= 36dp` threshold, clamped
///   to `92dp` total cord length) to drop the slatted Xiangfei Bamboo Blind and
///   collapse the window.
/// - Accessible `44x44` semantic tap target.
class BambooBlindPullCord extends StatefulWidget {
  static const double restingCordLength = 36.0;
  static const double maxCordLength = 92.0;
  static const double triggerDragDelta = 36.0;
  static const double tapJitterDelta = 5.0;
  static const double maxDragDelta = maxCordLength - restingCordLength;

  final double cordLength;
  final double dragDelta;
  final bool isDragging;
  final bool isTransitioning;
  final bool isVisible;
  final bool showRestingTag;
  final bool? enableAmbientAnimation;
  final VoidCallback onTap;
  final ValueChanged<double> onDragStart;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final VoidCallback onDragEnd;

  const BambooBlindPullCord({
    super.key,
    required this.cordLength,
    required this.dragDelta,
    required this.isDragging,
    required this.isTransitioning,
    this.isVisible = true,
    this.showRestingTag = true,
    this.enableAmbientAnimation,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<BambooBlindPullCord> createState() => _BambooBlindPullCordState();
}

class _BambooBlindPullCordState extends State<BambooBlindPullCord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swayController;

  bool get _effectiveAnimate =>
      shouldRunAmbientAnimation(widget.enableAmbientAnimation);

  bool get _shouldSway =>
      _effectiveAnimate &&
      widget.isVisible &&
      !widget.isDragging &&
      !widget.isTransitioning;

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    if (_shouldSway) {
      _swayController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant BambooBlindPullCord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldSway) {
      if (!_swayController.isAnimating) {
        _swayController.repeat();
      }
    } else if (_swayController.isAnimating) {
      _swayController.stop();
    }
  }

  @override
  void dispose() {
    _swayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    final passedThreshold =
        widget.dragDelta >= BambooBlindPullCord.triggerDragDelta;
    final isActivelyPulling =
        widget.isDragging && widget.dragDelta >= BambooBlindPullCord.tapJitterDelta;
    final isTagVisible =
        widget.showRestingTag || isActivelyPulling || passedThreshold;
    final tagLabel = passedThreshold
        ? '松手收窗 ✓'
        : (isActivelyPulling ? '继续下拉 ↓' : '下拉垂帘 ↓');

    final beadHighlight = Color.lerp(
      palette.accentSecondary,
      Colors.white,
      0.42,
    )!;
    final beadMid = Color.lerp(
      palette.accentSecondary,
      palette.accentPrimary,
      0.25,
    )!;
    final beadShadow = Color.lerp(
      palette.accentSecondary,
      palette.woodFrameDark,
      0.45,
    )!;
    final beadBorder = Color.lerp(
      palette.accentSecondary,
      Colors.white,
      0.55,
    )!.withValues(alpha: 0.70);

    return Semantics(
      button: true,
      label: '下拉竹帘收起山水画卷',
      child: GestureDetector(
        key: const Key('scenery_pull_cord_handle'),
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onTap: widget.isTransitioning ? null : widget.onTap,
        onVerticalDragStart: widget.isTransitioning
            ? null
            : (details) => widget.onDragStart(details.globalPosition.dy),
        onVerticalDragUpdate:
            widget.isTransitioning ? null : widget.onDragUpdate,
        onVerticalDragEnd: widget.isTransitioning
            ? null
            : (_) => widget.onDragEnd(),
        onVerticalDragCancel: widget.isTransitioning ? null : widget.onDragEnd,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.only(left: 2, right: 4, bottom: 6),
            child: AnimatedBuilder(
              animation: _swayController,
              builder: (context, child) {
                final angleDegrees = _shouldSway
                    ? math.sin(_swayController.value * math.pi * 2) * 1.5
                    : 0.0;
                return Transform.rotate(
                  angle: angleDegrees * math.pi / 180.0,
                  alignment: Alignment.topCenter,
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top pulley grommet (滑轮扣)
                  Container(
                    width: 16,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(3),
                      ),
                      border: Border.all(
                        color: palette.accentSecondary.withValues(alpha: 0.70),
                        width: 0.8,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.accentSecondary,
                          palette.accentSecondaryDim,
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 5,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: palette.woodFrameDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Braided silk cord (丝绦拉绳)
                  SizedBox(
                    width: 3.0,
                    height: widget.cordLength,
                    child: CustomPaint(
                      painter: _BraidedSilkCordPainter(palette: palette),
                    ),
                  ),

                  // Jade bead (算盘珠)
                  Container(
                    width: 14,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: beadBorder,
                        width: 0.8,
                      ),
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.4),
                        radius: 0.9,
                        colors: [beadHighlight, beadMid, beadShadow],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x88000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),

                  // Gold knot ring (绳结)
                  Container(
                    width: 10,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.blindCordSecondary,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),

                  // Silk tassel (流苏穗)
                  SizedBox(
                    width: 16,
                    height: 22,
                    child: CustomPaint(
                      painter: _TasselPainter(palette: palette),
                    ),
                  ),

                  // Pull-down micro-tag
                  const SizedBox(height: 2),
                  AnimatedOpacity(
                    key: const Key('scenery_pull_cord_tag_opacity'),
                    opacity: isTagVisible ? 1.0 : 0.0,
                    duration: SceneryHudController.fadeDuration,
                    curve: SceneryHudController.fadeCurve,
                    child: Container(
                      key: const Key('scenery_pull_cord_tag'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: palette.woodFrameDark.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: palette.accentSecondary.withValues(alpha: 0.60),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        tagLabel,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.15,
                          color: passedThreshold
                              ? palette.blindTagAccent
                              : palette.headerTitleText,
                          fontWeight: passedThreshold
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BraidedSilkCordPainter extends CustomPainter {
  final AtmospherePalette palette;

  const _BraidedSilkCordPainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final primaryPaint = Paint()..color = palette.blindCordPrimary;
    final secondaryPaint = Paint()..color = palette.blindCordSecondary;
    const segmentHeight = 3.0;
    var topY = 0.0;
    var usePrimary = true;

    while (topY < size.height) {
      final drawHeight = math.min(segmentHeight, size.height - topY);
      canvas.drawRect(
        Rect.fromLTWH(0, topY, size.width, drawHeight),
        usePrimary ? primaryPaint : secondaryPaint,
      );
      topY += segmentHeight;
      usePrimary = !usePrimary;
    }
  }

  @override
  bool shouldRepaint(covariant _BraidedSilkCordPainter oldDelegate) {
    return oldDelegate.palette.blindCordPrimary != palette.blindCordPrimary ||
        oldDelegate.palette.blindCordSecondary != palette.blindCordSecondary;
  }
}

class _TasselPainter extends CustomPainter {
  final AtmospherePalette palette;

  const _TasselPainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 18.0;
    final scaleY = size.height / 24.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Top knot cap
    final capPath = Path()
      ..moveTo(6, 1)
      ..lineTo(12, 1)
      ..lineTo(14, 6)
      ..lineTo(4, 6)
      ..close();
    canvas.drawPath(capPath, Paint()..color = palette.sealAccent);
    canvas.drawPath(
      capPath,
      Paint()
        ..color = Color.lerp(palette.sealAccent, Colors.white, 0.45)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    // Ferrule band
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5, 5, 8, 2),
        const Radius.circular(0.8),
      ),
      Paint()..color = palette.blindCordSecondary,
    );

    // Splayed silk skirt
    final skirtPath = Path()
      ..moveTo(5, 7)
      ..lineTo(2, 22)
      ..lineTo(6, 23)
      ..lineTo(9, 23)
      ..lineTo(12, 23)
      ..lineTo(16, 22)
      ..lineTo(13, 7)
      ..close();
    canvas.drawPath(skirtPath, Paint()..color = palette.blindCordPrimary);

    // Strand shading lines
    final darkStrand = Paint()
      ..color = Color.lerp(palette.blindCordPrimary, palette.woodFrameDark, 0.45)!
      ..strokeWidth = 0.7;
    final highlightStrand = Paint()
      ..color = Color.lerp(palette.blindCordPrimary, Colors.white, 0.45)!
      ..strokeWidth = 0.6;
    canvas.drawLine(const Offset(6.5, 8), const Offset(5, 22), darkStrand);
    canvas.drawLine(const Offset(9, 8), const Offset(9, 23), highlightStrand);
    canvas.drawLine(const Offset(11.5, 8), const Offset(13, 22), darkStrand);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TasselPainter oldDelegate) {
    return oldDelegate.palette.blindCordPrimary != palette.blindCordPrimary ||
        oldDelegate.palette.blindCordSecondary != palette.blindCordSecondary ||
        oldDelegate.palette.sealAccent != palette.sealAccent ||
        oldDelegate.palette.woodFrameDark != palette.woodFrameDark ||
        oldDelegate.palette.accentSecondary != palette.accentSecondary;
  }
}
