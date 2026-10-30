import 'package:flutter/material.dart';
import '../../editor/models/typography_settings.dart';
import '../models/template_style.dart';
import 'template_canvas_painter.dart';

/// Container that renders procedural paper styling behind its child.
class TemplateCanvasContainer extends StatelessWidget {
  final TemplateStyle style;
  final Widget child;
  final TypographySettings? typography;
  final double scrollOffset;
  final double headerHeight;

  /// Optional override for canvas padding.
  ///
  /// When wrapping scrollable in-paper headers or docks that manage their own horizontal
  /// margins, pass [customPadding]: EdgeInsets.zero to prevent double padding with [style.marginHorizontal].
  final EdgeInsetsGeometry? customPadding;

  const TemplateCanvasContainer({
    super.key,
    required this.style,
    required this.child,
    this.typography,
    this.scrollOffset = 0.0,
    this.headerHeight = 0.0,
    this.customPadding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TemplateCanvasPainter(
        style: style,
        typography: typography,
        scrollOffset: scrollOffset,
        headerHeight: headerHeight,
      ),
      child: Padding(
        padding: customPadding ??
            EdgeInsets.symmetric(
              horizontal: style.marginHorizontal,
              vertical: 24.0,
            ),
        child: child,
      ),
    );
  }
}
