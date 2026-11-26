import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'atmosphere_theme_models.dart';

/// Service managing persistent user preferences for the two-axis Atmosphere
/// Theme system (`外观模式` × `主题风格` + independent custom Light/Dark palettes).
class ThemeSettingsService {
  static const String _keyThemeMode = 'memodiary_theme_mode';
  static const String _keyAtmospherePreset = 'memodiary_atmosphere_preset';
  static const String _keyCustomLightPalette = 'memodiary_custom_light_palette';
  static const String _keyCustomDarkPalette = 'memodiary_custom_dark_palette';

  final FlutterSecureStorage _storage;

  /// Shared singleton instance for convenient app-wide access.
  static final ThemeSettingsService instance = ThemeSettingsService();

  /// Reactive notifier holding the unified two-axis [AtmosphereThemeConfig].
  final ValueNotifier<AtmosphereThemeConfig> configNotifier =
      ValueNotifier<AtmosphereThemeConfig>(const AtmosphereThemeConfig());

  ThemeSettingsService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Loads all four persisted theme keys and synchronizes [configNotifier].
  Future<AtmosphereThemeConfig> loadPreferences() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _keyThemeMode),
        _storage.read(key: _keyAtmospherePreset),
        _storage.read(key: _keyCustomLightPalette),
        _storage.read(key: _keyCustomDarkPalette),
      ]);
      final config = AtmosphereThemeConfig(
        themeMode: parseThemeMode(results[0]),
        preset: AtmosphereThemePreset.parse(results[1]),
        customLightPalette: LightAtmospherePaletteId.parse(results[2]),
        customDarkPalette: DarkAtmospherePaletteId.parse(results[3]),
      );
      configNotifier.value = config;
      return config;
    } catch (_) {
      const fallback = AtmosphereThemeConfig();
      configNotifier.value = fallback;
      return fallback;
    }
  }

  /// Loads the persisted theme mode from secure storage and updates [configNotifier].
  /// Defaults to [ThemeMode.system] if unset or if reading fails.
  Future<ThemeMode> getThemeMode() async {
    try {
      final value = await _storage.read(key: _keyThemeMode);
      final mode = parseThemeMode(value);
      configNotifier.value = configNotifier.value.copyWith(themeMode: mode);
      return mode;
    } catch (_) {
      configNotifier.value = configNotifier.value.copyWith(themeMode: ThemeMode.system);
      return ThemeMode.system;
    }
  }

  /// Sets and persists a new [ThemeMode], synchronously updating [configNotifier].
  Future<void> setThemeMode(ThemeMode mode) async {
    configNotifier.value = configNotifier.value.copyWith(themeMode: mode);
    try {
      await _storage.write(
        key: _keyThemeMode,
        value: serializeThemeMode(mode),
      );
    } catch (_) {
      // Gracefully handle storage write errors
    }
  }

  /// Sets and persists the active [AtmosphereThemePreset] without altering stored
  /// custom Light or Dark palette keys.
  Future<void> setPreset(AtmosphereThemePreset preset) async {
    configNotifier.value = configNotifier.value.copyWith(preset: preset);
    try {
      await _storage.write(
        key: _keyAtmospherePreset,
        value: preset.storageKey,
      );
    } catch (_) {
      // Gracefully handle storage write errors
    }
  }

  /// Sets and persists the custom Light [AtmospherePalette] selection.
  Future<void> setCustomLightPalette(LightAtmospherePaletteId paletteId) async {
    configNotifier.value = configNotifier.value.copyWith(customLightPalette: paletteId);
    try {
      await _storage.write(
        key: _keyCustomLightPalette,
        value: paletteId.storageKey,
      );
    } catch (_) {
      // Gracefully handle storage write errors
    }
  }

  /// Sets and persists the custom Dark [AtmospherePalette] selection.
  Future<void> setCustomDarkPalette(DarkAtmospherePaletteId paletteId) async {
    configNotifier.value = configNotifier.value.copyWith(customDarkPalette: paletteId);
    try {
      await _storage.write(
        key: _keyCustomDarkPalette,
        value: paletteId.storageKey,
      );
    } catch (_) {
      // Gracefully handle storage write errors
    }
  }

  /// Parses a string into a [ThemeMode].
  static ThemeMode parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Serializes a [ThemeMode] into a persistence-safe string.
  static String serializeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

class _ThemeModePresentation {
  final String label;
  final String subtitle;
  final String description;
  final IconData icon;
  final IconData filledIcon;

  const _ThemeModePresentation({
    required this.label,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.filledIcon,
  });
}

const _kThemeModePresentations = <ThemeMode, _ThemeModePresentation>{
  ThemeMode.system: _ThemeModePresentation(
    label: '跟随系统',
    subtitle: 'Auto',
    description: '随系统外观自动切换浅色或深色',
    icon: Icons.brightness_auto_outlined,
    filledIcon: Icons.brightness_auto_rounded,
  ),
  ThemeMode.light: _ThemeModePresentation(
    label: '浅色模式',
    subtitle: 'Light',
    description: '始终使用浅色外观',
    icon: Icons.light_mode_outlined,
    filledIcon: Icons.light_mode_rounded,
  ),
  ThemeMode.dark: _ThemeModePresentation(
    label: '深色模式',
    subtitle: 'Dark',
    description: '始终使用深色外观',
    icon: Icons.dark_mode_outlined,
    filledIcon: Icons.dark_mode_rounded,
  ),
};

/// Classical literati presentation metadata for [ThemeMode].
extension ThemeModePresentationX on ThemeMode {
  _ThemeModePresentation get _presentation => _kThemeModePresentations[this]!;

  String get label => _presentation.label;
  String get subtitle => _presentation.subtitle;
  String get description => _presentation.description;
  IconData get icon => _presentation.icon;
  IconData get filledIcon => _presentation.filledIcon;
}
