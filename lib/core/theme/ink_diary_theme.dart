import 'package:flutter/material.dart';

/// Semantic ink & Xuan paper design tokens embodying classical Chinese literati aesthetics.
/// Derived from `.stitch/DESIGN.md` (Ink & Paper Journal).
@immutable
class InkDiaryTokens extends ThemeExtension<InkDiaryTokens> {
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

  // Cinnabar Accent (The Seal Stamp)
  final Color cinnabar;
  final Color cinnabarWash;
  final Color cinnabarDark;

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
    required this.emeraldSaved,
  });

  /// Alias for the primary warm rice paper background ground
  Color get ricePaper => xuanGround;

  /// Light theme default tokens
  static const light = InkDiaryTokens(
    xuanGround: Color(0xFFFCF9F2),
    xuanPureLeaf: Color(0xFFFFFFFF),
    agedFiber: Color(0xFFEFE9DC),
    deckleBorder: Color(0xFFD8D1C3),
    jiaomo: Color(0xFF1E1E1E),
    nongmo: Color(0xFF2D2D2D),
    danmo: Color(0xFF68645E),
    qingmo: Color(0xFF9E998F),
    cinnabar: Color(0xFFB83B2E),
    cinnabarWash: Color(0xFFF3E5E3),
    cinnabarDark: Color(0xFF982B1F),
    emeraldSaved: Color(0xFF059669),
  );

  /// Dark theme (Inverted stone rubbings & night desk)
  static const dark = InkDiaryTokens(
    xuanGround: Color(0xFF181816),
    xuanPureLeaf: Color(0xFF242320),
    agedFiber: Color(0xFF2E2C28),
    deckleBorder: Color(0xFF3D3A34),
    jiaomo: Color(0xFFF0ECE3),
    nongmo: Color(0xFFDCD6CA),
    danmo: Color(0xFFA69F93),
    qingmo: Color(0xFF6E6960),
    cinnabar: Color(0xFFD25447),
    cinnabarWash: Color(0xFF381F1D),
    cinnabarDark: Color(0xFFB83B2E),
    emeraldSaved: Color(0xFF10B981),
  );

  @override
  InkDiaryTokens copyWith({
    Color? xuanGround,
    Color? xuanPureLeaf,
    Color? agedFiber,
    Color? deckleBorder,
    Color? jiaomo,
    Color? nongmo,
    Color? danmo,
    Color? qingmo,
    Color? cinnabar,
    Color? cinnabarWash,
    Color? cinnabarDark,
    Color? emeraldSaved,
  }) {
    return InkDiaryTokens(
      xuanGround: xuanGround ?? this.xuanGround,
      xuanPureLeaf: xuanPureLeaf ?? this.xuanPureLeaf,
      agedFiber: agedFiber ?? this.agedFiber,
      deckleBorder: deckleBorder ?? this.deckleBorder,
      jiaomo: jiaomo ?? this.jiaomo,
      nongmo: nongmo ?? this.nongmo,
      danmo: danmo ?? this.danmo,
      qingmo: qingmo ?? this.qingmo,
      cinnabar: cinnabar ?? this.cinnabar,
      cinnabarWash: cinnabarWash ?? this.cinnabarWash,
      cinnabarDark: cinnabarDark ?? this.cinnabarDark,
      emeraldSaved: emeraldSaved ?? this.emeraldSaved,
    );
  }

  @override
  InkDiaryTokens lerp(ThemeExtension<InkDiaryTokens>? other, double t) {
    if (other is! InkDiaryTokens) return this;
    return InkDiaryTokens(
      xuanGround: Color.lerp(xuanGround, other.xuanGround, t)!,
      xuanPureLeaf: Color.lerp(xuanPureLeaf, other.xuanPureLeaf, t)!,
      agedFiber: Color.lerp(agedFiber, other.agedFiber, t)!,
      deckleBorder: Color.lerp(deckleBorder, other.deckleBorder, t)!,
      jiaomo: Color.lerp(jiaomo, other.jiaomo, t)!,
      nongmo: Color.lerp(nongmo, other.nongmo, t)!,
      danmo: Color.lerp(danmo, other.danmo, t)!,
      qingmo: Color.lerp(qingmo, other.qingmo, t)!,
      cinnabar: Color.lerp(cinnabar, other.cinnabar, t)!,
      cinnabarWash: Color.lerp(cinnabarWash, other.cinnabarWash, t)!,
      cinnabarDark: Color.lerp(cinnabarDark, other.cinnabarDark, t)!,
      emeraldSaved: Color.lerp(emeraldSaved, other.emeraldSaved, t)!,
    );
  }
}

/// Convenience extension on [BuildContext] to access [InkDiaryTokens] directly
extension InkDiaryContext on BuildContext {
  InkDiaryTokens get inkTokens =>
      Theme.of(this).extension<InkDiaryTokens>() ?? InkDiaryTokens.light;
}

/// Comprehensive ThemeData implementation for MemoDiary (Ink & Paper Journal)
class InkDiaryTheme {
  static const String fontNotoSerif = 'Noto Serif SC';
  static const String fontLiterata = 'Literata';
  static const String fontKaiti = 'Kaiti SC';
  static const String fontMaShanZheng = 'Ma Shan Zheng';

  /// Convenience lookup for current [InkDiaryTokens] in [context].
  static InkDiaryTokens tokensOf(BuildContext context) =>
      Theme.of(context).extension<InkDiaryTokens>() ?? InkDiaryTokens.light;

  /// Primary light theme
  static ThemeData get light {
    final tokens = InkDiaryTokens.light;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: tokens.jiaomo,
      onPrimary: tokens.xuanGround,
      primaryContainer: tokens.nongmo,
      onPrimaryContainer: tokens.xuanPureLeaf,
      secondary: tokens.cinnabar,
      onSecondary: Colors.white,
      secondaryContainer: tokens.cinnabarWash,
      onSecondaryContainer: tokens.cinnabarDark,
      tertiary: tokens.danmo,
      onTertiary: Colors.white,
      surface: tokens.xuanGround,
      onSurface: tokens.jiaomo,
      surfaceDim: const Color(0xFFDCDAD3),
      surfaceBright: tokens.xuanGround,
      surfaceContainerLowest: tokens.xuanPureLeaf,
      surfaceContainerLow: const Color(0xFFF6F3EC),
      surfaceContainer: const Color(0xFFF1EEE7),
      surfaceContainerHigh: const Color(0xFFEBE8E1),
      surfaceContainerHighest: const Color(0xFFE5E2DB),
      onSurfaceVariant: tokens.danmo,
      outline: tokens.qingmo,
      outlineVariant: tokens.deckleBorder,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF93000A),
    );

    return _buildTheme(colorScheme, tokens);
  }

  /// Meditative dark theme
  static ThemeData get dark {
    final tokens = InkDiaryTokens.dark;

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: tokens.jiaomo,
      onPrimary: tokens.xuanGround,
      primaryContainer: tokens.nongmo,
      onPrimaryContainer: tokens.xuanPureLeaf,
      secondary: tokens.cinnabar,
      onSecondary: Colors.white,
      secondaryContainer: tokens.cinnabarWash,
      onSecondaryContainer: const Color(0xFFFFDAD5),
      tertiary: tokens.danmo,
      onTertiary: Colors.black,
      surface: tokens.xuanGround,
      onSurface: tokens.jiaomo,
      surfaceDim: const Color(0xFF141412),
      surfaceBright: tokens.xuanGround,
      surfaceContainerLowest: const Color(0xFF1C1C19),
      surfaceContainerLow: const Color(0xFF21201D),
      surfaceContainer: tokens.xuanPureLeaf,
      surfaceContainerHigh: tokens.agedFiber,
      surfaceContainerHighest: tokens.deckleBorder,
      onSurfaceVariant: tokens.danmo,
      outline: tokens.qingmo,
      outlineVariant: tokens.deckleBorder,
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
    );

    return _buildTheme(colorScheme, tokens);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, InkDiaryTokens tokens) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [tokens],
      fontFamily: fontNotoSerif,

      // App Bar styling
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
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 22,
        ),
      ),

      // Card styling with deckle paper border
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: tokens.deckleBorder,
            width: 1,
          ),
        ),
      ),

      // Dialog styling
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

      // Bottom Sheet styling
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        modalBackgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.jiaomo,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.cinnabar,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input Decoration
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
        hintStyle: TextStyle(
          color: tokens.qingmo,
          fontFamily: fontNotoSerif,
          fontSize: 14,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: tokens.deckleBorder.withValues(alpha: 0.6),
        thickness: 0.8,
        space: 1,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontNotoSerif,
          fontSize: 32,
          fontWeight: FontWeight.w400,
          height: 1.38,
          letterSpacing: 0.4,
          color: colorScheme.onSurface,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontNotoSerif,
          fontSize: 26,
          fontWeight: FontWeight.w500,
          height: 1.38,
          letterSpacing: 0.2,
          color: colorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontNotoSerif,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 1.5,
          letterSpacing: 0.15,
          color: colorScheme.onSurface,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontNotoSerif,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.53,
          letterSpacing: 0.1,
          color: colorScheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontLiterata,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.78,
          letterSpacing: 0.15,
          color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontLiterata,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.75,
          letterSpacing: 0.1,
          color: colorScheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontFamily: fontLiterata,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.71,
          letterSpacing: 0.05,
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontFamily: fontNotoSerif,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.43,
          letterSpacing: 0.8,
          color: colorScheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontFamily: fontNotoSerif,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.5,
          letterSpacing: 1.0,
          color: colorScheme.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontFamily: fontNotoSerif,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 1.4,
          color: tokens.qingmo,
        ),
      ),
    );
  }
}
