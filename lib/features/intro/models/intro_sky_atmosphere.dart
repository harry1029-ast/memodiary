import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// Atmospheric color and lighting stop for a specific hour of the 24-hour cycle.
@immutable
class IntroSkyKeyframe {
  final double hour;
  final String phaseName;
  final String mode;
  final Color skyTop;
  final Color skyMid;
  final Color skyHorizon;
  final Color waterBase;
  final Color farMountain;
  final Color midMountain;
  final Color nearMountain;
  final Color cloudTint;
  final double starOpacity;
  final double lanternGlow;
  final double nightFactor;

  const IntroSkyKeyframe({
    required this.hour,
    required this.phaseName,
    required this.mode,
    required this.skyTop,
    required this.skyMid,
    required this.skyHorizon,
    required this.waterBase,
    required this.farMountain,
    required this.midMountain,
    required this.nearMountain,
    required this.cloudTint,
    required this.starOpacity,
    required this.lanternGlow,
    required this.nightFactor,
  });
}

/// Interpolated 24-hour Shanshui sky, mountain, water, and lantern lighting state.
@immutable
class InterpolatedIntroSky {
  final double hour;
  final String phaseName;
  final String mode;
  final Color skyTop;
  final Color skyMid;
  final Color skyHorizon;
  final Color waterBase;
  final Color farMountain;
  final Color midMountain;
  final Color nearMountain;
  final Color cloudTint;
  final double starOpacity;
  final double lanternGlow;
  final double nightFactor;

  const InterpolatedIntroSky({
    required this.hour,
    required this.phaseName,
    required this.mode,
    required this.skyTop,
    required this.skyMid,
    required this.skyHorizon,
    required this.waterBase,
    required this.farMountain,
    required this.midMountain,
    required this.nearMountain,
    required this.cloudTint,
    required this.starOpacity,
    required this.lanternGlow,
    required this.nightFactor,
  });

  /// Canonical 7 keyframes across the 24-hour diurnal cycle (`皓月夜` & `云岚昼`).
  static const List<IntroSkyKeyframe> keyframes = [
    IntroSkyKeyframe(
      hour: 0.0,
      phaseName: '皓月夜 · 子夜星河',
      mode: '皓月夜',
      skyTop: Color(0xFF070D19),
      skyMid: Color(0xFF111E36),
      skyHorizon: Color(0xFF1E3150),
      waterBase: Color(0xFF0B1424),
      farMountain: Color(0xFF16253E),
      midMountain: Color(0xFF0F1B2E),
      nearMountain: Color(0xFF080F1C),
      cloudTint: Color(0xFF6580A8),
      starOpacity: 0.95,
      lanternGlow: 1.0,
      nightFactor: 1.0,
    ),
    IntroSkyKeyframe(
      hour: 5.5,
      phaseName: '晓岚 · 晨曦破晓',
      mode: '云岚昼',
      skyTop: Color(0xFF243554),
      skyMid: Color(0xFF586D8C),
      skyHorizon: Color(0xFFDF9B7C),
      waterBase: Color(0xFF334663),
      farMountain: Color(0xFF445570),
      midMountain: Color(0xFF2E3D54),
      nearMountain: Color(0xFF1E2838),
      cloudTint: Color(0xFFF2C1AE),
      starOpacity: 0.25,
      lanternGlow: 0.45,
      nightFactor: 0.4,
    ),
    IntroSkyKeyframe(
      hour: 8.5,
      phaseName: '云岚昼 · 碧空流云',
      mode: '云岚昼',
      skyTop: Color(0xFF6A93BC),
      skyMid: Color(0xFF9EC0DF),
      skyHorizon: Color(0xFFE8F1F8),
      waterBase: Color(0xFF7FA6C9),
      farMountain: Color(0xFF7394B2),
      midMountain: Color(0xFF527391),
      nearMountain: Color(0xFF36516B),
      cloudTint: Color(0xFFFFFFFF),
      starOpacity: 0.0,
      lanternGlow: 0.0,
      nightFactor: 0.0,
    ),
    IntroSkyKeyframe(
      hour: 13.0,
      phaseName: '云岚昼 · 云山清朗',
      mode: '云岚昼',
      skyTop: Color(0xFF759EC7),
      skyMid: Color(0xFFB2CFE8),
      skyHorizon: Color(0xFFF5F4EC),
      waterBase: Color(0xFF8EB2D1),
      farMountain: Color(0xFF7C9CB8),
      midMountain: Color(0xFF5A7B96),
      nearMountain: Color(0xFF3C5870),
      cloudTint: Color(0xFFFFFFFF),
      starOpacity: 0.0,
      lanternGlow: 0.0,
      nightFactor: 0.0,
    ),
    IntroSkyKeyframe(
      hour: 17.5,
      phaseName: '暮霞 · 落日熔金',
      mode: '云岚昼',
      skyTop: Color(0xFF2D3A59),
      skyMid: Color(0xFF7D6378),
      skyHorizon: Color(0xFFE59568),
      waterBase: Color(0xFF494761),
      farMountain: Color(0xFF4A4761),
      midMountain: Color(0xFF32324A),
      nearMountain: Color(0xFF1F2033),
      cloudTint: Color(0xFFF5B792),
      starOpacity: 0.2,
      lanternGlow: 0.72,
      nightFactor: 0.45,
    ),
    IntroSkyKeyframe(
      hour: 19.5,
      phaseName: '皓月夜 · 华灯初上',
      mode: '皓月夜',
      skyTop: Color(0xFF0E182B),
      skyMid: Color(0xFF1B2D4D),
      skyHorizon: Color(0xFF2E466C),
      waterBase: Color(0xFF132038),
      farMountain: Color(0xFF1F314F),
      midMountain: Color(0xFF142238),
      nearMountain: Color(0xFF0C1524),
      cloudTint: Color(0xFF88A4CC),
      starOpacity: 0.85,
      lanternGlow: 1.0,
      nightFactor: 0.92,
    ),
    IntroSkyKeyframe(
      hour: 24.0,
      phaseName: '皓月夜 · 子夜星河',
      mode: '皓月夜',
      skyTop: Color(0xFF070D19),
      skyMid: Color(0xFF111E36),
      skyHorizon: Color(0xFF1E3150),
      waterBase: Color(0xFF0B1424),
      farMountain: Color(0xFF16253E),
      midMountain: Color(0xFF0F1B2E),
      nearMountain: Color(0xFF080F1C),
      cloudTint: Color(0xFF6580A8),
      starOpacity: 0.95,
      lanternGlow: 1.0,
      nightFactor: 1.0,
    ),
  ];

  /// Computes the smooth interpolated sky atmosphere for any fractional [hour].
  factory InterpolatedIntroSky.fromHour(double hour) {
    final h = ((hour % 24.0) + 24.0) % 24.0;
    int index = 0;
    while (index < keyframes.length - 2 && h >= keyframes[index + 1].hour) {
      index++;
    }
    final k1 = keyframes[index];
    final k2 = keyframes[index + 1];
    final span = math.max(0.001, k2.hour - k1.hour);
    final t = ((h - k1.hour) / span).clamp(0.0, 1.0);

    return InterpolatedIntroSky(
      hour: h,
      phaseName: t < 0.5 ? k1.phaseName : k2.phaseName,
      mode: (h >= 18.0 || h < 6.0) ? '皓月夜' : '云岚昼',
      skyTop: Color.lerp(k1.skyTop, k2.skyTop, t)!,
      skyMid: Color.lerp(k1.skyMid, k2.skyMid, t)!,
      skyHorizon: Color.lerp(k1.skyHorizon, k2.skyHorizon, t)!,
      waterBase: Color.lerp(k1.waterBase, k2.waterBase, t)!,
      farMountain: Color.lerp(k1.farMountain, k2.farMountain, t)!,
      midMountain: Color.lerp(k1.midMountain, k2.midMountain, t)!,
      nearMountain: Color.lerp(k1.nearMountain, k2.nearMountain, t)!,
      cloudTint: Color.lerp(k1.cloudTint, k2.cloudTint, t)!,
      starOpacity: lerpDouble(k1.starOpacity, k2.starOpacity, t)!,
      lanternGlow: lerpDouble(k1.lanternGlow, k2.lanternGlow, t)!,
      nightFactor: lerpDouble(k1.nightFactor, k2.nightFactor, t)!,
    );
  }

  /// Whether the interpolated sky lighting is predominantly nighttime.
  bool get isNight => nightFactor > 0.52;
}

/// Parabolic east-to-west orbital coordinates and illumination metadata for the Sun or Moon.
@immutable
class CelestialOrbPosition {
  final bool isMoon;
  final double progress;
  final double refX;
  final double refY;
  final double x;
  final double y;
  final double edgeFade;
  final double lightAngleDeg;

  const CelestialOrbPosition({
    required this.isMoon,
    required this.progress,
    required this.refX,
    required this.refY,
    required this.x,
    required this.y,
    required this.edgeFade,
    required this.lightAngleDeg,
  });

  /// Computes the celestial orb coordinates scaled from the `400x812` design canvas to [canvasSize].
  factory CelestialOrbPosition.fromHour(double hour, Size canvasSize) {
    final h = ((hour % 24.0) + 24.0) % 24.0;
    final isMoon = h >= 18.0 || h < 6.0;
    final double progress;
    if (!isMoon) {
      progress = (h - 6.0) / 12.0;
    } else {
      final nightElapsed = h >= 18.0 ? h - 18.0 : h + 6.0;
      progress = nightElapsed / 12.0;
    }

    final refX = 36.0 + progress * 328.0;
    final arcLift = 4.0 * progress * (1.0 - progress);
    final refY = 212.0 - arcLift * 116.0;

    final scaleX = canvasSize.width / 400.0;
    final scaleY = canvasSize.height / 812.0;
    final x = refX * scaleX;
    final y = refY * scaleY;

    final edgeFade = math
        .min(1.0, math.min(progress * 6.5, (1.0 - progress) * 6.5))
        .clamp(0.0, 1.0);
    final lightAngleDeg = 105.0 + (progress - 0.5) * 70.0;

    return CelestialOrbPosition(
      isMoon: isMoon,
      progress: progress,
      refX: refX,
      refY: refY,
      x: x,
      y: y,
      edgeFade: edgeFade,
      lightAngleDeg: lightAngleDeg,
    );
  }
}
