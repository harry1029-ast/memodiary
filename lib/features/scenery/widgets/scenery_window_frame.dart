import 'package:flutter/material.dart';
import '../../../core/theme/atmosphere_palette.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../models/shanshui_atmosphere.dart';
import 'scenery_hud_controller.dart';
import 'shanshui_scenery_painting.dart';

/// Base landscape layer + semantic tap target inside the expanded
/// `Shanshui Scenery Card` window.
class SceneryWindowCanvasLayer extends StatelessWidget {
  final ShanshuiAtmosphereState atmosphere;
  final double aspectRatio;
  final bool? enableAmbientAnimation;
  final bool isVisible;
  final String semanticLabel;
  final VoidCallback onTap;

  const SceneryWindowCanvasLayer({
    super.key,
    required this.atmosphere,
    required this.aspectRatio,
    this.enableAmbientAnimation,
    this.isVisible = true,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ShanshuiSceneryPainting(
          atmosphere: atmosphere,
          aspectRatio: aspectRatio,
          fullPoem: false,
          showCalligraphy: false,
          enableAmbientAnimation: enableAmbientAnimation,
          isVisible: isVisible,
        ),
        Positioned.fill(
          child: Semantics(
            button: true,
            label: semanticLabel,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('scenery_canvas_tap_target'),
                onTap: onTap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Top overlay strip inside the `Shanshui Scenery Card` window, offset clear of
/// the left-hanging `Bamboo Blind Pull-Cord` and displaying Time/Weather,
/// [realmBadge], and seasonal seal.
class SceneryWindowOverlayStrip extends StatelessWidget {
  final ShanshuiAtmosphereState atmosphere;
  final InkDiaryTokens tokens;
  final double maxWidth;
  final Widget realmBadge;
  final bool isVisible;

  const SceneryWindowOverlayStrip({
    super.key,
    required this.atmosphere,
    required this.tokens,
    required this.maxWidth,
    required this.realmBadge,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 14,
      left: 72,
      right: 8,
      child: ExcludeSemantics(
        excluding: !isVisible,
        child: IgnorePointer(
          ignoring: !isVisible,
          child: AnimatedOpacity(
            key: const Key('scenery_overlay_strip_opacity'),
            opacity: isVisible ? 1.0 : 0.0,
            duration: SceneryHudController.fadeDuration,
            curve: SceneryHudController.fadeCurve,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x991E1A17),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Text(
                            atmosphere.timeWeatherBadgeZh,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Color(0xFFF7F4EB),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        flex: 3,
                        child: realmBadge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.sealCinnabar,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    atmosphere.sealBadgeZh,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim perimeter Jiangnan wooden window casing (`轩窗边框`), diagonal volumetric
/// light beams, top rolled bamboo valance (`半卷竹帘`), and exterior bottom
/// balustrade (`凭栏`) framing the 16:9 [ShanshuiSceneryPainting] without
/// obstructing the central landscape.
class SceneryWindowFrame extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const SceneryWindowFrame({
    super.key,
    required this.child,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    final isDark = palette.brightness == Brightness.dark;

    return Container(
      key: const Key('scenery_window_frame'),
      padding: const EdgeInsets.fromLTRB(6.0, 5.0, 6.0, 3.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.woodFrameDark, palette.woodFrameMid],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          (borderRadius - 4.0).clamp(0.0, borderRadius),
        ),
        child: ColoredBox(
          color: const Color(0xFF121519),
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              // Recessed inner shadow + beveled wood highlight + volumetric rays + valance + balustrade
              IgnorePointer(
                child: CustomPaint(
                  painter: _SceneryWindowOverlayPainter(palette: palette),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneryWindowOverlayPainter extends CustomPainter {
  final AtmospherePalette palette;

  const _SceneryWindowOverlayPainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    _paintSunbeams(canvas, size);
    _paintExteriorBalustrade(canvas, size);
    _paintTopBambooValance(canvas, size);
    _paintInnerWoodBevel(canvas, size);
  }

  void _paintSunbeams(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final beamPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-1.0, -0.85),
        end: Alignment(0.95, 0.85),
        stops: [0.0, 0.14, 0.24, 0.34, 0.44, 0.54, 0.66, 0.78, 1.0],
        colors: [
          Color(0x00FFEEC3),
          Color(0x00FFEEC3),
          Color(0x16FFEEC3),
          Color(0x05FFEEC3),
          Color(0x00FFEEC3),
          Color(0x18FFEEC3),
          Color(0x04FFEEC3),
          Color(0x00FFEEC3),
          Color(0x00FFEEC3),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, beamPaint);
  }

  void _paintExteriorBalustrade(Canvas canvas, Size size) {
    // Slim bottom railing spanning the exterior window sill without hiding the lake/ferryboat.
    const sillHeight = 7.0;
    final railTopY = size.height - 20.0;
    final sillTopY = size.height - sillHeight;

    final railColor = palette.woodFrameMid.withValues(alpha: 0.92);
    final sillColor = palette.woodFrameDark.withValues(alpha: 0.95);
    final postColor = Color.lerp(
      palette.woodFrameDark,
      palette.woodFrameMid,
      0.5,
    )!.withValues(alpha: 0.90);
    final highlightColor = palette.woodFrameHighlight.withValues(alpha: 0.45);

    final postPaint = Paint()
      ..color = postColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.butt;

    const postCount = 6;
    for (var slot = 1; slot <= postCount; slot++) {
      final postX = size.width * (slot / (postCount + 1));
      canvas.drawLine(
        Offset(postX, railTopY + 1.0),
        Offset(postX, sillTopY + 1.0),
        postPaint,
      );
    }

    final topRailRect = Rect.fromLTWH(0, railTopY, size.width, 3.5);
    canvas.drawRect(topRailRect, Paint()..color = railColor);
    canvas.drawLine(
      Offset(0, railTopY),
      Offset(size.width, railTopY),
      Paint()
        ..color = highlightColor
        ..strokeWidth = 0.8,
    );

    final sillRect = Rect.fromLTWH(0, sillTopY, size.width, sillHeight);
    canvas.drawRect(sillRect, Paint()..color = sillColor);
  }

  void _paintTopBambooValance(Canvas canvas, Size size) {
    // Rolled bamboo blind valance tucked cleanly along the top molding.
    const valanceHeight = 11.0;
    const poleHeight = 3.0;
    final valanceRect = Rect.fromLTWH(0, 0, size.width, valanceHeight);

    final valancePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.blindSlatTop,
          palette.blindSlatMid,
          palette.blindSlatBottom,
        ],
      ).createShader(valanceRect);
    canvas.drawRect(valanceRect, valancePaint);

    // Fine bamboo slat weave lines inside the rolled valance
    final slatPaint = Paint()
      ..color = palette.blindSlit.withValues(alpha: 0.65)
      ..strokeWidth = 0.85;
    canvas.drawLine(const Offset(0, 3.5), Offset(size.width, 3.5), slatPaint);
    canvas.drawLine(const Offset(0, 7.0), Offset(size.width, 7.0), slatPaint);

    // Bottom cylindrical bamboo roller rod
    final poleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, valanceHeight - 1.0, size.width, poleHeight),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(
      poleRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.blindRollerTop, palette.blindRollerMid],
        ).createShader(poleRect.outerRect),
    );
    canvas.drawLine(
      Offset(0, valanceHeight - 0.5),
      Offset(size.width, valanceHeight - 0.5),
      Paint()
        ..color = Color.lerp(
          palette.blindRollerTop,
          palette.accentSecondary,
          0.35,
        )!.withValues(alpha: 0.65)
        ..strokeWidth = 0.7,
    );
  }

  void _paintInnerWoodBevel(Canvas canvas, Size size) {
    // Subtle recessed shadow along top/sides + crisp wood inner highlight
    final topShadowRect = Rect.fromLTWH(0, 12, size.width, 12);
    canvas.drawRect(
      topShadowRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ).createShader(topShadowRect),
    );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = palette.woodFrameHighlight.withValues(alpha: 0.55);
    canvas.drawRect(
      Rect.fromLTWH(0.5, 0.5, size.width - 1.0, size.height - 1.0),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SceneryWindowOverlayPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}
