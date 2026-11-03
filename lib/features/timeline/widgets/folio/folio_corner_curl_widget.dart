import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paints the tactile paper dog-ear corner curl with drop shadow and silk gradient.
class FolioDogEarCurlPainter extends CustomPainter {
  final bool isRight;

  const FolioDogEarCurlPainter({required this.isRight});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Drop shadow under curled paper corner
    final shadowPath = Path();
    if (isRight) {
      shadowPath
        ..moveTo(width, 0)
        ..lineTo(0, height)
        ..lineTo(0, height + 4)
        ..lineTo(width, height + 4)
        ..close();
    } else {
      shadowPath
        ..moveTo(0, 0)
        ..lineTo(width, height)
        ..lineTo(width, height + 4)
        ..lineTo(0, height + 4)
        ..close();
    }
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Curled page triangle
    final curlPath = Path();
    if (isRight) {
      curlPath
        ..moveTo(width, 0)
        ..lineTo(0, height)
        ..lineTo(width, height)
        ..close();
    } else {
      curlPath
        ..moveTo(0, 0)
        ..lineTo(width, height)
        ..lineTo(0, height)
        ..close();
    }

    canvas.drawPath(
      curlPath,
      Paint()
        ..shader = LinearGradient(
          colors: const [
            Color(0x26000000),
            Color(0xEDEADFC9),
            Color(0xFFFDFBF7),
          ],
          begin: isRight ? Alignment.topLeft : Alignment.topRight,
          end: isRight ? Alignment.bottomRight : Alignment.bottomLeft,
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant FolioDogEarCurlPainter oldDelegate) =>
      oldDelegate.isRight != isRight;
}

/// Interactive dog-ear corner touch and peel zone with hover/press expansion,
/// light haptics, screen reader semantics, and horizontal drag tracking.
class FolioCornerCurlWidget extends StatefulWidget {
  final bool isNext;
  final VoidCallback? onTap;
  final GestureDragStartCallback? onHorizontalDragStart;
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;
  final bool enabled;

  const FolioCornerCurlWidget({
    super.key,
    required this.isNext,
    this.onTap,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.enabled = true,
  });

  @override
  State<FolioCornerCurlWidget> createState() => _FolioCornerCurlWidgetState();
}

class _FolioCornerCurlWidgetState extends State<FolioCornerCurlWidget> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isExpanded => _isHovered || _isPressed;

  void _handleTap() {
    if (!widget.enabled) return;
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _handleDragStart(DragStartDetails details) {
    if (!widget.enabled) return;
    HapticFeedback.lightImpact();
    widget.onHorizontalDragStart?.call(details);
  }

  @override
  Widget build(BuildContext context) {
    final double zoneSize = widget.isNext ? 96.0 : 86.0;
    final double restingSize = widget.isNext ? 34.0 : 24.0;
    final double expandedSize = widget.isNext ? 52.0 : 44.0;
    final double curlSize = _isExpanded ? expandedSize : restingSize;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.isNext ? '下一页' : '上一页',
      child: SizedBox(
        width: zoneSize,
        height: zoneSize,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.grab
              : SystemMouseCursors.basic,
          onEnter: (_) {
            if (widget.enabled && !_isHovered) setState(() => _isHovered = true);
          },
          onExit: (_) {
            if (_isHovered) setState(() => _isHovered = false);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              if (widget.enabled) setState(() => _isPressed = true);
            },
            onTapCancel: () {
              if (_isPressed) setState(() => _isPressed = false);
            },
            onTapUp: (_) {
              if (_isPressed) setState(() => _isPressed = false);
            },
            onTap: _handleTap,
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: widget.onHorizontalDragUpdate,
            onHorizontalDragEnd: widget.onHorizontalDragEnd,
            child: Stack(
              alignment: widget.isNext
                  ? Alignment.bottomRight
                  : Alignment.bottomLeft,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: curlSize,
                  height: curlSize,
                  child: CustomPaint(
                    painter: FolioDogEarCurlPainter(isRight: widget.isNext),
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
