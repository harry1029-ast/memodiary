import 'package:flutter/material.dart';
import 'shanshui_atmosphere.dart';

/// Complete atmospheric color palette for the Indoor Scholar Tea Hall (`雅室`) realm.
/// Faithfully ported from the React/Canvas prototype.
@immutable
class AncientRoomPalette {
  final Color skyTop;
  final Color skyBottom;
  final Color courtyardMist;
  final Color celestialColor;
  final Color celestialGlow;
  final Color shojiTop;
  final Color shojiBottom;
  final Color wallLeft;
  final Color wallRight;
  final Color woodDark;
  final Color woodMid;
  final Color woodHighlight;
  final Color floorBase;
  final Color floorHighlight;
  final Color ambientOverlay;
  final Color lightBeamColor;
  final Color floorPatchColor;
  final double candleIntensity;
  final Color foliagePrimary;
  final Color foliageSecondary;
  final Color foliageAccent;
  final Color indoorPotFlower;
  final Color indoorPotLeaf;
  final Color particleColor1;
  final Color particleColor2;

  const AncientRoomPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.courtyardMist,
    required this.celestialColor,
    required this.celestialGlow,
    required this.shojiTop,
    required this.shojiBottom,
    required this.wallLeft,
    required this.wallRight,
    required this.woodDark,
    required this.woodMid,
    required this.woodHighlight,
    required this.floorBase,
    required this.floorHighlight,
    required this.ambientOverlay,
    required this.lightBeamColor,
    required this.floorPatchColor,
    required this.candleIntensity,
    required this.foliagePrimary,
    required this.foliageSecondary,
    required this.foliageAccent,
    required this.indoorPotFlower,
    required this.indoorPotLeaf,
    required this.particleColor1,
    required this.particleColor2,
  });

  /// Resolves the authentic indoor palette for the specified [season] and [timeOfDay].
  static AncientRoomPalette of(ShanshuiSeason season, ShanshuiTimeOfDay timeOfDay) {
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

  // ==========================================================================
  // SPRING PALETTES (春 · 桃夭茶寮)
  // ==========================================================================
  static const Color _springFoliagePrimary = Color(0xFFE57383);
  static const Color _springFoliageSecondary = Color(0xFFF9B8C2);
  static const Color _springFoliageAccent = Color(0xFF588163);
  static const Color _springIndoorPotFlower = Color(0xFFF48FB1);
  static const Color _springIndoorPotLeaf = Color(0xFF4C7858);
  static const Color _springParticleColor1 = Color(0xFFF08090);
  static const Color _springParticleColor2 = Color(0xFFFADCE2);

  static const Map<ShanshuiTimeOfDay, AncientRoomPalette> _springPalettes = {
    ShanshuiTimeOfDay.dawn: AncientRoomPalette(
      skyTop: Color(0xFF2E3B4E),
      skyBottom: Color(0xFFF0B6A4),
      courtyardMist: Color.fromRGBO(245, 210, 200, 0.55),
      celestialColor: Color(0xFFF26B4E),
      celestialGlow: Color.fromRGBO(242, 107, 78, 0.45),
      shojiTop: Color(0xFFD9A796),
      shojiBottom: Color(0xFF8C6D68),
      wallLeft: Color(0xFFC9B199),
      wallRight: Color(0xFF9E8570),
      woodDark: Color(0xFF261710),
      woodMid: Color(0xFF42281B),
      woodHighlight: Color(0xFF6E4530),
      floorBase: Color(0xFF6B3E23),
      floorHighlight: Color(0xFF9E5F38),
      ambientOverlay: Color.fromRGBO(42, 30, 38, 0.34),
      lightBeamColor: Color.fromRGBO(255, 175, 135, 0.26),
      floorPatchColor: Color.fromRGBO(255, 188, 148, 0.30),
      candleIntensity: 0.72,
      foliagePrimary: _springFoliagePrimary,
      foliageSecondary: _springFoliageSecondary,
      foliageAccent: _springFoliageAccent,
      indoorPotFlower: _springIndoorPotFlower,
      indoorPotLeaf: _springIndoorPotLeaf,
      particleColor1: _springParticleColor1,
      particleColor2: _springParticleColor2,
    ),
    ShanshuiTimeOfDay.day: AncientRoomPalette(
      skyTop: Color(0xFFCFE2DF),
      skyBottom: Color(0xFFF5EFE6),
      courtyardMist: Color.fromRGBO(255, 250, 244, 0.45),
      celestialColor: Color(0xFFE04836),
      celestialGlow: Color.fromRGBO(255, 220, 175, 0.55),
      shojiTop: Color(0xFFFFFDF9),
      shojiBottom: Color(0xFFEADBC8),
      wallLeft: Color(0xFFF2E5D2),
      wallRight: Color(0xFFC7B299),
      woodDark: Color(0xFF2D1A11),
      woodMid: Color(0xFF4F2E1E),
      woodHighlight: Color(0xFF7D4C33),
      floorBase: Color(0xFF854B27),
      floorHighlight: Color(0xFFC47B46),
      ambientOverlay: Color.fromRGBO(255, 245, 230, 0.04),
      lightBeamColor: Color.fromRGBO(255, 246, 224, 0.34),
      floorPatchColor: Color.fromRGBO(255, 238, 200, 0.42),
      candleIntensity: 0.20,
      foliagePrimary: _springFoliagePrimary,
      foliageSecondary: _springFoliageSecondary,
      foliageAccent: _springFoliageAccent,
      indoorPotFlower: _springIndoorPotFlower,
      indoorPotLeaf: _springIndoorPotLeaf,
      particleColor1: _springParticleColor1,
      particleColor2: _springParticleColor2,
    ),
    ShanshuiTimeOfDay.dusk: AncientRoomPalette(
      skyTop: Color(0xFF6E5568),
      skyBottom: Color(0xFFF29F6D),
      courtyardMist: Color.fromRGBO(242, 175, 140, 0.48),
      celestialColor: Color(0xFFE8532C),
      celestialGlow: Color.fromRGBO(232, 83, 44, 0.50),
      shojiTop: Color(0xFFF0B68C),
      shojiBottom: Color(0xFF9E6B52),
      wallLeft: Color(0xFFD6AF8E),
      wallRight: Color(0xFF9E7B60),
      woodDark: Color(0xFF24140D),
      woodMid: Color(0xFF402316),
      woodHighlight: Color(0xFF6E3E26),
      floorBase: Color(0xFF6B381B),
      floorHighlight: Color(0xFFA85C30),
      ambientOverlay: Color.fromRGBO(55, 26, 20, 0.32),
      lightBeamColor: Color.fromRGBO(255, 156, 95, 0.32),
      floorPatchColor: Color.fromRGBO(255, 165, 102, 0.36),
      candleIntensity: 0.88,
      foliagePrimary: _springFoliagePrimary,
      foliageSecondary: _springFoliageSecondary,
      foliageAccent: _springFoliageAccent,
      indoorPotFlower: _springIndoorPotFlower,
      indoorPotLeaf: _springIndoorPotLeaf,
      particleColor1: _springParticleColor1,
      particleColor2: _springParticleColor2,
    ),
    ShanshuiTimeOfDay.night: AncientRoomPalette(
      skyTop: Color(0xFF111C28),
      skyBottom: Color(0xFF263849),
      courtyardMist: Color.fromRGBO(42, 62, 82, 0.50),
      celestialColor: Color(0xFFF7F4E0),
      celestialGlow: Color.fromRGBO(210, 230, 255, 0.38),
      shojiTop: Color(0xFF334659),
      shojiBottom: Color(0xFF1F2C38),
      wallLeft: Color(0xFF574C44),
      wallRight: Color(0xFF3D342E),
      woodDark: Color(0xFF140B07),
      woodMid: Color(0xFF26160E),
      woodHighlight: Color(0xFF452819),
      floorBase: Color(0xFF382012),
      floorHighlight: Color(0xFF5E3820),
      ambientOverlay: Color.fromRGBO(10, 16, 26, 0.64),
      lightBeamColor: Color.fromRGBO(185, 215, 250, 0.16),
      floorPatchColor: Color.fromRGBO(185, 215, 250, 0.18),
      candleIntensity: 1.0,
      foliagePrimary: _springFoliagePrimary,
      foliageSecondary: _springFoliageSecondary,
      foliageAccent: _springFoliageAccent,
      indoorPotFlower: _springIndoorPotFlower,
      indoorPotLeaf: _springIndoorPotLeaf,
      particleColor1: _springParticleColor1,
      particleColor2: _springParticleColor2,
    ),
  };

  // ==========================================================================
  // SUMMER PALETTES (夏 · 翠竹听荷)
  // ==========================================================================
  static const Color _summerFoliagePrimary = Color(0xFF2E6E49);
  static const Color _summerFoliageSecondary = Color(0xFF5CA377);
  static const Color _summerFoliageAccent = Color(0xFFE8839B);
  static const Color _summerIndoorPotFlower = Color(0xFFF7D070);
  static const Color _summerIndoorPotLeaf = Color(0xFF2D6644);
  static const Color _summerParticleColor1 = Color(0xFFB5F56C);
  static const Color _summerParticleColor2 = Color(0xFFFFE57F);

  static const Map<ShanshuiTimeOfDay, AncientRoomPalette> _summerPalettes = {
    ShanshuiTimeOfDay.dawn: AncientRoomPalette(
      skyTop: Color(0xFF1F3A42),
      skyBottom: Color(0xFFE6C2A8),
      courtyardMist: Color.fromRGBO(210, 232, 224, 0.52),
      celestialColor: Color(0xFFF0754F),
      celestialGlow: Color.fromRGBO(240, 117, 79, 0.42),
      shojiTop: Color(0xFFC9B8A6),
      shojiBottom: Color(0xFF78756E),
      wallLeft: Color(0xFFC4B6A2),
      wallRight: Color(0xFF968876),
      woodDark: Color(0xFF231610),
      woodMid: Color(0xFF3E271B),
      woodHighlight: Color(0xFF66412D),
      floorBase: Color(0xFF633B22),
      floorHighlight: Color(0xFF945935),
      ambientOverlay: Color.fromRGBO(28, 42, 40, 0.34),
      lightBeamColor: Color.fromRGBO(255, 195, 145, 0.25),
      floorPatchColor: Color.fromRGBO(255, 200, 155, 0.28),
      candleIntensity: 0.68,
      foliagePrimary: _summerFoliagePrimary,
      foliageSecondary: _summerFoliageSecondary,
      foliageAccent: _summerFoliageAccent,
      indoorPotFlower: _summerIndoorPotFlower,
      indoorPotLeaf: _summerIndoorPotLeaf,
      particleColor1: _summerParticleColor1,
      particleColor2: _summerParticleColor2,
    ),
    ShanshuiTimeOfDay.day: AncientRoomPalette(
      skyTop: Color(0xFFB5DCD1),
      skyBottom: Color(0xFFEBF5F0),
      courtyardMist: Color.fromRGBO(235, 248, 242, 0.42),
      celestialColor: Color(0xFFE64E35),
      celestialGlow: Color.fromRGBO(255, 235, 185, 0.55),
      shojiTop: Color(0xFFF8FFFC),
      shojiBottom: Color(0xFFDCE8E0),
      wallLeft: Color(0xFFEFE6D5),
      wallRight: Color(0xFFC2B39E),
      woodDark: Color(0xFF2B1910),
      woodMid: Color(0xFF4D2D1D),
      woodHighlight: Color(0xFF7A4A32),
      floorBase: Color(0xFF804825),
      floorHighlight: Color(0xFFBD7542),
      ambientOverlay: Color.fromRGBO(220, 245, 235, 0.04),
      lightBeamColor: Color.fromRGBO(250, 252, 228, 0.35),
      floorPatchColor: Color.fromRGBO(248, 245, 210, 0.40),
      candleIntensity: 0.18,
      foliagePrimary: _summerFoliagePrimary,
      foliageSecondary: _summerFoliageSecondary,
      foliageAccent: _summerFoliageAccent,
      indoorPotFlower: _summerIndoorPotFlower,
      indoorPotLeaf: _summerIndoorPotLeaf,
      particleColor1: _summerParticleColor1,
      particleColor2: _summerParticleColor2,
    ),
    ShanshuiTimeOfDay.dusk: AncientRoomPalette(
      skyTop: Color(0xFF4A5D66),
      skyBottom: Color(0xFFEDA56C),
      courtyardMist: Color.fromRGBO(235, 185, 145, 0.45),
      celestialColor: Color(0xFFEB6034),
      celestialGlow: Color.fromRGBO(235, 96, 52, 0.48),
      shojiTop: Color(0xFFE8B589),
      shojiBottom: Color(0xFF8C6B56),
      wallLeft: Color(0xFFD1AE8E),
      wallRight: Color(0xFF967A62),
      woodDark: Color(0xFF21130C),
      woodMid: Color(0xFF3D2216),
      woodHighlight: Color(0xFF663B25),
      floorBase: Color(0xFF66361A),
      floorHighlight: Color(0xFF9E572D),
      ambientOverlay: Color.fromRGBO(42, 30, 22, 0.34),
      lightBeamColor: Color.fromRGBO(255, 170, 102, 0.30),
      floorPatchColor: Color.fromRGBO(255, 178, 110, 0.35),
      candleIntensity: 0.86,
      foliagePrimary: _summerFoliagePrimary,
      foliageSecondary: _summerFoliageSecondary,
      foliageAccent: _summerFoliageAccent,
      indoorPotFlower: _summerIndoorPotFlower,
      indoorPotLeaf: _summerIndoorPotLeaf,
      particleColor1: _summerParticleColor1,
      particleColor2: _summerParticleColor2,
    ),
    ShanshuiTimeOfDay.night: AncientRoomPalette(
      skyTop: Color(0xFF0D1F24),
      skyBottom: Color(0xFF1E3A40),
      courtyardMist: Color.fromRGBO(32, 65, 70, 0.50),
      celestialColor: Color(0xFFF7F6E4),
      celestialGlow: Color.fromRGBO(195, 235, 230, 0.38),
      shojiTop: Color(0xFF2A474D),
      shojiBottom: Color(0xFF192B2E),
      wallLeft: Color(0xFF4F4942),
      wallRight: Color(0xFF38332D),
      woodDark: Color(0xFF120A06),
      woodMid: Color(0xFF24150E),
      woodHighlight: Color(0xFF402618),
      floorBase: Color(0xFF331E11),
      floorHighlight: Color(0xFF57341E),
      ambientOverlay: Color.fromRGBO(8, 20, 24, 0.65),
      lightBeamColor: Color.fromRGBO(175, 225, 235, 0.16),
      floorPatchColor: Color.fromRGBO(175, 225, 235, 0.18),
      candleIntensity: 1.0,
      foliagePrimary: _summerFoliagePrimary,
      foliageSecondary: _summerFoliageSecondary,
      foliageAccent: _summerFoliageAccent,
      indoorPotFlower: _summerIndoorPotFlower,
      indoorPotLeaf: _summerIndoorPotLeaf,
      particleColor1: _summerParticleColor1,
      particleColor2: _summerParticleColor2,
    ),
  };

  // ==========================================================================
  // FALL PALETTES (秋 · 霜枫品茗)
  // ==========================================================================
  static const Color _fallFoliagePrimary = Color(0xFFC8462C);
  static const Color _fallFoliageSecondary = Color(0xFFE88B38);
  static const Color _fallFoliageAccent = Color(0xFF8F2918);
  static const Color _fallIndoorPotFlower = Color(0xFFE89B3C);
  static const Color _fallIndoorPotLeaf = Color(0xFFA84228);
  static const Color _fallParticleColor1 = Color(0xFFD14B30);
  static const Color _fallParticleColor2 = Color(0xFFEB963E);

  static const Map<ShanshuiTimeOfDay, AncientRoomPalette> _fallPalettes = {
    ShanshuiTimeOfDay.dawn: AncientRoomPalette(
      skyTop: Color(0xFF362C3B),
      skyBottom: Color(0xFFF2B28D),
      courtyardMist: Color.fromRGBO(245, 208, 185, 0.52),
      celestialColor: Color(0xFFEB5E36),
      celestialGlow: Color.fromRGBO(235, 94, 54, 0.46),
      shojiTop: Color(0xFFE0AC8B),
      shojiBottom: Color(0xFF8F6A58),
      wallLeft: Color(0xFFCFB297),
      wallRight: Color(0xFFA1856C),
      woodDark: Color(0xFF26160E),
      woodMid: Color(0xFF45281A),
      woodHighlight: Color(0xFF73442C),
      floorBase: Color(0xFF6E3E21),
      floorHighlight: Color(0xFFA35F36),
      ambientOverlay: Color.fromRGBO(48, 30, 26, 0.34),
      lightBeamColor: Color.fromRGBO(255, 175, 120, 0.28),
      floorPatchColor: Color.fromRGBO(255, 182, 128, 0.32),
      candleIntensity: 0.74,
      foliagePrimary: _fallFoliagePrimary,
      foliageSecondary: _fallFoliageSecondary,
      foliageAccent: _fallFoliageAccent,
      indoorPotFlower: _fallIndoorPotFlower,
      indoorPotLeaf: _fallIndoorPotLeaf,
      particleColor1: _fallParticleColor1,
      particleColor2: _fallParticleColor2,
    ),
    ShanshuiTimeOfDay.day: AncientRoomPalette(
      skyTop: Color(0xFFEAD8C3),
      skyBottom: Color(0xFFFBF3E6),
      courtyardMist: Color.fromRGBO(250, 238, 220, 0.42),
      celestialColor: Color(0xFFD6452B),
      celestialGlow: Color.fromRGBO(255, 210, 150, 0.55),
      shojiTop: Color(0xFFFFF9F0),
      shojiBottom: Color(0xFFEDD7BE),
      wallLeft: Color(0xFFF5E4CE),
      wallRight: Color(0xFFCCB296),
      woodDark: Color(0xFF2E1A10),
      woodMid: Color(0xFF54301E),
      woodHighlight: Color(0xFF854E32),
      floorBase: Color(0xFF8C4E27),
      floorHighlight: Color(0xFFCC7E45),
      ambientOverlay: Color.fromRGBO(255, 235, 205, 0.05),
      lightBeamColor: Color.fromRGBO(255, 232, 188, 0.38),
      floorPatchColor: Color.fromRGBO(255, 224, 172, 0.45),
      candleIntensity: 0.24,
      foliagePrimary: _fallFoliagePrimary,
      foliageSecondary: _fallFoliageSecondary,
      foliageAccent: _fallFoliageAccent,
      indoorPotFlower: _fallIndoorPotFlower,
      indoorPotLeaf: _fallIndoorPotLeaf,
      particleColor1: _fallParticleColor1,
      particleColor2: _fallParticleColor2,
    ),
    ShanshuiTimeOfDay.dusk: AncientRoomPalette(
      skyTop: Color(0xFF5E3E47),
      skyBottom: Color(0xFFF0884D),
      courtyardMist: Color.fromRGBO(242, 165, 122, 0.48),
      celestialColor: Color(0xFFE04422),
      celestialGlow: Color.fromRGBO(224, 68, 34, 0.52),
      shojiTop: Color(0xFFF0A475),
      shojiBottom: Color(0xFF995E42),
      wallLeft: Color(0xFFD9A782),
      wallRight: Color(0xFF9E7456),
      woodDark: Color(0xFF24130B),
      woodMid: Color(0xFF422315),
      woodHighlight: Color(0xFF703D24),
      floorBase: Color(0xFF6E3819),
      floorHighlight: Color(0xFFAD5A2B),
      ambientOverlay: Color.fromRGBO(62, 26, 16, 0.35),
      lightBeamColor: Color.fromRGBO(255, 145, 80, 0.35),
      floorPatchColor: Color.fromRGBO(255, 155, 88, 0.40),
      candleIntensity: 0.90,
      foliagePrimary: _fallFoliagePrimary,
      foliageSecondary: _fallFoliageSecondary,
      foliageAccent: _fallFoliageAccent,
      indoorPotFlower: _fallIndoorPotFlower,
      indoorPotLeaf: _fallIndoorPotLeaf,
      particleColor1: _fallParticleColor1,
      particleColor2: _fallParticleColor2,
    ),
    ShanshuiTimeOfDay.night: AncientRoomPalette(
      skyTop: Color(0xFF1A1722),
      skyBottom: Color(0xFF332C3D),
      courtyardMist: Color.fromRGBO(58, 48, 68, 0.48),
      celestialColor: Color(0xFFFAD678),
      celestialGlow: Color.fromRGBO(250, 214, 120, 0.36),
      shojiTop: Color(0xFF453B4F),
      shojiBottom: Color(0xFF292330),
      wallLeft: Color(0xFF594B42),
      wallRight: Color(0xFF40352E),
      woodDark: Color(0xFF140B07),
      woodMid: Color(0xFF29170E),
      woodHighlight: Color(0xFF472919),
      floorBase: Color(0xFF3B2112),
      floorHighlight: Color(0xFF63391F),
      ambientOverlay: Color.fromRGBO(16, 12, 22, 0.64),
      lightBeamColor: Color.fromRGBO(245, 215, 155, 0.16),
      floorPatchColor: Color.fromRGBO(245, 215, 155, 0.18),
      candleIntensity: 1.0,
      foliagePrimary: _fallFoliagePrimary,
      foliageSecondary: _fallFoliageSecondary,
      foliageAccent: _fallFoliageAccent,
      indoorPotFlower: _fallIndoorPotFlower,
      indoorPotLeaf: _fallIndoorPotLeaf,
      particleColor1: _fallParticleColor1,
      particleColor2: _fallParticleColor2,
    ),
  };

  // ==========================================================================
  // WINTER PALETTES (冬 · 瑞雪温炉)
  // ==========================================================================
  static const Color _winterFoliagePrimary = Color(0xFFF8FAFC);
  static const Color _winterFoliageSecondary = Color(0xFFD93848);
  static const Color _winterFoliageAccent = Color(0xFFCBD5E1);
  static const Color _winterIndoorPotFlower = Color(0xFFDE3B4B);
  static const Color _winterIndoorPotLeaf = Color(0xFF3B3530);
  static const Color _winterParticleColor1 = Color(0xFFFFFFFF);
  static const Color _winterParticleColor2 = Color(0xFFE2E8F0);

  static const Map<ShanshuiTimeOfDay, AncientRoomPalette> _winterPalettes = {
    ShanshuiTimeOfDay.dawn: AncientRoomPalette(
      skyTop: Color(0xFF242F3D),
      skyBottom: Color(0xFFE0C3BC),
      courtyardMist: Color.fromRGBO(230, 234, 240, 0.58),
      celestialColor: Color(0xFFDE5A42),
      celestialGlow: Color.fromRGBO(222, 90, 66, 0.40),
      shojiTop: Color(0xFFCED6DE),
      shojiBottom: Color(0xFF858E96),
      wallLeft: Color(0xFFC4B9AD),
      wallRight: Color(0xFF968B80),
      woodDark: Color(0xFF21150F),
      woodMid: Color(0xFF3D271C),
      woodHighlight: Color(0xFF63402E),
      floorBase: Color(0xFF613A22),
      floorHighlight: Color(0xFF915734),
      ambientOverlay: Color.fromRGBO(28, 36, 48, 0.35),
      lightBeamColor: Color.fromRGBO(255, 195, 175, 0.24),
      floorPatchColor: Color.fromRGBO(255, 200, 180, 0.26),
      candleIntensity: 0.85,
      foliagePrimary: _winterFoliagePrimary,
      foliageSecondary: _winterFoliageSecondary,
      foliageAccent: _winterFoliageAccent,
      indoorPotFlower: _winterIndoorPotFlower,
      indoorPotLeaf: _winterIndoorPotLeaf,
      particleColor1: _winterParticleColor1,
      particleColor2: _winterParticleColor2,
    ),
    ShanshuiTimeOfDay.day: AncientRoomPalette(
      skyTop: Color(0xFFD4DEE6),
      skyBottom: Color(0xFFF2F6F9),
      courtyardMist: Color.fromRGBO(245, 248, 252, 0.55),
      celestialColor: Color(0xFFC94636),
      celestialGlow: Color.fromRGBO(255, 225, 195, 0.45),
      shojiTop: Color(0xFFF5F8FA),
      shojiBottom: Color(0xFFDAE2E8),
      wallLeft: Color(0xFFEBE2D5),
      wallRight: Color(0xFFBFB4A6),
      woodDark: Color(0xFF291810),
      woodMid: Color(0xFF4A2C1D),
      woodHighlight: Color(0xFF754730),
      floorBase: Color(0xFF7D4725),
      floorHighlight: Color(0xFFB56F3E),
      ambientOverlay: Color.fromRGBO(225, 235, 245, 0.06),
      lightBeamColor: Color.fromRGBO(245, 250, 255, 0.32),
      floorPatchColor: Color.fromRGBO(240, 246, 255, 0.36),
      candleIntensity: 0.55,
      foliagePrimary: _winterFoliagePrimary,
      foliageSecondary: _winterFoliageSecondary,
      foliageAccent: _winterFoliageAccent,
      indoorPotFlower: _winterIndoorPotFlower,
      indoorPotLeaf: _winterIndoorPotLeaf,
      particleColor1: _winterParticleColor1,
      particleColor2: _winterParticleColor2,
    ),
    ShanshuiTimeOfDay.dusk: AncientRoomPalette(
      skyTop: Color(0xFF4A5668),
      skyBottom: Color(0xFFDEB09C),
      courtyardMist: Color.fromRGBO(222, 215, 218, 0.50),
      celestialColor: Color(0xFFD9543B),
      celestialGlow: Color.fromRGBO(217, 84, 59, 0.42),
      shojiTop: Color(0xFFD6B8AD),
      shojiBottom: Color(0xFF827678),
      wallLeft: Color(0xFFC9B09C),
      wallRight: Color(0xFF947E6D),
      woodDark: Color(0xFF21130C),
      woodMid: Color(0xFF3B2317),
      woodHighlight: Color(0xFF633B27),
      floorBase: Color(0xFF63361B),
      floorHighlight: Color(0xFF96532B),
      ambientOverlay: Color.fromRGBO(35, 32, 42, 0.38),
      lightBeamColor: Color.fromRGBO(255, 175, 135, 0.26),
      floorPatchColor: Color.fromRGBO(255, 180, 140, 0.30),
      candleIntensity: 0.94,
      foliagePrimary: _winterFoliagePrimary,
      foliageSecondary: _winterFoliageSecondary,
      foliageAccent: _winterFoliageAccent,
      indoorPotFlower: _winterIndoorPotFlower,
      indoorPotLeaf: _winterIndoorPotLeaf,
      particleColor1: _winterParticleColor1,
      particleColor2: _winterParticleColor2,
    ),
    ShanshuiTimeOfDay.night: AncientRoomPalette(
      skyTop: Color(0xFF0F1722),
      skyBottom: Color(0xFF223244),
      courtyardMist: Color.fromRGBO(38, 54, 72, 0.52),
      celestialColor: Color(0xFFF8FAFC),
      celestialGlow: Color.fromRGBO(220, 238, 255, 0.42),
      shojiTop: Color(0xFF2E4054),
      shojiBottom: Color(0xFF1B2633),
      wallLeft: Color(0xFF4F463F),
      wallRight: Color(0xFF38312C),
      woodDark: Color(0xFF120A06),
      woodMid: Color(0xFF24140D),
      woodHighlight: Color(0xFF402518),
      floorBase: Color(0xFF331D10),
      floorHighlight: Color(0xFF57331D),
      ambientOverlay: Color.fromRGBO(8, 14, 24, 0.68),
      lightBeamColor: Color.fromRGBO(205, 228, 255, 0.20),
      floorPatchColor: Color.fromRGBO(205, 228, 255, 0.22),
      candleIntensity: 1.0,
      foliagePrimary: _winterFoliagePrimary,
      foliageSecondary: _winterFoliageSecondary,
      foliageAccent: _winterFoliageAccent,
      indoorPotFlower: _winterIndoorPotFlower,
      indoorPotLeaf: _winterIndoorPotLeaf,
      particleColor1: _winterParticleColor1,
      particleColor2: _winterParticleColor2,
    ),
  };
}
