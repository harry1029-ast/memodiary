import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/atmosphere_palettes.dart';

/// Color tokens for the Window Sill Ledge (`窗台案沿`) and Chronicle Desk (`案头卷匣`),
/// resolved from the active [AtmospherePalette] with Cloud-Moon defaults and
/// Classic (`宣纸胡桃` / `碑拓乌木`) preservation.
@immutable
class ChronicleDeskPalette {
  final Color woodFrameDark;
  final Color woodFrameMid;
  final Color woodFrameHighlight;
  final Color sillTop;
  final Color sillBottom;
  final Color lipTop;
  final Color lipBottom;
  final Color deskSurroundTop;
  final Color deskSurroundBottom;
  final Color deskMat;
  final Color deskTray;
  final Color agedChip;
  final Color deckleBorder;
  final Color brassGold;
  final Color brassDim;
  final Color cinnabar;
  final Color textPrimary;
  final Color textMuted;
  final Color textFaint;
  final Color candleGlow;

  const ChronicleDeskPalette({
    required this.woodFrameDark,
    required this.woodFrameMid,
    required this.woodFrameHighlight,
    required this.sillTop,
    required this.sillBottom,
    required this.lipTop,
    required this.lipBottom,
    required this.deskSurroundTop,
    required this.deskSurroundBottom,
    required this.deskMat,
    required this.deskTray,
    required this.agedChip,
    required this.deckleBorder,
    required this.brassGold,
    required this.brassDim,
    required this.cinnabar,
    required this.textPrimary,
    required this.textMuted,
    required this.textFaint,
    required this.candleGlow,
  });

  /// Classic dark theme ("碑拓乌木" — Stone Rubbing & Ebony).
  static const ChronicleDeskPalette classicDark = ChronicleDeskPalette(
    woodFrameDark: Color(0xFF1C140F),
    woodFrameMid: Color(0xFF2D2018),
    woodFrameHighlight: Color(0xFF473325),
    sillTop: Color(0xFF2C1E16),
    sillBottom: Color(0xFF19110C),
    lipTop: Color(0xFF3E2B1F),
    lipBottom: Color(0xFF140D09),
    deskSurroundTop: Color(0xFF1D150F),
    deskSurroundBottom: Color(0xFF120D09),
    deskMat: Color(0xFF181816),
    deskTray: Color(0xFF211F1C),
    agedChip: Color(0xFF2E2C28),
    deckleBorder: Color(0xFF3D3A34),
    brassGold: Color(0xFFC8A96E),
    brassDim: Color(0xFF7E6840),
    cinnabar: Color(0xFFD25447),
    textPrimary: Color(0xFFF0ECE3),
    textMuted: Color(0xFFA69F93),
    textFaint: Color(0xFF756E63),
    candleGlow: Color.fromRGBO(255, 184, 77, 0.16),
  );

  /// Classic light theme ("宣纸胡桃" — Xuan Paper & Walnut).
  static const ChronicleDeskPalette classicLight = ChronicleDeskPalette(
    woodFrameDark: Color(0xFF3D2719),
    woodFrameMid: Color(0xFF593A26),
    woodFrameHighlight: Color(0xFF785036),
    sillTop: Color(0xFF68442C),
    sillBottom: Color(0xFF4A2F1D),
    lipTop: Color(0xFF7C5337),
    lipBottom: Color(0xFF382214),
    deskSurroundTop: Color(0xFFDFD3C0),
    deskSurroundBottom: Color(0xFFDFD3C0),
    deskMat: Color(0xFFEAE2D3),
    deskTray: Color(0xFFE2D8C5),
    agedChip: Color(0xFFDDD2BE),
    deckleBorder: Color(0xFFC9B99E),
    brassGold: Color(0xFF9A7432),
    brassDim: Color(0xFFB5955B),
    cinnabar: Color(0xFFC43E30),
    textPrimary: Color(0xFF26211D),
    textMuted: Color(0xFF5C5347),
    textFaint: Color(0xFF887D6E),
    candleGlow: Color.fromRGBO(255, 195, 95, 0.22),
  );

  /// Default dark theme ("皓月夜" — Yunhao Night).
  static final ChronicleDeskPalette dark =
      ChronicleDeskPalette.fromAtmosphere(AtmospherePalettes.yunhaoNight);

  /// Default light theme ("云岚昼" — Yunhao Day).
  static final ChronicleDeskPalette light =
      ChronicleDeskPalette.fromAtmosphere(AtmospherePalettes.yunhaoDay);

  /// Derives a [ChronicleDeskPalette] from an [AtmospherePalette],
  /// preserving exact legacy hex tokens for [AtmospherePalettes.classicWalnut]
  /// and [AtmospherePalettes.classicEbony].
  factory ChronicleDeskPalette.fromAtmosphere(AtmospherePalette palette) {
    if (palette.id == AtmospherePalettes.classicWalnut.id) return classicLight;
    if (palette.id == AtmospherePalettes.classicEbony.id) return classicDark;
    return ChronicleDeskPalette(
      woodFrameDark: palette.woodFrameDark,
      woodFrameMid: palette.woodFrameMid,
      woodFrameHighlight: palette.woodFrameHighlight,
      sillTop: palette.sillTop,
      sillBottom: palette.sillBottom,
      lipTop: palette.lipTop,
      lipBottom: palette.lipBottom,
      deskSurroundTop: palette.deskSurroundTop,
      deskSurroundBottom: palette.deskSurroundBottom,
      deskMat: palette.deskMat,
      deskTray: palette.deskTray,
      agedChip: palette.agedFiberChip,
      deckleBorder: palette.deckleBorder,
      brassGold: palette.accentSecondary,
      brassDim: palette.accentSecondaryDim,
      cinnabar: palette.accentPrimary,
      textPrimary: palette.textPrimary,
      textMuted: palette.textMuted,
      textFaint: palette.textFaint,
      candleGlow: palette.candleGlow,
    );
  }

  /// Resolves the palette matching the active [AtmospherePalette] extension,
  /// falling back to [dark] / [light] by [ThemeData.brightness].
  static ChronicleDeskPalette of(BuildContext context) {
    final atmosphere = Theme.of(context).extension<AtmospherePalette>();
    if (atmosphere != null) {
      return ChronicleDeskPalette.fromAtmosphere(atmosphere);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }
}
