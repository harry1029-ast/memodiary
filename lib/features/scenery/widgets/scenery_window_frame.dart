import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../models/shanshui_atmosphere.dart';

/// Top overlay strip inside the `Shanshui Scenery Card` window, offset clear of
/// the left-hanging `Bamboo Blind Pull-Cord` and displaying Time/Weather,
/// [realmBadge], seasonal title, and seasonal seal.
class SceneryWindowOverlayStrip extends StatelessWidget {
  final ShanshuiAtmosphereState atmosphere;
  final InkDiaryTokens tokens;
  final double maxWidth;
  final Widget realmBadge;

  const SceneryWindowOverlayStrip({
    super.key,
    required this.atmosphere,
    required this.tokens,
    required this.maxWidth,
    required this.realmBadge,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = maxWidth < 360;
    return Positioned(
      top: 14,
      left: 72,
      right: 8,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isCompact ? 56.0 : maxWidth * 0.25,
                ),
                child: Text(
                  atmosphere.titleZh,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: isCompact ? 10.0 : 11.0,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF7F4EB),
                    letterSpacing: isCompact ? 0.2 : 1.0,
                    shadows: const [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: tokens.cinnabar,
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
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final frameDark = isDark ? const Color(0xFF1C140F) : const Color(0xFF3D2719);
    final frameMid = isDark ? const Color(0xFF2D2018) : const Color(0xFF593A26);
    final frameHighlight =
        isDark ? const Color(0xFF473325) : const Color(0xFF785036);

    return Container(
      key: const Key('scenery_window_frame'),
      padding: const EdgeInsets.fromLTRB(6.0, 5.0, 6.0, 3.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [frameDark, frameMid],
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
              // Recessed inner shadow + beveled warm wood highlight + volumetric rays + valance + balustrade
              IgnorePointer(
                child: CustomPaint(
                  painter: _SceneryWindowOverlayPainter(
                    isDark: isDark,
                    frameDark: frameDark,
                    frameMid: frameMid,
                    frameHighlight: frameHighlight,
                  ),
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
  final bool isDark;
  final Color frameDark;
  final Color frameMid;
  final Color frameHighlight;

  const _SceneryWindowOverlayPainter({
    required this.isDark,
    required this.frameDark,
    required this.frameMid,
    required this.frameHighlight,
  });

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
    final sillHeight = 7.0;
    final railTopY = size.height - 20.0;
    final sillTopY = size.height - sillHeight;

    final railColor = isDark ? const Color(0xEB2A1C14) : const Color(0xEB4A2F1D);
    final sillColor = isDark ? const Color(0xF218100B) : const Color(0xF2362214);
    final postColor = isDark ? const Color(0xE6241710) : const Color(0xE6422A1A);
    final highlightColor = frameHighlight.withValues(alpha: 0.45);

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
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2E2015),
          Color(0xFF3E2B1C),
          Color(0xFF281B11),
        ],
      ).createShader(valanceRect);
    canvas.drawRect(valanceRect, valancePaint);

    // Fine bamboo slat weave lines inside the rolled valance
    final slatPaint = Paint()
      ..color = const Color(0xFF634830).withValues(alpha: 0.72)
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
      Paint()..color = const Color(0xFF5C4028),
    );
    canvas.drawLine(
      Offset(0, valanceHeight - 0.5),
      Offset(size.width, valanceHeight - 0.5),
      Paint()
        ..color = const Color(0xFF8C6B48).withValues(alpha: 0.55)
        ..strokeWidth = 0.7,
    );
  }

  void _paintInnerWoodBevel(Canvas canvas, Size size) {
    // Subtle recessed shadow along top/sides + crisp warm wood inner highlight
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
      ..color = frameHighlight.withValues(alpha: 0.55);
    canvas.drawRect(
      Rect.fromLTWH(0.5, 0.5, size.width - 1.0, size.height - 1.0),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SceneryWindowOverlayPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.frameDark != frameDark ||
        oldDelegate.frameMid != frameMid ||
        oldDelegate.frameHighlight != frameHighlight;
  }
}
