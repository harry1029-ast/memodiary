import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:memodiary/features/home/widgets/diarist_panel_controller.dart';

/// Lays the Diarist Panel over the whole Home Shell (header and Tab Rail
/// included): the panel slides in from the left at [controller]'s open
/// fraction while the shell behind dims and shifts slightly.
///
/// Tapping the dimmed strip or swiping left closes the panel. While any of the
/// panel shows, the shell behind is hidden from screen readers and the panel
/// names itself as a route (`我的`), so it is announced when it opens.
class DiaristPanelOverlay extends StatelessWidget {
  /// Share of the screen width the open panel covers, before [maxPanelWidth].
  static const double widthFactor = 0.85;
  static const double maxPanelWidth = 420.0;

  /// How far the shell behind shifts right when the panel is fully open.
  static const double contentShift = 24.0;
  static const double _maxScrimAlpha = 0.45;

  final DiaristPanelController controller;
  final Widget panel;
  final Widget child;

  const DiaristPanelOverlay({
    super.key,
    required this.controller,
    required this.panel,
    required this.child,
  });

  /// The open panel's width on a screen [screenWidth] wide.
  static double panelWidthFor(double screenWidth) => math.min(screenWidth * widthFactor, maxPanelWidth);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = panelWidthFor(constraints.maxWidth);

        void handleDragUpdate(DragUpdateDetails details) => controller.dragBy(details.primaryDelta!, panelWidth);
        void handleDragEnd(DragEndDetails details) => controller.settleFrom(details.primaryVelocity ?? 0.0, panelWidth);

        return AnimatedBuilder(
          animation: controller.animation,
          child: child,
          builder: (context, shell) {
            final fraction = controller.fraction;
            final isShowing = fraction > 0;
            return Stack(
              children: [
                Transform.translate(
                  offset: Offset(contentShift * fraction, 0),
                  child: ExcludeSemantics(excluding: isShowing, child: shell),
                ),
                if (isShowing)
                  Positioned.fill(
                    child: Semantics(
                      button: true,
                      label: '关闭我的',
                      onTap: controller.close,
                      child: GestureDetector(
                        key: const Key('diarist_panel_scrim'),
                        behavior: HitTestBehavior.opaque,
                        excludeFromSemantics: true,
                        onTap: controller.close,
                        onHorizontalDragUpdate: handleDragUpdate,
                        onHorizontalDragEnd: handleDragEnd,
                        child: ColoredBox(
                          color: Colors.black.withValues(
                            alpha: _maxScrimAlpha * fraction,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isShowing)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: -panelWidth * (1 - fraction),
                    width: panelWidth,
                    child: Semantics(
                      scopesRoute: true,
                      namesRoute: true,
                      explicitChildNodes: true,
                      label: '我的',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        excludeFromSemantics: true,
                        onHorizontalDragUpdate: handleDragUpdate,
                        onHorizontalDragEnd: handleDragEnd,
                        child: panel,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
