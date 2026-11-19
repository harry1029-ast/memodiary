import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/atmosphere_palette.dart';
import '../../../core/theme/atmosphere_palettes.dart';
import '../../../core/theme/ink_diary_theme.dart';
import 'bamboo_blind_pull_cord.dart';

/// Pure timing and interpolation curve math for the two-stage **Xiangfei Bamboo
/// Blind (`湘妃竹帘`)** closing and opening choreography.
class BambooBlindChoreography {
  static const Cubic curve = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Duration closeDuration = Duration(milliseconds: 840);
  static const Duration openDuration = Duration(milliseconds: 780);
  static const Duration springBackDuration = Duration(milliseconds: 360);
  static const double collapsedHeight = 44.0;
  static const double tugCordTargetLength = 76.0;

  const BambooBlindChoreography._();

  static double cordLength({
    required bool isClosing,
    required double progress,
    required double cordStartLength,
    required double dragDelta,
  }) {
    if (!isClosing) {
      return BambooBlindPullCord.restingCordLength + dragDelta;
    }
    final peak = math.max(tugCordTargetLength, cordStartLength);
    if (progress <= 0.45) {
      final tugT = curve.transform((progress / 0.28).clamp(0.0, 1.0));
      return cordStartLength + (peak - cordStartLength) * tugT;
    }
    final retractT = curve.transform(((progress - 0.45) / 0.30).clamp(0.0, 1.0));
    return peak + (BambooBlindPullCord.restingCordLength - peak) * retractT;
  }

  static double blindProgress({
    required bool isClosing,
    required bool isOpening,
    required double progress,
    required double blindStartProgress,
    required double dragDelta,
  }) {
    if (isClosing) {
      final dropT = curve.transform((progress / (440 / 840)).clamp(0.0, 1.0));
      return blindStartProgress + (1.0 - blindStartProgress) * dropT;
    }
    if (isOpening) {
      if (progress <= 320 / 780) return 1.0;
      final liftT = curve
          .transform(((progress - 320 / 780) / (440 / 780)).clamp(0.0, 1.0));
      return 1.0 - liftT;
    }
    if (dragDelta > 0.0) {
      return (dragDelta / BambooBlindPullCord.maxDragDelta).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  static double windowHeight({
    required double expandedHeight,
    required bool isClosing,
    required bool isOpening,
    required double progress,
  }) {
    if (isClosing) {
      if (progress <= 380 / 840) return expandedHeight;
      final shrinkT = curve
          .transform(((progress - 380 / 840) / (460 / 840)).clamp(0.0, 1.0));
      return expandedHeight + (collapsedHeight - expandedHeight) * shrinkT;
    }
    if (isOpening) {
      final expandT = curve.transform((progress / (360 / 780)).clamp(0.0, 1.0));
      return collapsedHeight + (expandedHeight - collapsedHeight) * expandT;
    }
    return expandedHeight;
  }
}

/// Unrolling slatted **Xiangfei Bamboo Blind (`湘妃竹帘`)** overlay rendered
/// inside the 16:9 `Shanshui Scenery Card` window during pull-drag and
/// two-stage collapse/restore choreography.
///
/// [progress] maps `0.0` (fully rolled up at `-102%`) to `1.0` (fully dropped
/// down to the sill at `0%`).
class XiangfeiBambooBlind extends StatelessWidget {
  final double progress;

  const XiangfeiBambooBlind({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    final clamped = progress.clamp(0.0, 1.0);
    final translateFractionY = -1.02 * (1.0 - clamped);

    return FractionalTranslation(
      key: const Key('scenery_bamboo_blind_curtain'),
      translation: Offset(0, translateFractionY),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0xD9000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Horizontal bamboo slats + vertical braided silk cords
            CustomPaint(
              painter: XiangfeiBambooSlatPainter(
                compact: false,
                palette: palette,
              ),
              size: Size.infinite,
            ),

            // Centered woven calligraphy emblem
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.woodFrameDark.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: palette.accentSecondary.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.sealAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '竹帘垂落 · 静心抚卷',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 11,
                        letterSpacing: 2.0,
                        color: palette.headerTitleText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.sealAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Heavy bottom roller bar with brass end-caps (底轴与铜箍)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 14,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      palette.blindRollerTop,
                      palette.blindRollerMid,
                      palette.blindRollerBottom,
                    ],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: palette.accentSecondary.withValues(alpha: 0.85),
                      width: 1.0,
                    ),
                    bottom: BorderSide(
                      color: palette.blindRollerBottom,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _BrassRollerCap(palette: palette),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.sealAccent,
                            border: Border.all(
                              color: palette.headerTitleText.withValues(alpha: 0.60),
                              width: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '湘妃竹帘',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 8.5,
                            letterSpacing: 1.6,
                            color: palette.blindTagAccent,
                          ),
                        ),
                      ],
                    ),
                    _BrassRollerCap(palette: palette),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrassRollerCap extends StatelessWidget {
  final AtmospherePalette palette;

  const _BrassRollerCap({required this.palette});

  @override
  Widget build(BuildContext context) {
    final capHighlight = Color.lerp(
      palette.accentSecondary,
      palette.headerTitleText,
      0.28,
    )!;
    return Container(
      width: 12,
      height: 14,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            capHighlight,
            palette.accentSecondary,
            palette.accentSecondaryDim,
          ],
        ),
      ),
    );
  }
}

/// Custom painter rendering slatted Xiangfei bamboo texture (`湘妃竹帘`)
/// for both the full-window blind curtain and the `44dp` collapsed bar.
class XiangfeiBambooSlatPainter extends CustomPainter {
  final bool compact;
  final AtmospherePalette palette;

  const XiangfeiBambooSlatPainter({
    required this.compact,
    this.palette = AtmospherePalettes.yunhaoNight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const slatPitch = 6.0;
    final slatTopPaint = Paint()..color = palette.blindSlatTop;
    final slatMidPaint = Paint()..color = palette.blindSlatMid;
    final slatBottomPaint = Paint()..color = palette.blindSlatBottom;
    final slitPaint = Paint()..color = palette.blindSlit;

    var cursorY = 0.0;
    while (cursorY < size.height) {
      canvas.drawRect(Rect.fromLTWH(0, cursorY, size.width, 1.5), slatTopPaint);
      canvas.drawRect(
        Rect.fromLTWH(0, cursorY + 1.5, size.width, 1.5),
        slatMidPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, cursorY + 3.0, size.width, 1.5),
        slatBottomPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, cursorY + 4.5, size.width, 1.5),
        slitPaint,
      );
      cursorY += slatPitch;
    }

    if (compact) {
      final vignetteRect = Offset.zero & size;
      canvas.drawRect(
        vignetteRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: const [0.0, 0.16, 0.84, 1.0],
            colors: [
              palette.woodFrameDark.withValues(alpha: 0.72),
              palette.woodFrameDark.withValues(alpha: 0.32),
              palette.woodFrameDark.withValues(alpha: 0.32),
              palette.woodFrameDark.withValues(alpha: 0.72),
            ],
          ).createShader(vignetteRect),
      );
      return;
    }

    _drawSilkCordColumn(canvas, size.width * 0.148, size.height);
    _drawSilkCordColumn(canvas, size.width * 0.852, size.height);

    final centerCordRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.5),
      width: 2.5,
      height: size.height,
    );
    canvas.drawRect(
      centerCordRect,
      Paint()..color = palette.accentSecondary.withValues(alpha: 0.55),
    );

    final shadowRect = Rect.fromLTWH(0, 0, size.width, 18);
    canvas.drawRect(
      shadowRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.65),
            Colors.transparent,
          ],
        ).createShader(shadowRect),
    );
  }

  void _drawSilkCordColumn(Canvas canvas, double centerX, double height) {
    final primaryCord = Paint()
      ..color = palette.blindCordPrimary.withValues(alpha: 0.85);
    final secondaryCord = Paint()
      ..color = palette.blindCordSecondary.withValues(alpha: 0.90);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, height * 0.5),
        width: 4.5,
        height: height,
      ),
      primaryCord,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, height * 0.5),
        width: 1.6,
        height: height,
      ),
      secondaryCord,
    );
  }

  @override
  bool shouldRepaint(covariant XiangfeiBambooSlatPainter oldDelegate) {
    return oldDelegate.compact != compact || oldDelegate.palette != palette;
  }
}
