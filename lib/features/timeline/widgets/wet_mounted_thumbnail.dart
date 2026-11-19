import 'dart:io';
import 'package:flutter/material.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';

/// Wet-mounted album leaf thumbnail (*册页平裱*) for timeline entry cards.
///
/// Frames the entry's primary photo inside a palette-harmonized Song-brocade silk
/// mat, 45° corner miter seam lines, inner core rule, and a non-interactive
/// bottom-left 2×2 `云皓珍藏` cinnabar collector seal.
class WetMountedThumbnail extends StatelessWidget {
  final String relativePath;
  final MediaSandboxService mediaService;
  final double width;
  final double height;

  const WetMountedThumbnail({
    super.key,
    required this.relativePath,
    required this.mediaService,
    this.width = 82.0,
    this.height = 62.0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final palette = context.atmospherePalette;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.silkMountBg,
        borderRadius: BorderRadius.circular(2.0),
        border: Border.all(color: palette.silkMountBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 3.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(
              painter: _WetMountSilkMiterPainter(
                silkMountBg: palette.silkMountBg,
                silkMountBorder: palette.silkMountBorder,
                innerFrameColor: palette.silkInnerFrame,
                miterSeamColor: palette.silkMiterSeam,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.5),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C2226),
                border: Border.all(color: palette.silkInnerFrame, width: 1.0),
              ),
              child: _buildMediaContent(tokens),
            ),
          ),
          _buildCollectorSeal(palette),
        ],
      ),
    );
  }

  Widget _buildCollectorSeal(AtmospherePalette palette) {
    return Positioned(
      left: 2.5,
      bottom: 2.5,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Transform.rotate(
            angle: -0.035,
            child: Container(
              key: const Key('wet_mount_collector_seal'),
              width: 15.0,
              height: 15.0,
              decoration: BoxDecoration(
                color: palette.sealAccent,
                borderRadius: BorderRadius.circular(1.5),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 1.5,
                    offset: const Offset(0, 0.5),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '云皓\n珍藏',
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 5.2,
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent(InkDiaryTokens tokens) {
    return FutureBuilder<File>(
      future: mediaService.getFileFromRelativePath(relativePath),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null && file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(tokens),
          );
        }
        return _buildPlaceholder(tokens);
      },
    );
  }

  Widget _buildPlaceholder(InkDiaryTokens tokens) {
    return ColoredBox(
      color: tokens.agedFiber,
      child: Center(
        child: Icon(Icons.image_outlined, color: tokens.qingmo, size: 20),
      ),
    );
  }
}

class _WetMountSilkMiterPainter extends CustomPainter {
  final Color silkMountBg;
  final Color silkMountBorder;
  final Color innerFrameColor;
  final Color miterSeamColor;

  const _WetMountSilkMiterPainter({
    required this.silkMountBg,
    required this.silkMountBorder,
    required this.innerFrameColor,
    required this.miterSeamColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 12 || size.height <= 12) return;

    // Subtle Song-brocade weave dots across the silk border
    final weavePaint = Paint()
      ..color = innerFrameColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    for (double y = 3.0; y < size.height; y += 6.0) {
      for (double x = 3.0; x < size.width; x += 6.0) {
        canvas.drawCircle(Offset(x, y), 0.55, weavePaint);
      }
    }

    // Subtle inner highlight inset along the silk mat perimeter
    final highlightColor = Color.lerp(silkMountBg, Colors.white, 0.72) ?? const Color(0xFFFFFCF5);
    final highlightPaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.55)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0.5, 0.5, size.width - 1.0, size.height - 1.0), highlightPaint);

    // Subtle mat edge bevel bordering the mounted inner frame
    final bevelPaint = Paint()
      ..color = silkMountBorder.withValues(alpha: 0.24)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(4.0, 4.0, size.width - 8.0, size.height - 8.0), bevelPaint);

    // Four 45° corner miter seam lines
    final seamPaint = Paint()
      ..color = miterSeamColor
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    const seamLength = 5.5;
    canvas.drawLine(Offset.zero, const Offset(seamLength, seamLength), seamPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - seamLength, seamLength), seamPaint);
    canvas.drawLine(Offset(0, size.height), Offset(seamLength, size.height - seamLength), seamPaint);
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - seamLength, size.height - seamLength),
      seamPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WetMountSilkMiterPainter oldDelegate) =>
      oldDelegate.silkMountBg != silkMountBg ||
      oldDelegate.silkMountBorder != silkMountBorder ||
      oldDelegate.innerFrameColor != innerFrameColor ||
      oldDelegate.miterSeamColor != miterSeamColor;
}
