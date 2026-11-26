import 'package:flutter/material.dart';
import 'atmosphere_palette.dart';
import 'atmosphere_theme_models.dart';

/// Constant catalog of all 3 Light and 4 Dark [AtmospherePalette] definitions
/// matching SPEC-022 color tokens and legacy `经典` hex preservation.
class AtmospherePalettes {
  const AtmospherePalettes._();

  static const AtmospherePalette yunhaoDay = AtmospherePalette(
    id: 'yunhaoDay', nameZh: '云岚昼', brightness: Brightness.light,
    ground: Color(0xFFEFF3F6), deskMat: Color(0xFFF6F8FA), deskTray: Color(0xFFEAEFF3),
    cardPaper: Color(0xFFFFFFFF), cardStackLip: Color(0xFFD3DCE4), agedFiberChip: Color(0xFFE3E9EF), deckleBorder: Color(0xFFCCD5DF),
    textPrimary: Color(0xFF1E2A38), textSecondary: Color(0xFF344658), textMuted: Color(0xFF516578), textFaint: Color(0xFF7E93A6),
    accentPrimary: Color(0xFF4A7A9C), onAccentPrimary: Colors.white, accentPrimaryDark: Color(0xFF355C78), accentPrimaryWash: Color(0xFFE2ECF3),
    accentSecondary: Color(0xFF4E8782), accentSecondaryDim: Color(0xFF6E9D99),
    sealAccent: Color(0xFFC24D43), sealAccentDark: Color(0xFF9A3830), sealAccentWash: Color(0xFFF5E5E3),
    chipActiveBg: Color(0x334A7A9C), chipActiveBorder: Color(0x8C4A7A9C), emeraldSaved: Color(0xFF059669),
    woodFrameDark: Color(0xFF48647A), woodFrameMid: Color(0xFF5B7B94), woodFrameHighlight: Color(0xFF89A8BF),
    headerTitleText: Color(0xFFF7F9FB), headerSubText: Color(0xFFCEDAE5),
    sillTop: Color(0xFF527087), sillBottom: Color(0xFF3B5265), lipTop: Color(0xFF65859E), lipBottom: Color(0xFF2D4050),
    deskSurroundTop: Color(0xFFE4EBF0), deskSurroundBottom: Color(0xFFDDE5EC), candleGlow: Color.fromRGBO(255, 210, 130, 0.20),
    slipRuleColor: Color(0x124A7A9C), slipInnerFrameColor: Color(0x244E8782), slipDividerColor: Color(0x2B4A7A9C), slipShadowColor: Color(0x140E1A26),
    spineCordTop: Color(0xFF4A7A9C),
    scrubberRailStops: [
      Color(0xFF4A7A9C), Color(0xFF5D89A3), Color(0xFF4E8782), Color(0xFF6B9691), Color(0xFFB58E5B),
    ],
    tallyBgTop: Color(0xFFFFFFFF), tallyBgBottom: Color(0xFFE7EEF4), tallyBorder: Color(0xFFB4C5D4),
    tallyFeaturedTop: Color(0xFF5285A8), tallyFeaturedBottom: Color(0xFF3A6685), tallyFeaturedBorder: Color(0xFF87B5D4),
    tallyFeaturedText: Colors.white, tallyFeaturedShadow: Color(0x4D3A6685),
    silkMountBg: Color(0xFFEBF1F5), silkMountBorder: Color(0xFFA8BDCE), silkInnerFrame: Color(0xFF68849B), silkMiterSeam: Color(0xFF8BA2B5),
    blindSlatTop: Color(0xFFDAE4EC), blindSlatMid: Color(0xFFEEF4F8), blindSlatBottom: Color(0xFFC4D4E0), blindSlit: Color(0xFF8DA1B2),
    blindRollerTop: Color(0xFF5B7B94), blindRollerMid: Color(0xFF48647A), blindRollerBottom: Color(0xFF334A5C),
    blindCordPrimary: Color(0xFF4A7A9C), blindCordSecondary: Color(0xFFC9975B), blindTagAccent: Color(0xFFC9975B),
    fabTop: Color(0xFF4E8782), fabMid: Color(0xFF427772), fabBottom: Color(0xFF376662),
    fabBorder: Color(0xFF8BC2BC), fabInnerBorder: Color(0x59E6F4F2), fabText: Color(0xFFF7FBFA),
    fabCapHighlight: Color(0xFFCBE6E3), fabCapMid: Color(0xFF8BC2BC), fabCapDark: Color(0xFF264845), fabShadow: Color(0x66376662),
  );

  static const AtmospherePalette classicWalnut = AtmospherePalette(
    id: 'classicWalnut', nameZh: '宣纸胡桃', brightness: Brightness.light,
    ground: Color(0xFFFCF9F2), deskMat: Color(0xFFEAE2D3), deskTray: Color(0xFFE2D8C5),
    cardPaper: Color(0xFFFAF6EE), cardStackLip: Color(0xFFD4C7B0), agedFiberChip: Color(0xFFDDD2BE), deckleBorder: Color(0xFFC9B99E),
    textPrimary: Color(0xFF1E1E1E), textSecondary: Color(0xFF2D2D2D), textMuted: Color(0xFF68645E), textFaint: Color(0xFF9E998F),
    accentPrimary: Color(0xFFB83B2E), onAccentPrimary: Colors.white, accentPrimaryDark: Color(0xFF982B1F), accentPrimaryWash: Color(0xFFF3E5E3),
    accentSecondary: Color(0xFF9A7432), accentSecondaryDim: Color(0xFFB5955B),
    sealAccent: Color(0xFFC43E30), sealAccentDark: Color(0xFF982B1F), sealAccentWash: Color(0xFFF3E5E3),
    chipActiveBg: Color(0x33C43E30), chipActiveBorder: Color(0x8CC43E30), emeraldSaved: Color(0xFF059669),
    woodFrameDark: Color(0xFF3D2719), woodFrameMid: Color(0xFF593A26), woodFrameHighlight: Color(0xFF785036),
    headerTitleText: Color(0xFFFAF6EE), headerSubText: Color(0xFFDCD2C0),
    sillTop: Color(0xFF68442C), sillBottom: Color(0xFF4A2F1D), lipTop: Color(0xFF7C5337), lipBottom: Color(0xFF382214),
    deskSurroundTop: Color(0xFFDFD3C0), deskSurroundBottom: Color(0xFFDFD3C0), candleGlow: Color.fromRGBO(255, 195, 95, 0.22),
    slipRuleColor: Color(0x14B84335), slipInnerFrameColor: Color(0x249A7432), slipDividerColor: Color(0x2E9A7432), slipShadowColor: Color(0x17000000),
    spineCordTop: Color(0xFFB83B2E),
    scrubberRailStops: [
      Color(0xFFA65443), Color(0xFFB07846), Color(0xFF9A7432), Color(0xFF7F6A4A), Color(0xFF6B5847),
    ],
    tallyBgTop: Color(0xFFF7F2E6), tallyBgBottom: Color(0xFFE5D7BC), tallyBorder: Color(0xFFB5A487),
    tallyFeaturedTop: Color(0xFFD95B4D), tallyFeaturedBottom: Color(0xFFA6362A), tallyFeaturedBorder: Color(0xFFEC897E),
    tallyFeaturedText: Colors.white, tallyFeaturedShadow: Color(0x59A82E21),
    silkMountBg: Color(0xFFE8DFCE), silkMountBorder: Color(0xFFB8A689), silkInnerFrame: Color(0xFF9A7B48), silkMiterSeam: Color(0xFF9C8B70),
    blindSlatTop: Color(0xFF6E4F32), blindSlatMid: Color(0xFF8A6542), blindSlatBottom: Color(0xFF543B24), blindSlit: Color(0xEB22160D),
    blindRollerTop: Color(0xFF785436), blindRollerMid: Color(0xFF4B311D), blindRollerBottom: Color(0xFF2B1B10),
    blindCordPrimary: Color(0xFFB83B2E), blindCordSecondary: Color(0xFFDFC184), blindTagAccent: Color(0xFFE6C786),
    fabTop: Color(0xFFC43E30), fabMid: Color(0xFFA82F22), fabBottom: Color(0xFF8C2014),
    fabBorder: Color(0xFFD9A962), fabInnerBorder: Color(0x59FFE8D6), fabText: Color(0xFFFFF9F2),
    fabCapHighlight: Color(0xFFD9A962), fabCapMid: Color(0xFF5A432F), fabCapDark: Color(0xFF2B221B), fabShadow: Color(0x738C2014),
  );

  static const AtmospherePalette mistyTwilight = AtmospherePalette(
    id: 'mistyTwilight', nameZh: '淡墨暮岚', brightness: Brightness.light,
    ground: Color(0xFFD8D5CE), deskMat: Color(0xFFE6E3DC), deskTray: Color(0xFFDDDAD2),
    cardPaper: Color(0xFFF4F1EA), cardStackLip: Color(0xFFC9C4B9), agedFiberChip: Color(0xFFD1CEC6), deckleBorder: Color(0xFFBEB9AE),
    textPrimary: Color(0xFF2B2E33), textSecondary: Color(0xFF41454B), textMuted: Color(0xFF5A5F66), textFaint: Color(0xFF6F737A),
    accentPrimary: Color(0xFF6A7682), onAccentPrimary: Colors.white, accentPrimaryDark: Color(0xFF48525C), accentPrimaryWash: Color(0xFFDCE1E6),
    accentSecondary: Color(0xFFB08642), accentSecondaryDim: Color(0xFF94743E),
    sealAccent: Color(0xFFB55B52), sealAccentDark: Color(0xFF8E4139), sealAccentWash: Color(0xFFEDE0DE),
    chipActiveBg: Color(0x2E6A7682), chipActiveBorder: Color(0x8C6A7682), emeraldSaved: Color(0xFF059669),
    woodFrameDark: Color(0xFF45474A), woodFrameMid: Color(0xFF5B5D60), woodFrameHighlight: Color(0xFF7D7E80),
    headerTitleText: Color(0xFFF4F1EA), headerSubText: Color(0xFFC9C8C3),
    sillTop: Color(0xFF525457), sillBottom: Color(0xFF3B3D40), lipTop: Color(0xFF646669), lipBottom: Color(0xFF2D2E30),
    deskSurroundTop: Color(0xFFCFCBC2), deskSurroundBottom: Color(0xFFC7C3B9), candleGlow: Color.fromRGBO(255, 200, 110, 0.18),
    slipRuleColor: Color(0x146A7682), slipInnerFrameColor: Color(0x24B08642), slipDividerColor: Color(0x2B6A7682), slipShadowColor: Color(0x1A1E2024),
    spineCordTop: Color(0xFF6A7682),
    scrubberRailStops: [
      Color(0xFF5F6E7D), Color(0xFF72808C), Color(0xFF848B88), Color(0xFF9E875E), Color(0xFFB08642),
    ],
    tallyBgTop: Color(0xFFF4F1EA), tallyBgBottom: Color(0xFFDEDAD0), tallyBorder: Color(0xFFB4B0A6),
    tallyFeaturedTop: Color(0xFF5F6A75), tallyFeaturedBottom: Color(0xFF414A52), tallyFeaturedBorder: Color(0xFFC89B54),
    tallyFeaturedText: Color(0xFFF9F7F2), tallyFeaturedShadow: Color(0x4D414A52),
    silkMountBg: Color(0xFFE6E2D8), silkMountBorder: Color(0xFFB0ABA0), silkInnerFrame: Color(0xFF747068), silkMiterSeam: Color(0xFF948F84),
    blindSlatTop: Color(0xFFC8C4BA), blindSlatMid: Color(0xFFDBD7CE), blindSlatBottom: Color(0xFFB0ACA2), blindSlit: Color(0xFF7D7A72),
    blindRollerTop: Color(0xFF5B5D60), blindRollerMid: Color(0xFF45474A), blindRollerBottom: Color(0xFF2F3133),
    blindCordPrimary: Color(0xFF6A7682), blindCordSecondary: Color(0xFFC89B54), blindTagAccent: Color(0xFFC89B54),
    fabTop: Color(0xFF555D66), fabMid: Color(0xFF474E56), fabBottom: Color(0xFF3A4047),
    fabBorder: Color(0xFFC89B54), fabInnerBorder: Color(0x59EAE6DC), fabText: Color(0xFFF4F1EA),
    fabCapHighlight: Color(0xFFE0BE84), fabCapMid: Color(0xFFC89B54), fabCapDark: Color(0xFF2D3238), fabShadow: Color(0x663A4047),
  );

  static const AtmospherePalette yunhaoNight = AtmospherePalette(
    id: 'yunhaoNight', nameZh: '皓月夜', brightness: Brightness.dark,
    ground: Color(0xFF0E1520), deskMat: Color(0xFF141E2B), deskTray: Color(0xFF182332),
    cardPaper: Color(0xFF1B2738), cardStackLip: Color(0xFF27374D), agedFiberChip: Color(0xFF202E40), deckleBorder: Color(0xFF2D4057),
    textPrimary: Color(0xFFEEF2F6), textSecondary: Color(0xFFCBD6E2), textMuted: Color(0xFF9EB0C4), textFaint: Color(0xFF6D8299),
    accentPrimary: Color(0xFFF2B866), onAccentPrimary: Color(0xFF1A140B), accentPrimaryDark: Color(0xFFB88339), accentPrimaryWash: Color(0xFF2E2417),
    accentSecondary: Color(0xFFA8C0D6), accentSecondaryDim: Color(0xFF6E879E),
    sealAccent: Color(0xFFD16B62), sealAccentDark: Color(0xFFA84A42), sealAccentWash: Color(0xFF351F22),
    chipActiveBg: Color(0x2EF2B866), chipActiveBorder: Color(0x8CF2B866), emeraldSaved: Color(0xFF10B981),
    woodFrameDark: Color(0xFF0D1624), woodFrameMid: Color(0xFF152336), woodFrameHighlight: Color(0xFF2B425E),
    headerTitleText: Color(0xFFEEF2F6), headerSubText: Color(0xFF9EB0C4),
    sillTop: Color(0xFF18273B), sillBottom: Color(0xFF0D1522), lipTop: Color(0xFF223650), lipBottom: Color(0xFF090F1A),
    deskSurroundTop: Color(0xFF111B29), deskSurroundBottom: Color(0xFF0B121C), candleGlow: Color.fromRGBO(242, 184, 102, 0.16),
    slipRuleColor: Color(0x12A8C0D6), slipInnerFrameColor: Color(0x1CF2B866), slipDividerColor: Color(0x29A8C0D6), slipShadowColor: Color(0x52000000),
    spineCordTop: Color(0xFFF2B866),
    scrubberRailStops: [
      Color(0xFFE2BA78), Color(0xFFD8C292), Color(0xFFB3C3CE), Color(0xFF8CB0CC), Color(0xFF638BAB),
    ],
    tallyBgTop: Color(0xFF223044), tallyBgBottom: Color(0xFF16202F), tallyBorder: Color(0xFF2E425B),
    tallyFeaturedTop: Color(0xFF2B425F), tallyFeaturedBottom: Color(0xFF192A40), tallyFeaturedBorder: Color(0xFFF2B866),
    tallyFeaturedText: Color(0xFFFFF6E5), tallyFeaturedShadow: Color(0x5909111C),
    silkMountBg: Color(0xFFDCE4EC), silkMountBorder: Color(0xFF8EA4B8), silkInnerFrame: Color(0xFF5C7388), silkMiterSeam: Color(0xFF7B91A6),
    blindSlatTop: Color(0xFF1C2B3D), blindSlatMid: Color(0xFF293D54), blindSlatBottom: Color(0xFF14202E), blindSlit: Color(0xFF0B121B),
    blindRollerTop: Color(0xFF2B425E), blindRollerMid: Color(0xFF152336), blindRollerBottom: Color(0xFF0D1624),
    blindCordPrimary: Color(0xFFA8C0D6), blindCordSecondary: Color(0xFFF2B866), blindTagAccent: Color(0xFFF2B866),
    fabTop: Color(0xFF223752), fabMid: Color(0xFF1A2B42), fabBottom: Color(0xFF132133),
    fabBorder: Color(0xFFF2B866), fabInnerBorder: Color(0x52F2B866), fabText: Color(0xFFFFF6E5),
    fabCapHighlight: Color(0xFFF7D194), fabCapMid: Color(0xFFF2B866), fabCapDark: Color(0xFF121C2A), fabShadow: Color(0x8C060B12),
  );

  static const AtmospherePalette classicEbony = AtmospherePalette(
    id: 'classicEbony', nameZh: '碑拓乌木', brightness: Brightness.dark,
    ground: Color(0xFF181816), deskMat: Color(0xFF181816), deskTray: Color(0xFF211F1C),
    cardPaper: Color(0xFF242320), cardStackLip: Color(0xFF36332D), agedFiberChip: Color(0xFF2E2C28), deckleBorder: Color(0xFF3D3A34),
    textPrimary: Color(0xFFF0ECE3), textSecondary: Color(0xFFDCD6CA), textMuted: Color(0xFFA69F93), textFaint: Color(0xFF756E63),
    accentPrimary: Color(0xFFD25447), onAccentPrimary: Colors.white, accentPrimaryDark: Color(0xFFB83B2E), accentPrimaryWash: Color(0xFF381F1D),
    accentSecondary: Color(0xFFC8A96E), accentSecondaryDim: Color(0xFF7E6840),
    sealAccent: Color(0xFFD25447), sealAccentDark: Color(0xFFB83B2E), sealAccentWash: Color(0xFF381F1D),
    chipActiveBg: Color(0x33D25447), chipActiveBorder: Color(0x8CD25447), emeraldSaved: Color(0xFF10B981),
    woodFrameDark: Color(0xFF1C140F), woodFrameMid: Color(0xFF2D2018), woodFrameHighlight: Color(0xFF473325),
    headerTitleText: Color(0xFFF0ECE3), headerSubText: Color(0xFFB8AFA2),
    sillTop: Color(0xFF2C1E16), sillBottom: Color(0xFF19110C), lipTop: Color(0xFF3E2B1F), lipBottom: Color(0xFF140D09),
    deskSurroundTop: Color(0xFF1D150F), deskSurroundBottom: Color(0xFF120D09), candleGlow: Color.fromRGBO(255, 184, 77, 0.16),
    slipRuleColor: Color(0x11D25447), slipInnerFrameColor: Color(0x1CC8A96E), slipDividerColor: Color(0x29C8A96E), slipShadowColor: Color(0x52000000),
    spineCordTop: Color(0xFFD25447),
    scrubberRailStops: [
      Color(0xFFD4B478), Color(0xFFC29C63), Color(0xFFB57C5A), Color(0xFF9E6B5A), Color(0xFF8A7D6B),
    ],
    tallyBgTop: Color(0xFF2E2B27), tallyBgBottom: Color(0xFF1F1D1A), tallyBorder: Color(0xFF3D3A34),
    tallyFeaturedTop: Color(0xFFC23E30), tallyFeaturedBottom: Color(0xFFA42B1E), tallyFeaturedBorder: Color(0xFF6E180F),
    tallyFeaturedText: Colors.white, tallyFeaturedShadow: Color(0x59A82E21),
    silkMountBg: Color(0xFFE8DFCE), silkMountBorder: Color(0xFFB8A689), silkInnerFrame: Color(0xFF9A7B48), silkMiterSeam: Color(0xFF9C8B70),
    blindSlatTop: Color(0xFF4E3723), blindSlatMid: Color(0xFF684A30), blindSlatBottom: Color(0xFF3D2A1A), blindSlit: Color(0xEB0F0C09),
    blindRollerTop: Color(0xFF6E4E32), blindRollerMid: Color(0xFF3A2616), blindRollerBottom: Color(0xFF1E130A),
    blindCordPrimary: Color(0xFFD25447), blindCordSecondary: Color(0xFFDFC184), blindTagAccent: Color(0xFFE6C786),
    fabTop: Color(0xFF9E2E22), fabMid: Color(0xFF7A1F16), fabBottom: Color(0xFF5E150E),
    fabBorder: Color(0xFF8B6B3E), fabInnerBorder: Color(0x4DD25447), fabText: Color(0xFFFFF9F2),
    fabCapHighlight: Color(0xFFD9A962), fabCapMid: Color(0xFF8B6B3E), fabCapDark: Color(0xFF2B221B), fabShadow: Color(0x8C000000),
  );

  static const AtmospherePalette silveryRain = AtmospherePalette(
    id: 'silveryRain', nameZh: '清辉烟雨', brightness: Brightness.dark,
    ground: Color(0xFF111922), deskMat: Color(0xFF18232E), deskTray: Color(0xFF1C2936),
    cardPaper: Color(0xFF202E3B), cardStackLip: Color(0xFF2D3F50), agedFiberChip: Color(0xFF243442), deckleBorder: Color(0xFF34485B),
    textPrimary: Color(0xFFE6EEF5), textSecondary: Color(0xFFC5D5E3), textMuted: Color(0xFF9FB3C4), textFaint: Color(0xFF708596),
    accentPrimary: Color(0xFF8FB2C9), onAccentPrimary: Color(0xFF0E1720), accentPrimaryDark: Color(0xFF678CA3), accentPrimaryWash: Color(0xFF1D2F3E),
    accentSecondary: Color(0xFFE8C07D), accentSecondaryDim: Color(0xFF9E8254),
    sealAccent: Color(0xFFC9766E), sealAccentDark: Color(0xFF9E534C), sealAccentWash: Color(0xFF352326),
    chipActiveBg: Color(0x2E8FB2C9), chipActiveBorder: Color(0x8C8FB2C9), emeraldSaved: Color(0xFF10B981),
    woodFrameDark: Color(0xFF131D27), woodFrameMid: Color(0xFF1D2B38), woodFrameHighlight: Color(0xFF394F63),
    headerTitleText: Color(0xFFE6EEF5), headerSubText: Color(0xFF9FB3C4),
    sillTop: Color(0xFF21303F), sillBottom: Color(0xFF121C26), lipTop: Color(0xFF2E4154), lipBottom: Color(0xFF0D141C),
    deskSurroundTop: Color(0xFF151F2A), deskSurroundBottom: Color(0xFF0E151D), candleGlow: Color.fromRGBO(232, 192, 125, 0.16),
    slipRuleColor: Color(0x128FB2C9), slipInnerFrameColor: Color(0x1CE8C07D), slipDividerColor: Color(0x298FB2C9), slipShadowColor: Color(0x52000000),
    spineCordTop: Color(0xFF8FB2C9),
    scrubberRailStops: [
      Color(0xFF8FB2C9), Color(0xFF7FA8B4), Color(0xFF84ABA3), Color(0xFFB6BDAE), Color(0xFFDFC086),
    ],
    tallyBgTop: Color(0xFF253544), tallyBgBottom: Color(0xFF1A2632), tallyBorder: Color(0xFF34485B),
    tallyFeaturedTop: Color(0xFF334A5E), tallyFeaturedBottom: Color(0xFF203140), tallyFeaturedBorder: Color(0xFF8FB2C9),
    tallyFeaturedText: Color(0xFFEEF5FA), tallyFeaturedShadow: Color(0x590B131A),
    silkMountBg: Color(0xFFD8E2EA), silkMountBorder: Color(0xFF7F97AB), silkInnerFrame: Color(0xFF536C80), silkMiterSeam: Color(0xFF70889C),
    blindSlatTop: Color(0xFF243340), blindSlatMid: Color(0xFF324557), blindSlatBottom: Color(0xFF19242E), blindSlit: Color(0xFF0F161D),
    blindRollerTop: Color(0xFF394F63), blindRollerMid: Color(0xFF1D2B38), blindRollerBottom: Color(0xFF131D27),
    blindCordPrimary: Color(0xFF8FB2C9), blindCordSecondary: Color(0xFFE8C07D), blindTagAccent: Color(0xFFE8C07D),
    fabTop: Color(0xFF2D4254), fabMid: Color(0xFF233544), fabBottom: Color(0xFF1A2835),
    fabBorder: Color(0xFF8FB2C9), fabInnerBorder: Color(0x528FB2C9), fabText: Color(0xFFEEF5FA),
    fabCapHighlight: Color(0xFFBDD5E5), fabCapMid: Color(0xFF8FB2C9), fabCapDark: Color(0xFF16222E), fabShadow: Color(0x8C080E14),
  );

  static const AtmospherePalette blossomLantern = AtmospherePalette(
    id: 'blossomLantern', nameZh: '花影灯火', brightness: Brightness.dark,
    ground: Color(0xFF0D1B1E), deskMat: Color(0xFF13262A), deskTray: Color(0xFF172D32),
    cardPaper: Color(0xFF1A3136), cardStackLip: Color(0xFF26434A), agedFiberChip: Color(0xFF1F393F), deckleBorder: Color(0xFF2D4E55),
    textPrimary: Color(0xFFF7ECE8), textSecondary: Color(0xFFD8CECB), textMuted: Color(0xFFB3C2C2), textFaint: Color(0xFF7A9496),
    accentPrimary: Color(0xFFE89AA4), onAccentPrimary: Color(0xFF261015), accentPrimaryDark: Color(0xFFC2747F), accentPrimaryWash: Color(0xFF352329),
    accentSecondary: Color(0xFFF4B860), accentSecondaryDim: Color(0xFFA87D3D),
    sealAccent: Color(0xFFD9685B), sealAccentDark: Color(0xFFAB493E), sealAccentWash: Color(0xFF382022),
    chipActiveBg: Color(0x2EE89AA4), chipActiveBorder: Color(0x8CE89AA4), emeraldSaved: Color(0xFF10B981),
    woodFrameDark: Color(0xFF132225), woodFrameMid: Color(0xFF1B3034), woodFrameHighlight: Color(0xFF35595F),
    headerTitleText: Color(0xFFF7ECE8), headerSubText: Color(0xFFB3C2C2),
    sillTop: Color(0xFF1D3439), sillBottom: Color(0xFF101F22), lipTop: Color(0xFF28454B), lipBottom: Color(0xFF0B1618),
    deskSurroundTop: Color(0xFF102023), deskSurroundBottom: Color(0xFF0A1618), candleGlow: Color.fromRGBO(244, 184, 96, 0.18),
    slipRuleColor: Color(0x14E89AA4), slipInnerFrameColor: Color(0x1FF4B860), slipDividerColor: Color(0x29E89AA4), slipShadowColor: Color(0x52000000),
    spineCordTop: Color(0xFFE89AA4),
    scrubberRailStops: [
      Color(0xFFE89AA4), Color(0xFFE2AF8E), Color(0xFFE2BC7E), Color(0xFF9CC0B4), Color(0xFF6FA0A6),
    ],
    tallyBgTop: Color(0xFF213B41), tallyBgBottom: Color(0xFF16292E), tallyBorder: Color(0xFF2D4E55),
    tallyFeaturedTop: Color(0xFFC76975), tallyFeaturedBottom: Color(0xFF873E49), tallyFeaturedBorder: Color(0xFFF5B5BE),
    tallyFeaturedText: Color(0xFFFFF8F7), tallyFeaturedShadow: Color(0x594D1E25),
    silkMountBg: Color(0xFFEFE3DF), silkMountBorder: Color(0xFFC49D98), silkInnerFrame: Color(0xFF8D6662), silkMiterSeam: Color(0xFFA8827D),
    blindSlatTop: Color(0xFF1C353B), blindSlatMid: Color(0xFF284952), blindSlatBottom: Color(0xFF13252A), blindSlit: Color(0xFF0A171B),
    blindRollerTop: Color(0xFF35595F), blindRollerMid: Color(0xFF1B3034), blindRollerBottom: Color(0xFF132225),
    blindCordPrimary: Color(0xFFE89AA4), blindCordSecondary: Color(0xFFF4B860), blindTagAccent: Color(0xFFF4B860),
    fabTop: Color(0xFF9C4A55), fabMid: Color(0xFF833C46), fabBottom: Color(0xFF6B2E37),
    fabBorder: Color(0xFFF4B860), fabInnerBorder: Color(0x52F5B5BE), fabText: Color(0xFFFFF8F7),
    fabCapHighlight: Color(0xFFF8D08B), fabCapMid: Color(0xFFF4B860), fabCapDark: Color(0xFF2A191D), fabShadow: Color(0x8C0A1517),
  );

  /// Looks up the [AtmospherePalette] for a Light palette ID.
  static AtmospherePalette forLight(LightAtmospherePaletteId id) {
    switch (id) {
      case LightAtmospherePaletteId.yunhaoDay:
        return yunhaoDay;
      case LightAtmospherePaletteId.classicWalnut:
        return classicWalnut;
      case LightAtmospherePaletteId.mistyTwilight:
        return mistyTwilight;
    }
  }

  /// Looks up the [AtmospherePalette] for a Dark palette ID.
  static AtmospherePalette forDark(DarkAtmospherePaletteId id) {
    switch (id) {
      case DarkAtmospherePaletteId.yunhaoNight:
        return yunhaoNight;
      case DarkAtmospherePaletteId.classicEbony:
        return classicEbony;
      case DarkAtmospherePaletteId.silveryRain:
        return silveryRain;
      case DarkAtmospherePaletteId.blossomLantern:
        return blossomLantern;
    }
  }
}
