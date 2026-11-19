import 'package:flutter/material.dart';

import '../../../../core/theme/atmosphere_palette.dart';
import '../../../../core/theme/atmosphere_palettes.dart';

/// The fixed dark colours of the Scholar's Desk (文房书案), resolved from the
/// active [AtmospherePalette] (with brightness fallback) and never by the
/// entry's stationery template. The bamboo mat and brass inlays are tuned to
/// sit on their desk.
class DeskPalette {
  /// Desk base colour.
  final Color base;

  /// Centre and edge colours of the radial highlight laid over the base.
  final Color highlight;
  final Color vignette;

  /// Long grain lines running the width of the desk.
  final Color grain;

  /// Bamboo mat ground, its slat highlight and shadow, binding threads, rim.
  final Color mat;
  final Color slatLight;
  final Color slatShadow;
  final Color thread;
  final Color matRim;

  /// Antique brass of the mat corner inlays.
  final Color brass;

  const DeskPalette({
    required this.base,
    required this.highlight,
    required this.vignette,
    required this.grain,
    required this.mat,
    required this.slatLight,
    required this.slatShadow,
    required this.thread,
    required this.matRim,
    required this.brass,
  });

  static const walnut = DeskPalette(
    base: Color(0xFF211A14),
    highlight: Color(0x17FFE8B9),
    vignette: Color(0xB80F0B08),
    grain: Color(0x29000000),
    mat: Color(0xFF241D16),
    slatLight: Color(0x0DD4AF37),
    slatShadow: Color(0x38000000),
    thread: Color(0x40000000),
    matRim: Color(0x598C6D46),
    brass: Color(0x8CD4AF37),
  );

  /// Ebony, after the prototype's `#2B231B -> #120F0C` well, with fainter grain.
  static const ebony = DeskPalette(
    base: Color(0xFF120F0C),
    highlight: Color(0x12FFE8B9),
    vignette: Color(0xD1050403),
    grain: Color(0x14000000),
    mat: Color(0xFF1B1611),
    slatLight: Color(0x08D4AF37),
    slatShadow: Color(0x4D000000),
    thread: Color(0x59000000),
    matRim: Color(0x4D6B5435),
    brass: Color(0x73BF9B30),
  );

  static const yunhaoDay = DeskPalette(
    base: Color(0xFF1B2734), highlight: Color(0x1AE6F1FA), vignette: Color(0xBD0D141C),
    grain: Color(0x26000000), mat: Color(0xFF212E3B), slatLight: Color(0x0D6E9D99),
    slatShadow: Color(0x38000000), thread: Color(0x42000000), matRim: Color(0x595B7B94),
    brass: Color(0x8CC9975B),
  );

  static const yunhaoNight = DeskPalette(
    base: Color(0xFF0B121D), highlight: Color(0x14F2B866), vignette: Color(0xD404070C),
    grain: Color(0x17000000), mat: Color(0xFF121C2B), slatLight: Color(0x0AA8C0D6),
    slatShadow: Color(0x4D000000), thread: Color(0x59000000), matRim: Color(0x522B425E),
    brass: Color(0x80F2B866),
  );

  static const mistyTwilight = DeskPalette(
    base: Color(0xFF1E2022), highlight: Color(0x14EAE6DC), vignette: Color(0xBF0E0F10),
    grain: Color(0x24000000), mat: Color(0xFF26282B), slatLight: Color(0x0DB08642),
    slatShadow: Color(0x3D000000), thread: Color(0x45000000), matRim: Color(0x595B5D60),
    brass: Color(0x8CB08642),
  );

  static const silveryRain = DeskPalette(
    base: Color(0xFF0E151D), highlight: Color(0x128FB2C9), vignette: Color(0xD1060A0E),
    grain: Color(0x17000000), mat: Color(0xFF15202B), slatLight: Color(0x0AE8C07D),
    slatShadow: Color(0x4D000000), thread: Color(0x59000000), matRim: Color(0x4D394F63),
    brass: Color(0x78E8C07D),
  );

  static const blossomLantern = DeskPalette(
    base: Color(0xFF0C181A), highlight: Color(0x14F4B860), vignette: Color(0xD1050B0C),
    grain: Color(0x17000000), mat: Color(0xFF132427), slatLight: Color(0x0AF4B860),
    slatShadow: Color(0x4D000000), thread: Color(0x59000000), matRim: Color(0x4D35595F),
    brass: Color(0x7DF4B860),
  );

  static DeskPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? ebony : walnut;

  /// Resolves the scholar's desk palette matching [palette].
  static DeskPalette forAtmosphere(AtmospherePalette palette) {
    if (palette.id == AtmospherePalettes.classicWalnut.id) return walnut;
    if (palette.id == AtmospherePalettes.classicEbony.id) return ebony;
    if (palette.id == AtmospherePalettes.mistyTwilight.id) return mistyTwilight;
    if (palette.id == AtmospherePalettes.yunhaoNight.id) return yunhaoNight;
    if (palette.id == AtmospherePalettes.silveryRain.id) return silveryRain;
    if (palette.id == AtmospherePalettes.blossomLantern.id) return blossomLantern;
    if (palette.id == AtmospherePalettes.yunhaoDay.id) return yunhaoDay;
    return forBrightness(palette.brightness);
  }

  /// Resolves the active [DeskPalette] from [AtmospherePalette], falling back to brightness.
  static DeskPalette of(BuildContext context) {
    final atmosphere = Theme.of(context).extension<AtmospherePalette>();
    return atmosphere != null
        ? forAtmosphere(atmosphere)
        : forBrightness(Theme.of(context).brightness);
  }
}
