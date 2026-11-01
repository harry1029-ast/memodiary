import 'package:flutter/material.dart';
import 'shanshui_atmosphere.dart';

/// Complete atmospheric and architectural color palette for the Outdoor Ancient
/// Market Street (`市井`) realm across all seasons and times of day.
@immutable
class OutdoorStreetPalette {
  final Color skyTop;
  final Color skyBottom;
  final Color celestialColor;
  final Color celestialGlow;
  final Color ambientOverlay;
  final double candleIntensity;

  // Mountain & Crags
  final Color mtnTop;
  final Color mtnMid;
  final Color mtnBase;
  final Color mtnCrag;

  // Seasonal Foliage Clusters
  final Color foliagePrimary;
  final Color foliageSecondary;
  final Color foliageAccent;

  // Seasonal Particle Attributes
  final String particleType;
  final Color particleColor1;
  final Color particleColor2;

  // Architectural Plaster, Timber & Street Flagstones
  final Color wallPlaster;
  final Color wallPlasterDark;
  final Color woodFrame;
  final Color streetBase;
  final Color streetMid;
  final Color streetDark;

  const OutdoorStreetPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.celestialColor,
    required this.celestialGlow,
    required this.ambientOverlay,
    required this.candleIntensity,
    required this.mtnTop,
    required this.mtnMid,
    required this.mtnBase,
    required this.mtnCrag,
    required this.foliagePrimary,
    required this.foliageSecondary,
    required this.foliageAccent,
    required this.particleType,
    required this.particleColor1,
    required this.particleColor2,
    required this.wallPlaster,
    required this.wallPlasterDark,
    required this.woodFrame,
    required this.streetBase,
    required this.streetMid,
    required this.streetDark,
  });

  /// Resolves the authentic outdoor palette for the given [season] and [timeOfDay].
  static OutdoorStreetPalette of(ShanshuiSeason season, ShanshuiTimeOfDay timeOfDay) {
    switch (season) {
      case ShanshuiSeason.spring:
        return _springPalettes[timeOfDay]!;
      case ShanshuiSeason.summer:
        return _summerPalettes[timeOfDay]!;
      case ShanshuiSeason.fall:
        return _fallPalettes[timeOfDay]!;
      case ShanshuiSeason.winter:
        return _winterPalettes[timeOfDay]!;
    }
  }

  // ---------------------------------------------------------------------------
  // Architecture Constants
  // ---------------------------------------------------------------------------
  static const Color _wallPlasterDay = Color(0xFFDFC6A8);
  static const Color _wallPlasterDarkDay = Color(0xFFC7AC8C);
  static const Color _woodFrameDay = Color(0xFF5C3A24);
  static const Color _streetBaseDay = Color(0xFFF5DEC0);
  static const Color _streetMidDay = Color(0xFFDFC3A0);
  static const Color _streetDarkDay = Color(0xFFB89B7A);

  static const Color _wallPlasterNight = Color(0xFF786B5E);
  static const Color _wallPlasterDarkNight = Color(0xFF5C5146);
  static const Color _woodFrameNight = Color(0xFF2B1B12);
  static const Color _streetBaseNight = Color(0xFF4A4642);
  static const Color _streetMidNight = Color(0xFF383430);
  static const Color _streetDarkNight = Color(0xFF262320);

  // ---------------------------------------------------------------------------
  // Spring Palettes
  // ---------------------------------------------------------------------------
  static const _springPalettes = {
    ShanshuiTimeOfDay.dawn: OutdoorStreetPalette(
      skyTop: Color(0xFF2E3B4E),
      skyBottom: Color(0xFFF0B6A4),
      celestialColor: Color(0xFFF26B4E),
      celestialGlow: Color.fromRGBO(242, 107, 78, 0.45),
      ambientOverlay: Color.fromRGBO(42, 30, 38, 0.34),
      candleIntensity: 0.72,
      mtnTop: Color(0xFF6B8E78),
      mtnMid: Color(0xFF8FB096),
      mtnBase: Color(0xFF52735D),
      mtnCrag: Color(0xFF364F3E),
      foliagePrimary: Color(0xFFE57383),
      foliageSecondary: Color(0xFFF9B8C2),
      foliageAccent: Color(0xFF588163),
      particleType: 'petals',
      particleColor1: Color(0xFFF08090),
      particleColor2: Color(0xFFFADCE2),
      wallPlaster: _wallPlasterDay,
      wallPlasterDark: _wallPlasterDarkDay,
      woodFrame: _woodFrameDay,
      streetBase: _streetBaseDay,
      streetMid: _streetMidDay,
      streetDark: _streetDarkDay,
    ),
    ShanshuiTimeOfDay.day: OutdoorStreetPalette(
      skyTop: Color(0xFFCFE2DF),
      skyBottom: Color(0xFFF5EFE6),
      celestialColor: Color(0xFFE04836),
      celestialGlow: Color.fromRGBO(255, 220, 175, 0.55),
      ambientOverlay: Color.fromRGBO(255, 245, 230, 0.04),
      candleIntensity: 0.20,
      mtnTop: Color(0xFF6B8E78),
      mtnMid: Color(0xFF8FB096),
      mtnBase: Color(0xFF52735D),
      mtnCrag: Color(0xFF364F3E),
      foliagePrimary: Color(0xFFE57383),
      foliageSecondary: Color(0xFFF9B8C2),
      foliageAccent: Color(0xFF588163),
      particleType: 'petals',
      particleColor1: Color(0xFFF08090),
      particleColor2: Color(0xFFFADCE2),
      wallPlaster: _wallPlasterDay,
      wallPlasterDark: _wallPlasterDarkDay,
      woodFrame: _woodFrameDay,
      streetBase: _streetBaseDay,
      streetMid: _streetMidDay,
      streetDark: _streetDarkDay,
    ),
    ShanshuiTimeOfDay.dusk: OutdoorStreetPalette(
      skyTop: Color(0xFF6E5568),
      skyBottom: Color(0xFFF29F6D),
      celestialColor: Color(0xFFE8532C),
      celestialGlow: Color.fromRGBO(232, 83, 44, 0.50),
      ambientOverlay: Color.fromRGBO(55, 26, 20, 0.32),
      candleIntensity: 0.88,
      mtnTop: Color(0xFF6B8E78),
      mtnMid: Color(0xFF8FB096),
      mtnBase: Color(0xFF52735D),
      mtnCrag: Color(0xFF364F3E),
      foliagePrimary: Color(0xFFE57383),
      foliageSecondary: Color(0xFFF9B8C2),
      foliageAccent: Color(0xFF588163),
      particleType: 'petals',
      particleColor1: Color(0xFFF08090),
      particleColor2: Color(0xFFFADCE2),
      wallPlaster: _wallPlasterDay,
      wallPlasterDark: _wallPlasterDarkDay,
      woodFrame: _woodFrameDay,
      streetBase: _streetBaseDay,
      streetMid: _streetMidDay,
      streetDark: _streetDarkDay,
    ),
    ShanshuiTimeOfDay.night: OutdoorStreetPalette(
      skyTop: Color(0xFF111C28),
      skyBottom: Color(0xFF263849),
      celestialColor: Color(0xFFF7F4E0),
      celestialGlow: Color.fromRGBO(210, 230, 255, 0.38),
      ambientOverlay: Color.fromRGBO(10, 16, 26, 0.64),
      candleIntensity: 1.0,
      mtnTop: Color(0xFF6B8E78),
      mtnMid: Color(0xFF8FB096),
      mtnBase: Color(0xFF52735D),
      mtnCrag: Color(0xFF364F3E),
      foliagePrimary: Color(0xFFE57383),
      foliageSecondary: Color(0xFFF9B8C2),
      foliageAccent: Color(0xFF588163),
      particleType: 'petals',
      particleColor1: Color(0xFFF08090),
      particleColor2: Color(0xFFFADCE2),
      wallPlaster: _wallPlasterNight,
      wallPlasterDark: _wallPlasterDarkNight,
      woodFrame: _woodFrameNight,
      streetBase: _streetBaseNight,
      streetMid: _streetMidNight,
      streetDark: _streetDarkNight,
    ),
  };

  // ---------------------------------------------------------------------------
  // Summer Palettes
  // ---------------------------------------------------------------------------
  static const _summerPalettes = {
    ShanshuiTimeOfDay.dawn: OutdoorStreetPalette(
      skyTop: Color(0xFF1F3A42),
      skyBottom: Color(0xFFE6C2A8),
      celestialColor: Color(0xFFF0754F),
      celestialGlow: Color.fromRGBO(240, 117, 79, 0.42),
      ambientOverlay: Color.fromRGBO(28, 42, 40, 0.34),
      candleIntensity: 0.68,
      mtnTop: Color(0xFF3E6B52),
      mtnMid: Color(0xFF689977),
      mtnBase: Color(0xFF2D523D),
      mtnCrag: Color(0xFF1D3828),
      foliagePrimary: Color(0xFF2E6E49),
      foliageSecondary: Color(0xFF5CA377),
      foliageAccent: Color(0xFFE8839B),
      particleType: 'fireflies',
      particleColor1: Color(0xFFB5F56C),
      particleColor2: Color(0xFFFFE57F),
      wallPlaster: _wallPlasterDay,
      wallPlasterDark: _wallPlasterDarkDay,
      woodFrame: _woodFrameDay,
      streetBase: _streetBaseDay,
      streetMid: _streetMidDay,
      streetDark: _streetDarkDay,
    ),
    ShanshuiTimeOfDay.day: OutdoorStreetPalette(
      skyTop: Color(0xFFB5DCD1),
      skyBottom: Color(0xFFEBF5F0),
      celestialColor: Color(0xFFE64E35),
      celestialGlow: Color.fromRGBO(255, 235, 185, 0.55),
      ambientOverlay: Color.fromRGBO(220, 245, 235, 0.04),
      candleIntensity: 0.18,
      mtnTop: Color(0xFF3E6B52),
      mtnMid: Color(0xFF689977),
      mtnBase: Color(0xFF2D523D),
      mtnCrag: Color(0xFF1D3828),
      foliagePrimary: Color(0xFF2E6E49),
      foliageSecondary: Color(0xFF5CA377),
      foliageAccent: Color(0xFFE8839B),
      particleType: 'fireflies',
      particleColor1: Color(0xFFB5F56C),
      particleColor2: Color(0xFFFFE57F),
      wallPlaster: _wallPlasterDay,
      wallPlasterDark: _wallPlasterDarkDay,
      woodFrame: _woodFrameDay,
      streetBase: _streetBaseDay,
      streetMid: _streetMidDay,
      streetDark: _streetDarkDay,
    ),
    ShanshuiTimeOfDay.dusk: OutdoorStreetPalette(
      skyTop: Color(0xFF4A5D66),
      skyBottom: Color(0xFFEDA56C),
      celestialColor: Color(0xFFEB6034),
      celestialGlow: Color.fromRGBO(235, 96, 52, 0.48),
      ambientOverlay: Color.fromRGBO(42, 30, 22, 0.34),
      candleIntensity: 0.86,
      mtnTop: Color(0xFF3E6B52),
      mtnMid: Color(0xFF689977),
      mtnBase: Color(0xFF2D523D),
      mtnCrag: Color(0xFF1D3828),
      foliagePrimary: Color(0xFF2E6E49),
      foliageSecondary: Color(0xFF5CA377),
      foliageAccent: Color(0xFFE8839B),
      particleType: 'fireflies',
      particleColor1: Color(0xFFB5F56C),
      particleColor2: Color(0xFFFFE57F),
      wallPlaster: _wallPlasterDay,
      wallPlasterDark: _wallPlasterDarkDay,
      woodFrame: _woodFrameDay,
      streetBase: _streetBaseDay,
      streetMid: _streetMidDay,
      streetDark: _streetDarkDay,
    ),
    ShanshuiTimeOfDay.night: OutdoorStreetPalette(
      skyTop: Color(0xFF0D1F24),
      skyBottom: Color(0xFF1E3A40),
      celestialColor: Color(0xFFF7F6E4),
      celestialGlow: Color.fromRGBO(195, 235, 230, 0.38),
      ambientOverlay: Color.fromRGBO(8, 20, 24, 0.65),
      candleIntensity: 1.0,
      mtnTop: Color(0xFF3E6B52),
      mtnMid: Color(0xFF689977),
      mtnBase: Color(0xFF2D523D),
      mtnCrag: Color(0xFF1D3828),
      foliagePrimary: Color(0xFF2E6E49),
      foliageSecondary: Color(0xFF5CA377),
      foliageAccent: Color(0xFFE8839B),
      particleType: 'fireflies',
      particleColor1: Color(0xFFB5F56C),
      particleColor2: Color(0xFFFFE57F),
      wallPlaster: _wallPlasterNight,
      wallPlasterDark: _wallPlasterDarkNight,
      woodFrame: _woodFrameNight,
      streetBase: _streetBaseNight,
      streetMid: _streetMidNight,
      streetDark: _streetDarkNight,
    ),
  };

  // ---------------------------------------------------------------------------
  // Fall Palettes
  // ---------------------------------------------------------------------------
  static const _fallPalettes = {
    ShanshuiTimeOfDay.dawn: OutdoorStreetPalette(
      skyTop: Color(0xFF362C3B),
      skyBottom: Color(0xFFF2B28D),
      celestialColor: Color(0xFFEB5E36),
      celestialGlow: Color.fromRGBO(235, 94, 54, 0.46),
      ambientOverlay: Color.fromRGBO(48, 30, 26, 0.34),
      candleIntensity: 0.74,
      mtnTop: Color(0xFF9E6B43),
      mtnMid: Color(0xFFC79663),
      mtnBase: Color(0xFF784E30),
      mtnCrag: Color(0xFF4A2E1B),
      foliagePrimary: Color(0xFFC8462C),
      foliageSecondary: Color(0xFFE88B38),
      foliageAccent: Color(0xFF8F2918),
      particleType: 'leaves',
      particleColor1: Color(0xFFD14B30),
      particleColor2: Color(0xFFEB963E),
      wallPlaster: _wallPlasterDay,
      wallPlasterDark: _wallPlasterDarkDay,
      woodFrame: _woodFrameDay,
      streetBase: _streetBaseDay,
      streetMid: _streetMidDay,
      streetDark: _streetDarkDay,
    ),
    ShanshuiTimeOfDay.day: OutdoorStreetPalette(
      skyTop: Color(0xFFEAD8C3),
      skyBottom: Color(0xFFFBF3E6),
      celestialColor: Color(0xFFD6452B),
      celestialGlow: Color.fromRGBO(255, 210, 150, 0.55),
      ambientOverlay: Color.fromRGBO(255, 235, 205, 0.05),
      candleIntensity: 0.24,
      mtnTop: Color(0xFF9E6B43),
      mtnMid: Color(0xFFC79663),
      mtnBase: Color(0xFF784E30),
      mtnCrag: Color(0xFF4A2E1B),
      foliagePrimary: Color(0xFFC8462C),
      foliageSecondary: Color(0xFFE88B38),
      foliageAccent: Color(0xFF8F2918),
      particleType: 'leaves',
      particleColor1: Color(0xFFD14B30),
      particleColor2: Color(0xFFEB963E),
      wallPlaster: _wallPlasterDay,
      wallPlasterDark: _wallPlasterDarkDay,
      woodFrame: _woodFrameDay,
      streetBase: _streetBaseDay,
      streetMid: _streetMidDay,
      streetDark: _streetDarkDay,
    ),
    ShanshuiTimeOfDay.dusk: OutdoorStreetPalette(
      skyTop: Color(0xFF5E3E47),
      skyBottom: Color(0xFFF0884D),
      celestialColor: Color(0xFFE04422),
      celestialGlow: Color.fromRGBO(224, 68, 34, 0.52),
      ambientOverlay: Color.fromRGBO(62, 26, 16, 0.35),
      candleIntensity: 0.90,
      mtnTop: Color(0xFF9E6B43),
      mtnMid: Color(0xFFC79663),
      mtnBase: Color(0xFF784E30),
      mtnCrag: Color(0xFF4A2E1B),
      foliagePrimary: Color(0xFFC8462C),
      foliageSecondary: Color(0xFFE88B38),
      foliageAccent: Color(0xFF8F2918),
      particleType: 'leaves',
      particleColor1: Color(0xFFD14B30),
      particleColor2: Color(0xFFEB963E),
      wallPlaster: _wallPlasterDay,
      wallPlasterDark: _wallPlasterDarkDay,
      woodFrame: _woodFrameDay,
      streetBase: _streetBaseDay,
      streetMid: _streetMidDay,
      streetDark: _streetDarkDay,
    ),
    ShanshuiTimeOfDay.night: OutdoorStreetPalette(
      skyTop: Color(0xFF1A1722),
      skyBottom: Color(0xFF332C3D),
      celestialColor: Color(0xFFFAD678),
      celestialGlow: Color.fromRGBO(250, 214, 120, 0.36),
      ambientOverlay: Color.fromRGBO(16, 12, 22, 0.64),
      candleIntensity: 1.0,
      mtnTop: Color(0xFF9E6B43),
      mtnMid: Color(0xFFC79663),
      mtnBase: Color(0xFF784E30),
      mtnCrag: Color(0xFF4A2E1B),
      foliagePrimary: Color(0xFFC8462C),
      foliageSecondary: Color(0xFFE88B38),
      foliageAccent: Color(0xFF8F2918),
      particleType: 'leaves',
      particleColor1: Color(0xFFD14B30),
      particleColor2: Color(0xFFEB963E),
      wallPlaster: _wallPlasterNight,
      wallPlasterDark: _wallPlasterDarkNight,
      woodFrame: _woodFrameNight,
      streetBase: _streetBaseNight,
      streetMid: _streetMidNight,
      streetDark: _streetDarkNight,
    ),
  };

  // ---------------------------------------------------------------------------
  // Winter Palettes
  // ---------------------------------------------------------------------------
  static const _winterPalettes = {
    ShanshuiTimeOfDay.dawn: OutdoorStreetPalette(
      skyTop: Color(0xFF242F3D),
      skyBottom: Color(0xFFE0C3BC),
      celestialColor: Color(0xFFDE5A42),
      celestialGlow: Color.fromRGBO(222, 90, 66, 0.40),
      ambientOverlay: Color.fromRGBO(28, 36, 48, 0.35),
      candleIntensity: 0.85,
      mtnTop: Color(0xFFF8FAFC),
      mtnMid: Color(0xFFCBD5E1),
      mtnBase: Color(0xFF64748B),
      mtnCrag: Color(0xFF334155),
      foliagePrimary: Color(0xFFF8FAFC),
      foliageSecondary: Color(0xFFD93848),
      foliageAccent: Color(0xFFCBD5E1),
      particleType: 'snow',
      particleColor1: Color(0xFFFFFFFF),
      particleColor2: Color(0xFFE2E8F0),
      wallPlaster: _wallPlasterDay,
      wallPlasterDark: _wallPlasterDarkDay,
      woodFrame: _woodFrameDay,
      streetBase: _streetBaseDay,
      streetMid: _streetMidDay,
      streetDark: _streetDarkDay,
    ),
    ShanshuiTimeOfDay.day: OutdoorStreetPalette(
      skyTop: Color(0xFFD4DEE6),
      skyBottom: Color(0xFFF2F6F9),
      celestialColor: Color(0xFFC94636),
      celestialGlow: Color.fromRGBO(255, 225, 195, 0.45),
      ambientOverlay: Color.fromRGBO(225, 235, 245, 0.06),
      candleIntensity: 0.55,
      mtnTop: Color(0xFFF8FAFC),
      mtnMid: Color(0xFFCBD5E1),
      mtnBase: Color(0xFF64748B),
      mtnCrag: Color(0xFF334155),
      foliagePrimary: Color(0xFFF8FAFC),
      foliageSecondary: Color(0xFFD93848),
      foliageAccent: Color(0xFFCBD5E1),
      particleType: 'snow',
      particleColor1: Color(0xFFFFFFFF),
      particleColor2: Color(0xFFE2E8F0),
      wallPlaster: _wallPlasterDay,
      wallPlasterDark: _wallPlasterDarkDay,
      woodFrame: _woodFrameDay,
      streetBase: _streetBaseDay,
      streetMid: _streetMidDay,
      streetDark: _streetDarkDay,
    ),
    ShanshuiTimeOfDay.dusk: OutdoorStreetPalette(
      skyTop: Color(0xFF4A5668),
      skyBottom: Color(0xFFDEB09C),
      celestialColor: Color(0xFFD9543B),
      celestialGlow: Color.fromRGBO(217, 84, 59, 0.42),
      ambientOverlay: Color.fromRGBO(35, 32, 42, 0.38),
      candleIntensity: 0.94,
      mtnTop: Color(0xFFF8FAFC),
      mtnMid: Color(0xFFCBD5E1),
      mtnBase: Color(0xFF64748B),
      mtnCrag: Color(0xFF334155),
      foliagePrimary: Color(0xFFF8FAFC),
      foliageSecondary: Color(0xFFD93848),
      foliageAccent: Color(0xFFCBD5E1),
      particleType: 'snow',
      particleColor1: Color(0xFFFFFFFF),
      particleColor2: Color(0xFFE2E8F0),
      wallPlaster: _wallPlasterDay,
      wallPlasterDark: _wallPlasterDarkDay,
      woodFrame: _woodFrameDay,
      streetBase: _streetBaseDay,
      streetMid: _streetMidDay,
      streetDark: _streetDarkDay,
    ),
    ShanshuiTimeOfDay.night: OutdoorStreetPalette(
      skyTop: Color(0xFF0F1722),
      skyBottom: Color(0xFF223244),
      celestialColor: Color(0xFFF8FAFC),
      celestialGlow: Color.fromRGBO(220, 238, 255, 0.42),
      ambientOverlay: Color.fromRGBO(8, 14, 24, 0.68),
      candleIntensity: 1.0,
      mtnTop: Color(0xFFF8FAFC),
      mtnMid: Color(0xFFCBD5E1),
      mtnBase: Color(0xFF64748B),
      mtnCrag: Color(0xFF334155),
      foliagePrimary: Color(0xFFF8FAFC),
      foliageSecondary: Color(0xFFD93848),
      foliageAccent: Color(0xFFCBD5E1),
      particleType: 'snow',
      particleColor1: Color(0xFFFFFFFF),
      particleColor2: Color(0xFFE2E8F0),
      wallPlaster: _wallPlasterNight,
      wallPlasterDark: _wallPlasterDarkNight,
      woodFrame: _woodFrameNight,
      streetBase: _streetBaseNight,
      streetMid: _streetMidNight,
      streetDark: _streetDarkNight,
    ),
  };
}
