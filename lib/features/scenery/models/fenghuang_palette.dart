import 'package:flutter/material.dart';
import 'shanshui_atmosphere.dart';

/// Complete atmospheric and seasonal color palette for the Xiangxi Fenghuang
/// Ancient Stilt Town (`凤凰`) realm across all four seasons and times of day.
@immutable
class FenghuangPalette {
  final Color skyTop;
  final Color skyBottom;
  final Color riverMist;
  final Color celestialColor;
  final Color celestialGlow;
  final double candleIntensity;

  // Tuojiang River water gradient
  final Color riverTop;
  final Color riverBottom;

  // NanHua & Wuling hills & seasonal foliage
  final Color mtnMid;
  final Color mtnBase;
  final Color foliagePrimary;
  final Color foliageSecondary;

  // Seasonal particles
  final String particleType;
  final Color particleColor1;
  final Color particleColor2;

  const FenghuangPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.riverMist,
    required this.celestialColor,
    required this.celestialGlow,
    required this.candleIntensity,
    required this.riverTop,
    required this.riverBottom,
    required this.mtnMid,
    required this.mtnBase,
    required this.foliagePrimary,
    required this.foliageSecondary,
    required this.particleType,
    required this.particleColor1,
    required this.particleColor2,
  });

  /// Resolves the Fenghuang palette for [season] and [timeOfDay].
  static FenghuangPalette of(
    ShanshuiSeason season,
    ShanshuiTimeOfDay timeOfDay,
  ) {
    final seasonBase = _seasonalBases[season]!;
    final timeSky = _timeLighting[season]![timeOfDay]!;
    return FenghuangPalette(
      skyTop: timeSky.skyTop,
      skyBottom: timeSky.skyBottom,
      riverMist: timeSky.riverMist,
      celestialColor: timeSky.celestialColor,
      celestialGlow: timeSky.celestialGlow,
      candleIntensity: timeSky.candleIntensity,
      riverTop: seasonBase.riverTop,
      riverBottom: seasonBase.riverBottom,
      mtnMid: seasonBase.mtnMid,
      mtnBase: seasonBase.mtnBase,
      foliagePrimary: seasonBase.foliagePrimary,
      foliageSecondary: seasonBase.foliageSecondary,
      particleType: seasonBase.particleType,
      particleColor1: seasonBase.particleColor1,
      particleColor2: seasonBase.particleColor2,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FenghuangPalette &&
        other.skyTop == skyTop &&
        other.skyBottom == skyBottom &&
        other.riverMist == riverMist &&
        other.celestialColor == celestialColor &&
        other.celestialGlow == celestialGlow &&
        other.candleIntensity == candleIntensity &&
        other.riverTop == riverTop &&
        other.riverBottom == riverBottom &&
        other.mtnMid == mtnMid &&
        other.mtnBase == mtnBase &&
        other.foliagePrimary == foliagePrimary &&
        other.foliageSecondary == foliageSecondary &&
        other.particleType == particleType &&
        other.particleColor1 == particleColor1 &&
        other.particleColor2 == particleColor2;
  }

  @override
  int get hashCode => Object.hash(
        skyTop,
        skyBottom,
        riverMist,
        celestialColor,
        celestialGlow,
        candleIntensity,
        riverTop,
        riverBottom,
        mtnMid,
        mtnBase,
        foliagePrimary,
        foliageSecondary,
        particleType,
        particleColor1,
        particleColor2,
      );

  static const Map<
      ShanshuiSeason,
      ({
        Color riverTop,
        Color riverBottom,
        Color mtnMid,
        Color mtnBase,
        Color foliagePrimary,
        Color foliageSecondary,
        String particleType,
        Color particleColor1,
        Color particleColor2,
      })> _seasonalBases = {
    ShanshuiSeason.spring: (
      riverTop: Color(0xFF4A8E82),
      riverBottom: Color(0xFF1F4E48),
      mtnMid: Color(0xFF8FB096),
      mtnBase: Color(0xFF52735D),
      foliagePrimary: Color(0xFFE57383),
      foliageSecondary: Color(0xFFF9B8C2),
      particleType: 'petals',
      particleColor1: Color(0xFFF08090),
      particleColor2: Color(0xFFFADCE2),
    ),
    ShanshuiSeason.summer: (
      riverTop: Color(0xFF2E7D6B),
      riverBottom: Color(0xFF134238),
      mtnMid: Color(0xFF689977),
      mtnBase: Color(0xFF2D523D),
      foliagePrimary: Color(0xFF2E6E49),
      foliageSecondary: Color(0xFF5CA377),
      particleType: 'fireflies',
      particleColor1: Color(0xFFB5F56C),
      particleColor2: Color(0xFFFFE57F),
    ),
    ShanshuiSeason.fall: (
      riverTop: Color(0xFF3E7A70),
      riverBottom: Color(0xFF1B3D38),
      mtnMid: Color(0xFFC79663),
      mtnBase: Color(0xFF784E30),
      foliagePrimary: Color(0xFFC8462C),
      foliageSecondary: Color(0xFFE88B38),
      particleType: 'leaves',
      particleColor1: Color(0xFFD14B30),
      particleColor2: Color(0xFFEB963E),
    ),
    ShanshuiSeason.winter: (
      riverTop: Color(0xFF4A6B78),
      riverBottom: Color(0xFF1D303A),
      mtnMid: Color(0xFFCBD5E1),
      mtnBase: Color(0xFF64748B),
      foliagePrimary: Color(0xFFF8FAFC),
      foliageSecondary: Color(0xFFD93848),
      particleType: 'snow',
      particleColor1: Color(0xFFFFFFFF),
      particleColor2: Color(0xFFE2E8F0),
    ),
  };

  static const Map<
      ShanshuiSeason,
      Map<
          ShanshuiTimeOfDay,
          ({
            Color skyTop,
            Color skyBottom,
            Color riverMist,
            Color celestialColor,
            Color celestialGlow,
            double candleIntensity,
          })>> _timeLighting = {
    ShanshuiSeason.spring: {
      ShanshuiTimeOfDay.dawn: (
        skyTop: Color(0xFF2E3B4E),
        skyBottom: Color(0xFFF0B6A4),
        riverMist: Color.fromRGBO(245, 210, 200, 0.55),
        celestialColor: Color(0xFFF26B4E),
        celestialGlow: Color.fromRGBO(242, 107, 78, 0.45),
        candleIntensity: 0.72,
      ),
      ShanshuiTimeOfDay.day: (
        skyTop: Color(0xFFCFE2DF),
        skyBottom: Color(0xFFF5EFE6),
        riverMist: Color.fromRGBO(255, 250, 244, 0.45),
        celestialColor: Color(0xFFE04836),
        celestialGlow: Color.fromRGBO(255, 220, 175, 0.55),
        candleIntensity: 0.20,
      ),
      ShanshuiTimeOfDay.dusk: (
        skyTop: Color(0xFF6E5568),
        skyBottom: Color(0xFFF29F6D),
        riverMist: Color.fromRGBO(242, 175, 140, 0.48),
        celestialColor: Color(0xFFE8532C),
        celestialGlow: Color.fromRGBO(232, 83, 44, 0.50),
        candleIntensity: 0.88,
      ),
      ShanshuiTimeOfDay.night: (
        skyTop: Color(0xFF111C28),
        skyBottom: Color(0xFF263849),
        riverMist: Color.fromRGBO(42, 62, 82, 0.50),
        celestialColor: Color(0xFFF7F4E0),
        celestialGlow: Color.fromRGBO(210, 230, 255, 0.38),
        candleIntensity: 1.0,
      ),
    },
    ShanshuiSeason.summer: {
      ShanshuiTimeOfDay.dawn: (
        skyTop: Color(0xFF1F3A42),
        skyBottom: Color(0xFFE6C2A8),
        riverMist: Color.fromRGBO(210, 232, 224, 0.52),
        celestialColor: Color(0xFFF0754F),
        celestialGlow: Color.fromRGBO(240, 117, 79, 0.42),
        candleIntensity: 0.68,
      ),
      ShanshuiTimeOfDay.day: (
        skyTop: Color(0xFFB5DCD1),
        skyBottom: Color(0xFFEBF5F0),
        riverMist: Color.fromRGBO(235, 248, 242, 0.42),
        celestialColor: Color(0xFFE64E35),
        celestialGlow: Color.fromRGBO(255, 235, 185, 0.55),
        candleIntensity: 0.18,
      ),
      ShanshuiTimeOfDay.dusk: (
        skyTop: Color(0xFF4A5D66),
        skyBottom: Color(0xFFEDA56C),
        riverMist: Color.fromRGBO(235, 185, 145, 0.45),
        celestialColor: Color(0xFFEB6034),
        celestialGlow: Color.fromRGBO(235, 96, 52, 0.48),
        candleIntensity: 0.86,
      ),
      ShanshuiTimeOfDay.night: (
        skyTop: Color(0xFF0D1F24),
        skyBottom: Color(0xFF1E3A40),
        riverMist: Color.fromRGBO(32, 65, 70, 0.50),
        celestialColor: Color(0xFFF7F6E4),
        celestialGlow: Color.fromRGBO(195, 235, 230, 0.38),
        candleIntensity: 1.0,
      ),
    },
    ShanshuiSeason.fall: {
      ShanshuiTimeOfDay.dawn: (
        skyTop: Color(0xFF362C3B),
        skyBottom: Color(0xFFF2B28D),
        riverMist: Color.fromRGBO(245, 208, 185, 0.52),
        celestialColor: Color(0xFFEB5E36),
        celestialGlow: Color.fromRGBO(235, 94, 54, 0.46),
        candleIntensity: 0.74,
      ),
      ShanshuiTimeOfDay.day: (
        skyTop: Color(0xFFEAD8C3),
        skyBottom: Color(0xFFFBF3E6),
        riverMist: Color.fromRGBO(250, 238, 220, 0.42),
        celestialColor: Color(0xFFD6452B),
        celestialGlow: Color.fromRGBO(255, 210, 150, 0.55),
        candleIntensity: 0.24,
      ),
      ShanshuiTimeOfDay.dusk: (
        skyTop: Color(0xFF5E3E47),
        skyBottom: Color(0xFFF0884D),
        riverMist: Color.fromRGBO(242, 165, 122, 0.48),
        celestialColor: Color(0xFFE04422),
        celestialGlow: Color.fromRGBO(224, 68, 34, 0.52),
        candleIntensity: 0.90,
      ),
      ShanshuiTimeOfDay.night: (
        skyTop: Color(0xFF1A1722),
        skyBottom: Color(0xFF332C3D),
        riverMist: Color.fromRGBO(58, 48, 68, 0.48),
        celestialColor: Color(0xFFFAD678),
        celestialGlow: Color.fromRGBO(250, 214, 120, 0.36),
        candleIntensity: 1.0,
      ),
    },
    ShanshuiSeason.winter: {
      ShanshuiTimeOfDay.dawn: (
        skyTop: Color(0xFF242F3D),
        skyBottom: Color(0xFFE0C3BC),
        riverMist: Color.fromRGBO(230, 234, 240, 0.58),
        celestialColor: Color(0xFFDE5A42),
        celestialGlow: Color.fromRGBO(222, 90, 66, 0.40),
        candleIntensity: 0.85,
      ),
      ShanshuiTimeOfDay.day: (
        skyTop: Color(0xFFD4DEE6),
        skyBottom: Color(0xFFF2F6F9),
        riverMist: Color.fromRGBO(245, 248, 252, 0.55),
        celestialColor: Color(0xFFC94636),
        celestialGlow: Color.fromRGBO(255, 225, 195, 0.45),
        candleIntensity: 0.55,
      ),
      ShanshuiTimeOfDay.dusk: (
        skyTop: Color(0xFF4A5668),
        skyBottom: Color(0xFFDEB09C),
        riverMist: Color.fromRGBO(222, 215, 218, 0.50),
        celestialColor: Color(0xFFD9543B),
        celestialGlow: Color.fromRGBO(217, 84, 59, 0.42),
        candleIntensity: 0.94,
      ),
      ShanshuiTimeOfDay.night: (
        skyTop: Color(0xFF0F1722),
        skyBottom: Color(0xFF223244),
        riverMist: Color.fromRGBO(38, 54, 72, 0.52),
        celestialColor: Color(0xFFF8FAFC),
        celestialGlow: Color.fromRGBO(220, 238, 255, 0.42),
        candleIntensity: 1.0,
      ),
    },
  };
}
