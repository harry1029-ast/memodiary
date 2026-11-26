import 'package:flutter/material.dart';
import 'atmosphere_palette.dart';
import 'atmosphere_palettes.dart';
import 'atmosphere_theme_models.dart';

/// Semantic ink & Xuan paper design tokens embodying classical Chinese literati aesthetics.
@immutable
class InkDiaryTokens {
  // Ground & Paper Foundation
  final Color xuanGround;
  final Color xuanPureLeaf;
  final Color agedFiber;
  final Color deckleBorder;

  // Ink Spectrum
  final Color jiaomo; // 焦墨 (Deep Ink)
  final Color nongmo; // 浓墨 (Concentrated Ink)
  final Color danmo; // 淡墨 (Diluted Ink Wash)
  final Color qingmo; // 清墨 (Faint Water Tint)

  // Interactive Primary Accent
  final Color cinnabar;
  final Color cinnabarWash;
  final Color cinnabarDark;
  final Color onAccentPrimary;

  // Precious Seal Cinnabar (Reserved strictly for stamps & seals)
  final Color sealCinnabar;
  final Color sealCinnabarWash;
  final Color sealCinnabarDark;

  // Functional Status
  final Color emeraldSaved;

  const InkDiaryTokens({
    required this.xuanGround,
    required this.xuanPureLeaf,
    required this.agedFiber,
    required this.deckleBorder,
    required this.jiaomo,
    required this.nongmo,
    required this.danmo,
    required this.qingmo,
    required this.cinnabar,
    required this.cinnabarWash,
    required this.cinnabarDark,
    this.onAccentPrimary = Colors.white,
    this.sealCinnabar = const Color(0xFFC24D43),
    this.sealCinnabarWash = const Color(0xFFF5E5E3),
    this.sealCinnabarDark = const Color(0xFF9A3830),
    required this.emeraldSaved,
  });

  /// Derives semantic tokens from an [AtmospherePalette].
  factory InkDiaryTokens.fromAtmosphere(AtmospherePalette palette) {
    return InkDiaryTokens(
      xuanGround: palette.ground,
      xuanPureLeaf: palette.cardPaper,
      agedFiber: palette.agedFiberChip,
      deckleBorder: palette.deckleBorder,
      jiaomo: palette.textPrimary,
      nongmo: palette.textSecondary,
      danmo: palette.textMuted,
      qingmo: palette.textFaint,
      cinnabar: palette.accentPrimary,
      cinnabarWash: palette.accentPrimaryWash,
      cinnabarDark: palette.accentPrimaryDark,
      onAccentPrimary: palette.onAccentPrimary,
      sealCinnabar: palette.sealAccent,
      sealCinnabarWash: palette.sealAccentWash,
      sealCinnabarDark: palette.sealAccentDark,
      emeraldSaved: palette.emeraldSaved,
    );
  }

  /// Alias for the primary paper background ground.
  Color get ricePaper => xuanGround;

  /// Light theme default tokens (`云岚昼`).
  static final light = InkDiaryTokens.fromAtmosphere(AtmospherePalettes.yunhaoDay);

  /// Dark theme default tokens (`皓月夜`).
  static final dark = InkDiaryTokens.fromAtmosphere(AtmospherePalettes.yunhaoNight);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InkDiaryTokens &&
            runtimeType == other.runtimeType &&
            xuanGround == other.xuanGround && xuanPureLeaf == other.xuanPureLeaf &&
            agedFiber == other.agedFiber && deckleBorder == other.deckleBorder &&
            jiaomo == other.jiaomo && nongmo == other.nongmo &&
            danmo == other.danmo && qingmo == other.qingmo &&
            cinnabar == other.cinnabar && cinnabarWash == other.cinnabarWash &&
            cinnabarDark == other.cinnabarDark && onAccentPrimary == other.onAccentPrimary &&
            sealCinnabar == other.sealCinnabar && sealCinnabarWash == other.sealCinnabarWash &&
            sealCinnabarDark == other.sealCinnabarDark && emeraldSaved == other.emeraldSaved;
  }

  @override
  int get hashCode => Object.hash(
        xuanGround, xuanPureLeaf, agedFiber, deckleBorder,
        jiaomo, nongmo, danmo, qingmo,
        cinnabar, cinnabarWash, cinnabarDark, onAccentPrimary,
        sealCinnabar, sealCinnabarWash, sealCinnabarDark, emeraldSaved,
      );
}

/// Convenience extension on [BuildContext] to access [InkDiaryTokens] directly.
extension InkDiaryContext on BuildContext {
  InkDiaryTokens get inkTokens => InkDiaryTokens.fromAtmosphere(atmospherePalette);
}

/// Comprehensive [ThemeData] builder for 云皓日记 (MemoDiary).
class InkDiaryTheme {
  static const String fontNotoSerif = 'Noto Serif SC';
  static const String fontLiterata = 'Literata';
  static const String fontKaiti = 'Kaiti SC';
  static const String fontMaShanZheng = 'Ma Shan Zheng';

  /// Convenience lookup for current [InkDiaryTokens] in [context].
  static InkDiaryTokens tokensOf(BuildContext context) => context.inkTokens;

  /// Default light theme (`云岚昼`).
  static ThemeData get light => forLightPalette(LightAtmospherePaletteId.yunhaoDay);

  /// Default dark theme (`皓月夜`).
  static ThemeData get dark => forDarkPalette(DarkAtmospherePaletteId.yunhaoNight);

  /// Builds a light [ThemeData] from the chosen [LightAtmospherePaletteId].
  static ThemeData forLightPalette(LightAtmospherePaletteId paletteId) =>
      forAtmosphere(AtmospherePalettes.forLight(paletteId));

  /// Builds a dark [ThemeData] from the chosen [DarkAtmospherePaletteId].
  static ThemeData forDarkPalette(DarkAtmospherePaletteId paletteId) =>
      forAtmosphere(AtmospherePalettes.forDark(paletteId));

  /// Builds a full [ThemeData] attaching both [InkDiaryTokens] and [AtmospherePalette].
  static ThemeData forAtmosphere(AtmospherePalette palette) {
    final tokens = InkDiaryTokens.fromAtmosphere(palette);
    final colorScheme = _buildColorScheme(palette, tokens);
    return _buildTheme(colorScheme, tokens, palette);
  }

  static ColorScheme _buildColorScheme(
    AtmospherePalette palette,
    InkDiaryTokens tokens,
  ) {
    final isDark = palette.brightness == Brightness.dark;
    return ColorScheme(
      brightness: palette.brightness,
      primary: tokens.jiaomo,
      onPrimary: tokens.xuanGround,
      primaryContainer: tokens.nongmo,
      onPrimaryContainer: tokens.xuanPureLeaf,
      secondary: tokens.cinnabar,
      onSecondary: tokens.onAccentPrimary,
      secondaryContainer: tokens.cinnabarWash,
      onSecondaryContainer: isDark
          ? Color.lerp(tokens.cinnabar, Colors.white, 0.72)!
          : tokens.cinnabarDark,
      tertiary: tokens.danmo,
      onTertiary: isDark ? Colors.black : Colors.white,
      surface: tokens.xuanGround,
      onSurface: tokens.jiaomo,
      surfaceDim: isDark
          ? Color.lerp(tokens.xuanGround, Colors.black, 0.25)!
          : Color.lerp(tokens.xuanGround, tokens.deckleBorder, 0.55)!,
      surfaceBright: tokens.xuanGround,
      surfaceContainerLowest: isDark
          ? Color.lerp(tokens.xuanGround, palette.deskMat, 0.4)!
          : tokens.xuanPureLeaf,
      surfaceContainerLow: isDark
          ? palette.deskMat
          : Color.lerp(tokens.xuanGround, palette.deskMat, 0.45)!,
      surfaceContainer: isDark ? tokens.xuanPureLeaf : palette.deskMat,
      surfaceContainerHigh: isDark ? tokens.agedFiber : palette.deskTray,
      surfaceContainerHighest: isDark ? tokens.deckleBorder : tokens.agedFiber,
      onSurfaceVariant: tokens.danmo,
      outline: tokens.qingmo,
      outlineVariant: tokens.deckleBorder,
      error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
      onError: isDark ? const Color(0xFF690005) : Colors.white,
      errorContainer: isDark ? const Color(0xFF93000A) : const Color(0xFFFFDAD6),
      onErrorContainer: isDark ? const Color(0xFFFFDAD6) : const Color(0xFF93000A),
    );
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    InkDiaryTokens tokens,
    AtmospherePalette palette,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [palette],
      fontFamily: fontNotoSerif,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontNotoSerif,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.deckleBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.deckleBorder, width: 1),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontNotoSerif,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        modalBackgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.jiaomo,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: fontNotoSerif,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: tokens.deckleBorder, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: fontNotoSerif,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontFamily: fontNotoSerif,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.cinnabar,
        foregroundColor: tokens.onAccentPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.deckleBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.deckleBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.jiaomo, width: 1.5),
        ),
        hintStyle: TextStyle(color: tokens.qingmo, fontFamily: fontNotoSerif, fontSize: 14),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.deckleBorder.withValues(alpha: 0.6),
        thickness: 0.8,
        space: 1,
      ),
      textTheme: _buildTextTheme(colorScheme, tokens),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme, InkDiaryTokens tokens) {
    TextStyle style(
      String family,
      double size,
      FontWeight weight,
      double height,
      double spacing,
      Color color,
    ) =>
        TextStyle(
          fontFamily: family,
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
          color: color,
        );
    final primary = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    return TextTheme(
      displayLarge: style(fontNotoSerif, 32, FontWeight.w400, 1.38, 0.4, primary),
      headlineLarge: style(fontNotoSerif, 26, FontWeight.w500, 1.38, 0.2, primary),
      headlineMedium: style(fontNotoSerif, 20, FontWeight.w500, 1.5, 0.15, primary),
      headlineSmall: style(fontNotoSerif, 17, FontWeight.w600, 1.53, 0.1, primary),
      bodyLarge: style(fontLiterata, 18, FontWeight.w400, 1.78, 0.15, primary),
      bodyMedium: style(fontLiterata, 16, FontWeight.w400, 1.75, 0.1, primary),
      bodySmall: style(fontLiterata, 14, FontWeight.w400, 1.71, 0.05, muted),
      labelLarge: style(fontNotoSerif, 14, FontWeight.w500, 1.43, 0.8, primary),
      labelMedium: style(fontNotoSerif, 12, FontWeight.w500, 1.5, 1.0, muted),
      labelSmall: style(fontNotoSerif, 10, FontWeight.w600, 1.4, 1.4, tokens.qingmo),
    );
  }
}
