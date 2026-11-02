import 'package:flutter/material.dart';

/// Test double recording lines, circles, rects, and paths painted via Canvas.
class RecordingCanvas implements Canvas {
  final List<(Offset, Offset, Paint)> drawnLines = [];
  final List<(Offset, double, Paint)> drawnCircles = [];
  final List<(Rect, Paint)> drawnRects = [];
  final List<(Path, Paint)> drawnPaths = [];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    drawnLines.add((p1, p2, paint));
  }

  @override
  void drawCircle(Offset center, double radius, Paint paint) {
    drawnCircles.add((center, radius, paint));
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    drawnRects.add((rect, paint));
  }

  @override
  void drawPath(Path path, Paint paint) {
    drawnPaths.add((path, paint));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
