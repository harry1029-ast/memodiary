import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/features/home/widgets/diarist_panel_controller.dart';
import 'package:memodiary/features/home/widgets/diarist_panel_overlay.dart';

/// The silk bookmark ribbon peeking from the left edge that shows where the
/// Diarist Panel can be dragged out.
///
/// It sits centred in the left-edge drag band, rides the panel's right edge
/// while the panel is dragged, and disappears once the panel is fully open.
/// Tapping it opens the panel. It is left out of semantics because the
/// header's cloud-avatar button (`我的`) is the accessible way in.
class DiaristPanelRibbonTab extends StatelessWidget {
  /// Visible ribbon size.
  static const Size ribbonSize = Size(7, 40);

  /// Touch area around the ribbon (≥ 44×44dp).
  static const Size hitSize = Size(44, 48);

  final DiaristPanelController controller;
  final double panelWidth;

  /// The drag band this ribbon marks, in logical pixels.
  final Rect band;

  const DiaristPanelRibbonTab({
    super.key,
    required this.controller,
    required this.panelWidth,
    required this.band,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    final top = band.center.dy - hitSize.height / 2;
    return AnimatedBuilder(
      animation: controller.animation,
      builder: (context, child) {
        final fraction = controller.fraction;
        if (fraction >= 1.0) return const SizedBox.shrink();
        // The band lives inside the content that the overlay shifts right by
        // contentShift × fraction, so subtract it to land on the panel edge.
        return Positioned(
          left: fraction * (panelWidth - DiaristPanelOverlay.contentShift),
          top: top,
          width: hitSize.width,
          height: hitSize.height,
          child: child!,
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        dragStartBehavior: DragStartBehavior.down,
        onTap: controller.open,
        onHorizontalDragUpdate: (details) => controller.dragBy(details.primaryDelta!, panelWidth),
        onHorizontalDragEnd: (details) => controller.settleFrom(details.primaryVelocity ?? 0.0, panelWidth),
        child: Align(
          alignment: Alignment.centerLeft,
          child: CustomPaint(
            key: const Key('diarist_panel_ribbon_tab'),
            size: ribbonSize,
            painter: _SilkRibbonPainter(
              silk: palette.accentPrimary,
              shade: palette.accentPrimaryDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// A vertical silk ribbon with a swallowtail notch at its foot.
class _SilkRibbonPainter extends CustomPainter {
  final Color silk;
  final Color shade;

  const _SilkRibbonPainter({required this.silk, required this.shade});

  @override
  void paint(Canvas canvas, Size size) {
    const notch = 5.0;
    final w = size.width;
    final h = size.height;
    final ribbon = Path()
      ..moveTo(0, 0)
      ..lineTo(w - 1.5, 0)
      ..quadraticBezierTo(w, 0, w, 1.5)
      ..lineTo(w, h)
      ..lineTo(w / 2, h - notch)
      ..lineTo(0, h)
      ..close();

    canvas.drawShadow(ribbon, Colors.black, 1.5, false);
    canvas.drawPath(
      ribbon,
      Paint()
        ..shader = LinearGradient(
          colors: [shade, silk, silk.withValues(alpha: 0.92)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );
    // Sheen line along the silk.
    canvas.drawLine(
      Offset(w * 0.62, 2),
      Offset(w * 0.62, h - notch - 1),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_SilkRibbonPainter oldDelegate) =>
      oldDelegate.silk != silk || oldDelegate.shade != shade;
}
