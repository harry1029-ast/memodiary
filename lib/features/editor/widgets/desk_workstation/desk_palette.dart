import 'package:flutter/material.dart';

/// The fixed colours of the Scholar's Desk (文房书案), chosen by the app's
/// brightness and never by the entry's stationery template: warm walnut in the
/// light appearance, a deeper ebony in the dark one. The bamboo mat and brass
/// inlays are tuned to sit on their desk.
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

  static DeskPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? ebony : walnut;

  static DeskPalette of(BuildContext context) => forBrightness(Theme.of(context).brightness);
}
