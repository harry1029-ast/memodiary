import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';

/// Base `CustomPainter` for 1500x1000 normalized scenery realm painters.
///
/// Centralizes coordinate-space scaling, canvas clipping, and shared
/// `shouldRepaint` comparisons while letting each realm implement [paintScene].
abstract class SceneryCanvasPainterBase extends CustomPainter {
  final ShanshuiAtmosphereState atmosphere;
  final double animationTime;
  final List<ShanshuiParticle> particles;
  final List<ShanshuiWeatherDrop> weatherDrops;
  final bool showCalligraphy;
  final bool fullPoem;
  final double lightningAlpha;
  final ui.Picture? cachedStaticPicture;

  const SceneryCanvasPainterBase({
    required this.atmosphere,
    required this.animationTime,
    required this.particles,
    required this.weatherDrops,
    this.showCalligraphy = false,
    this.fullPoem = false,
    this.lightningAlpha = 0.0,
    this.cachedStaticPicture,
  });

  /// Effective ripple count tracked by `shouldRepaint`.
  int get rippleCount => 0;

  /// Paints the realm layers in normalized `1500x1000` canvas coordinates.
  void paintScene(Canvas canvas);

  /// Override to compare realm-specific fields such as typed palettes.
  bool shouldRepaintExtra(covariant SceneryCanvasPainterBase oldDelegate) =>
      false;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1500.0, size.height / 1000.0);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 1500, 1000));
    paintScene(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SceneryCanvasPainterBase oldDelegate) {
    if (oldDelegate.runtimeType != runtimeType) return true;
    return oldDelegate.animationTime != animationTime ||
        oldDelegate.atmosphere != atmosphere ||
        oldDelegate.lightningAlpha != lightningAlpha ||
        oldDelegate.showCalligraphy != showCalligraphy ||
        oldDelegate.fullPoem != fullPoem ||
        oldDelegate.rippleCount != rippleCount ||
        oldDelegate.particles.length != particles.length ||
        oldDelegate.weatherDrops.length != weatherDrops.length ||
        oldDelegate.cachedStaticPicture != cachedStaticPicture ||
        shouldRepaintExtra(oldDelegate);
  }
}
