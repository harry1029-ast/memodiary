import 'package:flutter/material.dart';
import '../models/template_style.dart';
import 'template_canvas_painter.dart';

/// Container that renders procedural paper styling behind its child.
class TemplateCanvasContainer extends StatelessWidget {
  final TemplateStyle style;
  final Widget child;
  final EdgeInsetsGeometry? customPadding;

  const TemplateCanvasContainer({
    super.key,
    required this.style,
    required this.child,
    this.customPadding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TemplateCanvasPainter(style: style),
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

