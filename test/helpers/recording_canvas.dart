import 'package:flutter/material.dart';

/// Test double recording lines, circles, and rects painted via Canvas.
class RecordingCanvas implements Canvas {
  final List<(Offset, Offset, Paint)> drawnLines = [];
  final List<(Offset, double, Paint)> drawnCircles = [];
  final List<(Rect, Paint)> drawnRects = [];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    drawnLines.add((p1, p2, paint));
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    drawnCircles.add((c, radius, paint));
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    drawnRects.add((rect, paint));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
