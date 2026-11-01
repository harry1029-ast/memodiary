import 'package:flutter/material.dart';
import 'shanshui_atmosphere.dart';

/// Descriptor for a townsfolk character or stall vendor/patron in the ancient street.
class TownsfolkWalker {
  final double baseX;
  final double baseY;
  final double scale;
  final Color jacket;
  final Color vest;
  final Color pants;
  final double phase;
  final double speed;
  final bool hasUmbrella;
  final bool showAtNight;
  final bool holdingCup;
  final bool isVendorOrPatron;

  const TownsfolkWalker({
    required this.baseX,
    required this.baseY,
    required this.scale,
    required this.jacket,
    required this.vest,
    required this.pants,
    required this.phase,
    required this.speed,
    this.hasUmbrella = false,
    this.showAtNight = false,
    this.holdingCup = false,
    this.isVendorOrPatron = false,
  });
}

/// Drifting cloud descriptor behind the central mountain peak.
class OutdoorCloud {
  double x;
  final double y;
  final double scale;
  final double speed;

  OutdoorCloud({
    required this.x,
    required this.y,
    required this.scale,
    required this.speed,
  });

  static List<OutdoorCloud> createDefaultClouds() => [
        OutdoorCloud(x: 260, y: 185, scale: 1.0, speed: 10),
        OutdoorCloud(x: 520, y: 125, scale: 1.15, speed: 13),
        OutdoorCloud(x: 890, y: 95, scale: 1.35, speed: 11),
        OutdoorCloud(x: 1160, y: 155, scale: 0.95, speed: 14),
      ];
}

/// Rising food stall steam wisp descriptor.
class OutdoorSteamWisp {
  double progress;
  final double phase;
  final bool isLeftStall;

  OutdoorSteamWisp({
    required this.progress,
    required this.phase,
    required this.isLeftStall,
  });

  static List<OutdoorSteamWisp> createDefaultWisps() {
    return List.generate(24, (i) {
      return OutdoorSteamWisp(
        progress: (i / 24.0) % 1.0,
        phase: (i * 0.785) % 6.28,
        isLeftStall: i % 2 == 0,
      );
    });
  }
}

/// Expanding puddle ripple on the stone avenue.
class OutdoorPuddleRipple {
  final double x;
  final double y;
  double radius;
  double alpha;

  OutdoorPuddleRipple({
    required this.x,
    required this.y,
    this.radius = 4.0,
    this.alpha = 0.8,
  });

  void update({double radiusStep = 1.4, double alphaDecay = 0.96}) {
    radius += radiusStep;
    alpha *= alphaDecay;
  }

  bool get isExpired => alpha <= 0.04;
}

/// Red paper lantern descriptor along the street eaves.
class OutdoorLantern {
  final double x;
  final double y;
  final double rx;
  final double ry;
  final double phase;

  const OutdoorLantern({
    required this.x,
    required this.y,
    required this.rx,
    required this.ry,
    required this.phase,
  });

  static List<OutdoorLantern> createStreetLanterns() => const [
        // Left foreground & mid-ground lanterns
        OutdoorLantern(x: 24, y: 175, rx: 46, ry: 38, phase: 0.0),
        OutdoorLantern(x: 242, y: 272, rx: 38, ry: 31, phase: 0.8),
        OutdoorLantern(x: 18, y: 465, rx: 32, ry: 26, phase: 1.4),
        OutdoorLantern(x: 405, y: 498, rx: 25, ry: 20, phase: 2.1),
        OutdoorLantern(x: 510, y: 542, rx: 16, ry: 13, phase: 2.8),
        OutdoorLantern(x: 562, y: 548, rx: 14, ry: 11, phase: 3.4),
        // Right foreground & mid-ground lanterns
        OutdoorLantern(x: 1318, y: 292, rx: 38, ry: 31, phase: 0.4),
        OutdoorLantern(x: 1478, y: 465, rx: 36, ry: 30, phase: 1.1),
        OutdoorLantern(x: 1292, y: 492, rx: 30, ry: 24, phase: 1.9),
        OutdoorLantern(x: 1125, y: 512, rx: 22, ry: 18, phase: 2.5),
        OutdoorLantern(x: 1068, y: 508, rx: 16, ry: 13, phase: 3.1),
        OutdoorLantern(x: 982, y: 538, rx: 14, ry: 11, phase: 3.8),
      ];
}

/// Lifecycle manager for townsfolk walkers, stall merchants, and umbrella states.
class OutdoorStreetCrowd {
  const OutdoorStreetCrowd._();

  /// 15 central avenue walkers sorted back-to-front by baseY.
  static const List<TownsfolkWalker> avenueWalkers = [
    // Far-ground walkers under and near the Paifang gate
    TownsfolkWalker(
      baseX: 722, baseY: 586, scale: 0.30,
      jacket: Color(0xFF7A6855), vest: Color(0xFF4E3E30), pants: Color(0xFF2E2925),
      phase: 0.5, speed: 1.5, hasUmbrella: false, showAtNight: false,
    ),
    TownsfolkWalker(
      baseX: 768, baseY: 590, scale: 0.32,
      jacket: Color(0xFF9E8C7A), vest: Color(0xFF5C4E42), pants: Color(0xFF332E2A),
      phase: 1.9, speed: 1.4, hasUmbrella: true, showAtNight: false,
    ),
    TownsfolkWalker(
      baseX: 662, baseY: 596, scale: 0.35,
      jacket: Color(0xFFD4B499), vest: Color(0xFF8C4A32), pants: Color(0xFF3A322C),
      phase: 2.7, speed: 1.7, hasUmbrella: false, showAtNight: false,
    ),
    TownsfolkWalker(
      baseX: 745, baseY: 602, scale: 0.36,
      jacket: Color(0xFFC87D55), vest: Color(0xFF8C3B2B), pants: Color(0xFF3D352E),
      phase: 0.2, speed: 1.8, hasUmbrella: true, showAtNight: true,
    ),
    TownsfolkWalker(
      baseX: 798, baseY: 606, scale: 0.38,
      jacket: Color(0xFF5E8C6A), vest: Color(0xFF3B5E45), pants: Color(0xFF2E3630),
      phase: 1.5, speed: 1.6, hasUmbrella: false, showAtNight: false,
    ),
    TownsfolkWalker(
      baseX: 848, baseY: 612, scale: 0.40,
      jacket: Color(0xFF68829E), vest: Color(0xFF3E5268), pants: Color(0xFF2C333B),
      phase: 3.1, speed: 1.6, hasUmbrella: true, showAtNight: false,
    ),
    // Mid-ground shoppers browsing side stalls & walking the avenue
    TownsfolkWalker(
      baseX: 558, baseY: 638, scale: 0.48,
      jacket: Color(0xFFD99B82), vest: Color(0xFF9E4738), pants: Color(0xFF423833),
      phase: 1.2, speed: 1.2, hasUmbrella: false, showAtNight: false,
    ),
    TownsfolkWalker(
      baseX: 932, baseY: 642, scale: 0.48,
      jacket: Color(0xFF7A9A82), vest: Color(0xFF496952), pants: Color(0xFF383E3A),
      phase: 2.4, speed: 1.3, hasUmbrella: true, showAtNight: false,
    ),
    TownsfolkWalker(
      baseX: 690, baseY: 668, scale: 0.58,
      jacket: Color(0xFFE8D8C8), vest: Color(0xFFC84B31), pants: Color(0xFF4A3E38),
      phase: 0.8, speed: 2.1, hasUmbrella: true, showAtNight: true,
    ),
    TownsfolkWalker(
      baseX: 745, baseY: 672, scale: 0.58,
      jacket: Color(0xFF689F4E), vest: Color(0xFF4E7D38), pants: Color(0xFF4A3E38),
      phase: 2.3, speed: 2.1, hasUmbrella: false, showAtNight: false,
    ),
    TownsfolkWalker(
      baseX: 835, baseY: 692, scale: 0.64,
      jacket: Color(0xFFD4A359), vest: Color(0xFF8C5828), pants: Color(0xFF3E352E),
      phase: 0.6, speed: 1.9, hasUmbrella: false, showAtNight: false,
    ),
    TownsfolkWalker(
      baseX: 525, baseY: 710, scale: 0.68,
      jacket: Color(0xFFC98A96), vest: Color(0xFF8F3D4C), pants: Color(0xFF42383B),
      phase: 2.0, speed: 1.5, hasUmbrella: true, showAtNight: false,
    ),
    // Foreground main street characters
    TownsfolkWalker(
      baseX: 468, baseY: 775, scale: 0.88,
      jacket: Color(0xFF5E8C4A), vest: Color(0xFF4A7339), pants: Color(0xFF4A4039),
      phase: 1.1, speed: 2.4, hasUmbrella: true, showAtNight: false,
    ),
    TownsfolkWalker(
      baseX: 608, baseY: 818, scale: 0.82,
      jacket: Color(0xFF9E6B9E), vest: Color(0xFFC83E4B), pants: Color(0xFF45484F),
      phase: 3.0, speed: 2.8, hasUmbrella: false, showAtNight: false,
    ),
    TownsfolkWalker(
      baseX: 965, baseY: 825, scale: 0.90,
      jacket: Color(0xFF6E8EB5), vest: Color(0xFFC84630), pants: Color(0xFF4A423E),
      phase: 0.4, speed: 2.3, hasUmbrella: true, holdingCup: true, showAtNight: true,
    ),
  ];

  /// 7 foreground and mid-ground stall vendors & seated/standing patrons.
  static const List<TownsfolkWalker> stallFigures = [
    // Left Stall Figures (Day & Dusk only)
    TownsfolkWalker(
      baseX: 158, baseY: 715, scale: 0.92,
      jacket: Color(0xFFE2E6EC), vest: Color(0xFF4F6278), pants: Color(0xFF364152),
      phase: 0.0, speed: 0.4, isVendorOrPatron: true,
    ),
    TownsfolkWalker(
      baseX: 382, baseY: 642, scale: 0.66,
      jacket: Color(0xFFC87A82), vest: Color(0xFF8F3E48), pants: Color(0xFF3B3234),
      phase: 1.6, speed: 0.35, isVendorOrPatron: true,
    ),
    TownsfolkWalker(
      baseX: 322, baseY: 785, scale: 0.96,
      jacket: Color(0xFFD8DCE3), vest: Color(0xFF3F5678), pants: Color(0xFF3A3532),
      phase: 1.2, speed: 0.5, holdingCup: true, isVendorOrPatron: true,
    ),
    // Right Stall Figures
    TownsfolkWalker(
      baseX: 1245, baseY: 695, scale: 0.84,
      jacket: Color(0xFFE6D8C5), vest: Color(0xFF7A4B38), pants: Color(0xFF3D352E),
      phase: 0.7, speed: 0.4, showAtNight: true, isVendorOrPatron: true,
    ),
    TownsfolkWalker(
      baseX: 1022, baseY: 672, scale: 0.65,
      jacket: Color(0xFF547A8C), vest: Color(0xFF385463), pants: Color(0xFF2E363B),
      phase: 2.5, speed: 0.45, isVendorOrPatron: true,
    ),
    TownsfolkWalker(
      baseX: 1102, baseY: 712, scale: 0.82,
      jacket: Color(0xFF5E8C4A), vest: Color(0xFF4E7A3B), pants: Color(0xFF3A4238),
      phase: 2.1, speed: 0.3, isVendorOrPatron: true,
    ),
    TownsfolkWalker(
      baseX: 1342, baseY: 738, scale: 0.86,
      jacket: Color(0xFF9E3832), vest: Color(0xFF7D2822), pants: Color(0xFF2E3440),
      phase: 1.4, speed: 0.3, showAtNight: true, isVendorOrPatron: true,
    ),
  ];

  /// Resolves the active crowd figures according to time-of-day crowd lifecycle.
  static List<TownsfolkWalker> getActiveFigures(ShanshuiTimeOfDay timeOfDay) {
    switch (timeOfDay) {
      case ShanshuiTimeOfDay.dawn:
        return const [];
      case ShanshuiTimeOfDay.day:
      case ShanshuiTimeOfDay.dusk:
        return [...avenueWalkers, ...stallFigures];
      case ShanshuiTimeOfDay.night:
        return [
          ...avenueWalkers.where((walker) => walker.showAtNight),
          ...stallFigures.where((figure) => figure.showAtNight),
        ];
    }
  }

  /// Whether current weather requires walkers to carry oiled-paper umbrellas.
  static bool isPrecipitationWeather(ShanshuiWeather weather) {
    return weather == ShanshuiWeather.rainy ||
        weather == ShanshuiWeather.stormy ||
        weather == ShanshuiWeather.snowy;
  }

  /// Whether food steam is active for the specified stall and time of day.
  static bool isSteamActive(ShanshuiTimeOfDay timeOfDay, {required bool isLeftStall}) {
    if (timeOfDay == ShanshuiTimeOfDay.dawn) return false;
    if (timeOfDay == ShanshuiTimeOfDay.night && isLeftStall) return false;
    return true;
  }
}
