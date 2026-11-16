import 'dart:io';
import 'package:flutter/material.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';

/// Wet-mounted album leaf thumbnail (*册页平裱*) for timeline entry cards.
///
/// Frames the entry's primary photo inside a Song-brocade silk mat (`#E8DFCE`),
/// outer frame (`#B8A689`), inner painting core rule (`#9A7B48`), and subtle
/// 45° corner miter seam lines (`#9C8B70`) without any overlapping seal stamp.
class WetMountedThumbnail extends StatelessWidget {
  static const Color silkBrocadeMatColor = Color(0xFFE8DFCE);
  static const Color outerBorderColor = Color(0xFFB8A689);
  static const Color innerFrameColor = Color(0xFF9A7B48);
  static const Color miterSeamColor = Color(0xFF9C8B70);

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

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: silkBrocadeMatColor,
        borderRadius: BorderRadius.circular(2.0),
        border: Border.all(color: outerBorderColor, width: 1.0),
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
          // Subtle Song-brocade weave & 45° corner miter seam lines
          const IgnorePointer(
            child: CustomPaint(
              painter: _WetMountSilkMiterPainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.5),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C2226),
                border: Border.all(color: innerFrameColor, width: 1.0),
              ),
              child: _buildMediaContent(tokens),
            ),
          ),
        ],
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
        child: Icon(
          Icons.image_outlined,
          color: tokens.qingmo,
          size: 20,
        ),
      ),
    );
  }
}

class _WetMountSilkMiterPainter extends CustomPainter {
  const _WetMountSilkMiterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 12 || size.height <= 12) return;

    // Subtle Song-brocade weave dots across the silk border
    final weavePaint = Paint()
      ..color = WetMountedThumbnail.innerFrameColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    for (double y = 3.0; y < size.height; y += 6.0) {
      for (double x = 3.0; x < size.width; x += 6.0) {
        canvas.drawCircle(Offset(x, y), 0.55, weavePaint);
      }
    }

    // Subtle inner highlight inset along the silk mat perimeter
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFFCF5).withValues(alpha: 0.55)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(0.5, 0.5, size.width - 1.0, size.height - 1.0),
      highlightPaint,
    );

    // Four 45° corner miter seam lines
    final seamPaint = Paint()
      ..color = WetMountedThumbnail.miterSeamColor
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
  bool shouldRepaint(covariant _WetMountSilkMiterPainter oldDelegate) => false;
}
