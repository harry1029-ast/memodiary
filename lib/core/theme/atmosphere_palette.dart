import 'package:flutter/material.dart';
import 'atmosphere_palettes.dart';

/// Unified semantic color tokens for the two-axis Atmosphere Theme system,
/// governing surfaces, accents, seals, woodwork casement framing, folded slips,
/// timeline spine tallies, silk mounts, bamboo blind slats, and the scroll FAB.
@immutable
class AtmospherePalette extends ThemeExtension<AtmospherePalette> {
  final String id;
  final String nameZh;
  final Brightness brightness;

  // App surfaces & ink
  final Color ground;
  final Color deskMat;
  final Color deskTray;
  final Color cardPaper;
  final Color cardStackLip;
  final Color agedFiberChip;
  final Color deckleBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;

  // Interactive vs seal accents
  final Color accentPrimary;
  final Color onAccentPrimary;
  final Color accentPrimaryDark;
  final Color accentPrimaryWash;
  final Color accentSecondary;
  final Color accentSecondaryDim;
  final Color sealAccent;
  final Color sealAccentDark;
  final Color sealAccentWash;
  final Color chipActiveBg;
  final Color chipActiveBorder;
  final Color emeraldSaved;

  // Casement woodwork & sill
  final Color woodFrameDark;
  final Color woodFrameMid;
  final Color woodFrameHighlight;
  final Color headerTitleText;
  final Color headerSubText;
  final Color sillTop;
  final Color sillBottom;
  final Color lipTop;
  final Color lipBottom;
  final Color deskSurroundTop;
  final Color deskSurroundBottom;
  final Color candleGlow;

  // Folded slip accents
  final Color slipRuleColor;
  final Color slipInnerFrameColor;
  final Color slipDividerColor;
  final Color slipShadowColor;

  // Timeline spine & waist tally
  final Color spineCordTop;
  final Color tallyBgTop;
  final Color tallyBgBottom;
  final Color tallyBorder;
  final Color tallyFeaturedTop;
  final Color tallyFeaturedBottom;
  final Color tallyFeaturedBorder;
  final Color tallyFeaturedText;
  final Color tallyFeaturedShadow;

  // Wet-mount silk
  final Color silkMountBg;
  final Color silkMountBorder;
  final Color silkInnerFrame;
  final Color silkMiterSeam;

  // Bamboo blind & cord
  final Color blindSlatTop;
  final Color blindSlatMid;
  final Color blindSlatBottom;
  final Color blindSlit;
  final Color blindRollerTop;
  final Color blindRollerMid;
  final Color blindRollerBottom;
  final Color blindCordPrimary;
  final Color blindCordSecondary;
  final Color blindTagAccent;

  // ScrollRollerFab
  final Color fabTop;
  final Color fabMid;
  final Color fabBottom;
  final Color fabBorder;
  final Color fabInnerBorder;
  final Color fabText;
  final Color fabCapHighlight;
  final Color fabCapMid;
  final Color fabCapDark;
  final Color fabShadow;

  const AtmospherePalette({
    required this.id,
    required this.nameZh,
    required this.brightness,
    required this.ground,
    required this.deskMat,
    required this.deskTray,
    required this.cardPaper,
    required this.cardStackLip,
    required this.agedFiberChip,
    required this.deckleBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.accentPrimary,
    required this.onAccentPrimary,
    required this.accentPrimaryDark,
    required this.accentPrimaryWash,
    required this.accentSecondary,
    required this.accentSecondaryDim,
    required this.sealAccent,
    required this.sealAccentDark,
    required this.sealAccentWash,
    required this.chipActiveBg,
    required this.chipActiveBorder,
    required this.emeraldSaved,
    required this.woodFrameDark,
    required this.woodFrameMid,
    required this.woodFrameHighlight,
    required this.headerTitleText,
    required this.headerSubText,
    required this.sillTop,
    required this.sillBottom,
    required this.lipTop,
    required this.lipBottom,
    required this.deskSurroundTop,
    required this.deskSurroundBottom,
    required this.candleGlow,
    required this.slipRuleColor,
    required this.slipInnerFrameColor,
    required this.slipDividerColor,
    required this.slipShadowColor,
    required this.spineCordTop,
    required this.tallyBgTop,
    required this.tallyBgBottom,
    required this.tallyBorder,
    required this.tallyFeaturedTop,
    required this.tallyFeaturedBottom,
    required this.tallyFeaturedBorder,
    required this.tallyFeaturedText,
    required this.tallyFeaturedShadow,
    required this.silkMountBg,
    required this.silkMountBorder,
    required this.silkInnerFrame,
    required this.silkMiterSeam,
    required this.blindSlatTop,
    required this.blindSlatMid,
    required this.blindSlatBottom,
    required this.blindSlit,
    required this.blindRollerTop,
    required this.blindRollerMid,
    required this.blindRollerBottom,
    required this.blindCordPrimary,
    required this.blindCordSecondary,
    required this.blindTagAccent,
    required this.fabTop,
    required this.fabMid,
    required this.fabBottom,
    required this.fabBorder,
    required this.fabInnerBorder,
    required this.fabText,
    required this.fabCapHighlight,
    required this.fabCapMid,
    required this.fabCapDark,
    required this.fabShadow,
  });

  @override
  AtmospherePalette copyWith({
    String? id,
    String? nameZh,
    Brightness? brightness,
    Color? ground,
    Color? deskMat,
    Color? deskTray,
    Color? cardPaper,
    Color? cardStackLip,
    Color? agedFiberChip,
    Color? deckleBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textFaint,
    Color? accentPrimary,
    Color? onAccentPrimary,
    Color? accentPrimaryDark,
    Color? accentPrimaryWash,
    Color? accentSecondary,
    Color? accentSecondaryDim,
    Color? sealAccent,
    Color? sealAccentDark,
    Color? sealAccentWash,
    Color? chipActiveBg,
    Color? chipActiveBorder,
    Color? emeraldSaved,
    Color? woodFrameDark,
    Color? woodFrameMid,
    Color? woodFrameHighlight,
    Color? headerTitleText,
    Color? headerSubText,
    Color? sillTop,
    Color? sillBottom,
    Color? lipTop,
    Color? lipBottom,
    Color? deskSurroundTop,
    Color? deskSurroundBottom,
    Color? candleGlow,
    Color? slipRuleColor,
    Color? slipInnerFrameColor,
    Color? slipDividerColor,
    Color? slipShadowColor,
    Color? spineCordTop,
    Color? tallyBgTop,
    Color? tallyBgBottom,
    Color? tallyBorder,
    Color? tallyFeaturedTop,
    Color? tallyFeaturedBottom,
    Color? tallyFeaturedBorder,
    Color? tallyFeaturedText,
    Color? tallyFeaturedShadow,
    Color? silkMountBg,
    Color? silkMountBorder,
    Color? silkInnerFrame,
    Color? silkMiterSeam,
    Color? blindSlatTop,
    Color? blindSlatMid,
    Color? blindSlatBottom,
    Color? blindSlit,
    Color? blindRollerTop,
    Color? blindRollerMid,
    Color? blindRollerBottom,
    Color? blindCordPrimary,
    Color? blindCordSecondary,
    Color? blindTagAccent,
    Color? fabTop,
    Color? fabMid,
    Color? fabBottom,
    Color? fabBorder,
    Color? fabInnerBorder,
    Color? fabText,
    Color? fabCapHighlight,
    Color? fabCapMid,
    Color? fabCapDark,
    Color? fabShadow,
  }) {
    return AtmospherePalette(
      id: id ?? this.id,
      nameZh: nameZh ?? this.nameZh,
      brightness: brightness ?? this.brightness,
      ground: ground ?? this.ground,
      deskMat: deskMat ?? this.deskMat,
      deskTray: deskTray ?? this.deskTray,
      cardPaper: cardPaper ?? this.cardPaper,
      cardStackLip: cardStackLip ?? this.cardStackLip,
      agedFiberChip: agedFiberChip ?? this.agedFiberChip,
      deckleBorder: deckleBorder ?? this.deckleBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      onAccentPrimary: onAccentPrimary ?? this.onAccentPrimary,
      accentPrimaryDark: accentPrimaryDark ?? this.accentPrimaryDark,
      accentPrimaryWash: accentPrimaryWash ?? this.accentPrimaryWash,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      accentSecondaryDim: accentSecondaryDim ?? this.accentSecondaryDim,
      sealAccent: sealAccent ?? this.sealAccent,
      sealAccentDark: sealAccentDark ?? this.sealAccentDark,
      sealAccentWash: sealAccentWash ?? this.sealAccentWash,
      chipActiveBg: chipActiveBg ?? this.chipActiveBg,
      chipActiveBorder: chipActiveBorder ?? this.chipActiveBorder,
      emeraldSaved: emeraldSaved ?? this.emeraldSaved,
      woodFrameDark: woodFrameDark ?? this.woodFrameDark,
      woodFrameMid: woodFrameMid ?? this.woodFrameMid,
      woodFrameHighlight: woodFrameHighlight ?? this.woodFrameHighlight,
      headerTitleText: headerTitleText ?? this.headerTitleText,
      headerSubText: headerSubText ?? this.headerSubText,
      sillTop: sillTop ?? this.sillTop,
      sillBottom: sillBottom ?? this.sillBottom,
      lipTop: lipTop ?? this.lipTop,
      lipBottom: lipBottom ?? this.lipBottom,
      deskSurroundTop: deskSurroundTop ?? this.deskSurroundTop,
      deskSurroundBottom: deskSurroundBottom ?? this.deskSurroundBottom,
      candleGlow: candleGlow ?? this.candleGlow,
      slipRuleColor: slipRuleColor ?? this.slipRuleColor,
      slipInnerFrameColor: slipInnerFrameColor ?? this.slipInnerFrameColor,
      slipDividerColor: slipDividerColor ?? this.slipDividerColor,
      slipShadowColor: slipShadowColor ?? this.slipShadowColor,
      spineCordTop: spineCordTop ?? this.spineCordTop,
      tallyBgTop: tallyBgTop ?? this.tallyBgTop,
      tallyBgBottom: tallyBgBottom ?? this.tallyBgBottom,
      tallyBorder: tallyBorder ?? this.tallyBorder,
      tallyFeaturedTop: tallyFeaturedTop ?? this.tallyFeaturedTop,
      tallyFeaturedBottom: tallyFeaturedBottom ?? this.tallyFeaturedBottom,
      tallyFeaturedBorder: tallyFeaturedBorder ?? this.tallyFeaturedBorder,
      tallyFeaturedText: tallyFeaturedText ?? this.tallyFeaturedText,
      tallyFeaturedShadow: tallyFeaturedShadow ?? this.tallyFeaturedShadow,
      silkMountBg: silkMountBg ?? this.silkMountBg,
      silkMountBorder: silkMountBorder ?? this.silkMountBorder,
      silkInnerFrame: silkInnerFrame ?? this.silkInnerFrame,
      silkMiterSeam: silkMiterSeam ?? this.silkMiterSeam,
      blindSlatTop: blindSlatTop ?? this.blindSlatTop,
      blindSlatMid: blindSlatMid ?? this.blindSlatMid,
      blindSlatBottom: blindSlatBottom ?? this.blindSlatBottom,
      blindSlit: blindSlit ?? this.blindSlit,
      blindRollerTop: blindRollerTop ?? this.blindRollerTop,
      blindRollerMid: blindRollerMid ?? this.blindRollerMid,
      blindRollerBottom: blindRollerBottom ?? this.blindRollerBottom,
      blindCordPrimary: blindCordPrimary ?? this.blindCordPrimary,
      blindCordSecondary: blindCordSecondary ?? this.blindCordSecondary,
      blindTagAccent: blindTagAccent ?? this.blindTagAccent,
      fabTop: fabTop ?? this.fabTop,
      fabMid: fabMid ?? this.fabMid,
      fabBottom: fabBottom ?? this.fabBottom,
      fabBorder: fabBorder ?? this.fabBorder,
      fabInnerBorder: fabInnerBorder ?? this.fabInnerBorder,
      fabText: fabText ?? this.fabText,
      fabCapHighlight: fabCapHighlight ?? this.fabCapHighlight,
      fabCapMid: fabCapMid ?? this.fabCapMid,
      fabCapDark: fabCapDark ?? this.fabCapDark,
      fabShadow: fabShadow ?? this.fabShadow,
    );
  }

  @override
  AtmospherePalette lerp(ThemeExtension<AtmospherePalette>? other, double t) {
    if (other is! AtmospherePalette) return this;
    return AtmospherePalette(
      id: t < 0.5 ? id : other.id,
      nameZh: t < 0.5 ? nameZh : other.nameZh,
      brightness: t < 0.5 ? brightness : other.brightness,
      ground: Color.lerp(ground, other.ground, t)!,
      deskMat: Color.lerp(deskMat, other.deskMat, t)!,
      deskTray: Color.lerp(deskTray, other.deskTray, t)!,
      cardPaper: Color.lerp(cardPaper, other.cardPaper, t)!,
      cardStackLip: Color.lerp(cardStackLip, other.cardStackLip, t)!,
      agedFiberChip: Color.lerp(agedFiberChip, other.agedFiberChip, t)!,
      deckleBorder: Color.lerp(deckleBorder, other.deckleBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      onAccentPrimary: Color.lerp(onAccentPrimary, other.onAccentPrimary, t)!,
      accentPrimaryDark: Color.lerp(accentPrimaryDark, other.accentPrimaryDark, t)!,
      accentPrimaryWash: Color.lerp(accentPrimaryWash, other.accentPrimaryWash, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      accentSecondaryDim: Color.lerp(accentSecondaryDim, other.accentSecondaryDim, t)!,
      sealAccent: Color.lerp(sealAccent, other.sealAccent, t)!,
      sealAccentDark: Color.lerp(sealAccentDark, other.sealAccentDark, t)!,
      sealAccentWash: Color.lerp(sealAccentWash, other.sealAccentWash, t)!,
      chipActiveBg: Color.lerp(chipActiveBg, other.chipActiveBg, t)!,
      chipActiveBorder: Color.lerp(chipActiveBorder, other.chipActiveBorder, t)!,
      emeraldSaved: Color.lerp(emeraldSaved, other.emeraldSaved, t)!,
      woodFrameDark: Color.lerp(woodFrameDark, other.woodFrameDark, t)!,
      woodFrameMid: Color.lerp(woodFrameMid, other.woodFrameMid, t)!,
      woodFrameHighlight: Color.lerp(woodFrameHighlight, other.woodFrameHighlight, t)!,
      headerTitleText: Color.lerp(headerTitleText, other.headerTitleText, t)!,
      headerSubText: Color.lerp(headerSubText, other.headerSubText, t)!,
      sillTop: Color.lerp(sillTop, other.sillTop, t)!,
      sillBottom: Color.lerp(sillBottom, other.sillBottom, t)!,
      lipTop: Color.lerp(lipTop, other.lipTop, t)!,
      lipBottom: Color.lerp(lipBottom, other.lipBottom, t)!,
      deskSurroundTop: Color.lerp(deskSurroundTop, other.deskSurroundTop, t)!,
      deskSurroundBottom: Color.lerp(deskSurroundBottom, other.deskSurroundBottom, t)!,
      candleGlow: Color.lerp(candleGlow, other.candleGlow, t)!,
      slipRuleColor: Color.lerp(slipRuleColor, other.slipRuleColor, t)!,
      slipInnerFrameColor: Color.lerp(slipInnerFrameColor, other.slipInnerFrameColor, t)!,
      slipDividerColor: Color.lerp(slipDividerColor, other.slipDividerColor, t)!,
      slipShadowColor: Color.lerp(slipShadowColor, other.slipShadowColor, t)!,
      spineCordTop: Color.lerp(spineCordTop, other.spineCordTop, t)!,
      tallyBgTop: Color.lerp(tallyBgTop, other.tallyBgTop, t)!,
      tallyBgBottom: Color.lerp(tallyBgBottom, other.tallyBgBottom, t)!,
      tallyBorder: Color.lerp(tallyBorder, other.tallyBorder, t)!,
      tallyFeaturedTop: Color.lerp(tallyFeaturedTop, other.tallyFeaturedTop, t)!,
      tallyFeaturedBottom: Color.lerp(tallyFeaturedBottom, other.tallyFeaturedBottom, t)!,
      tallyFeaturedBorder: Color.lerp(tallyFeaturedBorder, other.tallyFeaturedBorder, t)!,
      tallyFeaturedText: Color.lerp(tallyFeaturedText, other.tallyFeaturedText, t)!,
      tallyFeaturedShadow: Color.lerp(tallyFeaturedShadow, other.tallyFeaturedShadow, t)!,
      silkMountBg: Color.lerp(silkMountBg, other.silkMountBg, t)!,
      silkMountBorder: Color.lerp(silkMountBorder, other.silkMountBorder, t)!,
      silkInnerFrame: Color.lerp(silkInnerFrame, other.silkInnerFrame, t)!,
      silkMiterSeam: Color.lerp(silkMiterSeam, other.silkMiterSeam, t)!,
      blindSlatTop: Color.lerp(blindSlatTop, other.blindSlatTop, t)!,
      blindSlatMid: Color.lerp(blindSlatMid, other.blindSlatMid, t)!,
      blindSlatBottom: Color.lerp(blindSlatBottom, other.blindSlatBottom, t)!,
      blindSlit: Color.lerp(blindSlit, other.blindSlit, t)!,
      blindRollerTop: Color.lerp(blindRollerTop, other.blindRollerTop, t)!,
      blindRollerMid: Color.lerp(blindRollerMid, other.blindRollerMid, t)!,
      blindRollerBottom: Color.lerp(blindRollerBottom, other.blindRollerBottom, t)!,
      blindCordPrimary: Color.lerp(blindCordPrimary, other.blindCordPrimary, t)!,
      blindCordSecondary: Color.lerp(blindCordSecondary, other.blindCordSecondary, t)!,
      blindTagAccent: Color.lerp(blindTagAccent, other.blindTagAccent, t)!,
      fabTop: Color.lerp(fabTop, other.fabTop, t)!,
      fabMid: Color.lerp(fabMid, other.fabMid, t)!,
      fabBottom: Color.lerp(fabBottom, other.fabBottom, t)!,
      fabBorder: Color.lerp(fabBorder, other.fabBorder, t)!,
      fabInnerBorder: Color.lerp(fabInnerBorder, other.fabInnerBorder, t)!,
      fabText: Color.lerp(fabText, other.fabText, t)!,
      fabCapHighlight: Color.lerp(fabCapHighlight, other.fabCapHighlight, t)!,
      fabCapMid: Color.lerp(fabCapMid, other.fabCapMid, t)!,
      fabCapDark: Color.lerp(fabCapDark, other.fabCapDark, t)!,
      fabShadow: Color.lerp(fabShadow, other.fabShadow, t)!,
    );
  }
}

/// Convenience extension on [BuildContext] to access the active [AtmospherePalette].
extension AtmospherePaletteContext on BuildContext {
  AtmospherePalette get atmospherePalette {
    final theme = Theme.of(this);
    return theme.extension<AtmospherePalette>() ??
        (theme.brightness == Brightness.dark
            ? AtmospherePalettes.yunhaoNight
            : AtmospherePalettes.yunhaoDay);
  }
}
