import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:memodiary/core/services/system_gesture_exclusion.dart';
import 'package:memodiary/features/home/widgets/diarist_panel_controller.dart';
import 'package:memodiary/features/home/widgets/diarist_panel_overlay.dart';

/// The left-edge strip from which the diarist drags the Diarist Panel out.
///
/// The strip is limited to an upper band, from the top of the safe area down
/// at most [maxBandHeight] (the header and scenery window), so below it the
/// left edge stays free for Android's system Back gesture.
///
/// While its route is the visible one, the band is reserved from system Back
/// through [SystemGestureExclusion]; the reservation is cleared as soon as
/// another route covers it or the shell is replaced.
class DiaristPanelEdgeBand extends StatefulWidget {
  /// Width of the draggable strip at the left edge.
  static const double bandWidth = 20.0;

  /// Android honours at most 200dp of gesture exclusion per edge.
  static const double maxBandHeight = 200.0;

  final DiaristPanelController controller;
  final Widget child;

  const DiaristPanelEdgeBand({
    super.key,
    required this.controller,
    required this.child,
  });

  /// The band in logical pixels for a screen of [size] with [padding] insets.
  static Rect bandRectFor(Size size, EdgeInsets padding) {
    final height = (size.height - padding.top).clamp(0.0, maxBandHeight);
    return Rect.fromLTWH(0, padding.top, bandWidth, height);
  }

  @override
  State<DiaristPanelEdgeBand> createState() => _DiaristPanelEdgeBandState();
}

class _DiaristPanelEdgeBandState extends State<DiaristPanelEdgeBand> {
  static const SystemGestureExclusion _exclusion = SystemGestureExclusion();

  /// The rect last sent to the platform, or null while nothing is excluded.
  Rect? _excludedRect;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isVisibleRoute = ModalRoute.isCurrentOf(context) ?? true;
    final band = DiaristPanelEdgeBand.bandRectFor(MediaQuery.sizeOf(context), MediaQuery.paddingOf(context));
    if (isVisibleRoute && band != _excludedRect) {
      _excludedRect = band;
      _exclusion.setRect(band).ignore();
    } else if (!isVisibleRoute && _excludedRect != null) {
      _clearExclusion();
    }
  }

  @override
  void dispose() {
    if (_excludedRect != null) _clearExclusion();
    super.dispose();
  }

  void _clearExclusion() {
    _excludedRect = null;
    _exclusion.clear().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final band = DiaristPanelEdgeBand.bandRectFor(size, MediaQuery.paddingOf(context));
    final panelWidth = DiaristPanelOverlay.panelWidthFor(size.width);
    final controller = widget.controller;
    return Stack(
      children: [
        widget.child,
        Positioned.fromRect(
          rect: band,
          child: GestureDetector(
            key: const Key('diarist_panel_edge_band'),
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
            dragStartBehavior: DragStartBehavior.down,
            onHorizontalDragUpdate: (details) =>
                controller.dragTo(controller.fraction + details.primaryDelta! / panelWidth),
            onHorizontalDragEnd: (details) =>
                controller.settle(velocity: (details.primaryVelocity ?? 0.0) / panelWidth),
          ),
        ),
      ],
    );
  }
}
