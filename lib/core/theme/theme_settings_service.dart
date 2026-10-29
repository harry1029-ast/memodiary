import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service managing persistent user preferences for the app's theme appearance
/// (System Default, Light / Xuan Paper, Dark / Deep Ink).
class ThemeSettingsService {
  static const String _keyThemeMode = 'memodiary_theme_mode';
  final FlutterSecureStorage _storage;

  /// Shared singleton instance for convenient app-wide access.
  static final ThemeSettingsService instance = ThemeSettingsService();

  /// Reactive notifier holding the current active [ThemeMode], listened to by [MaterialApp].
  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  ThemeSettingsService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Loads the persisted theme mode from secure storage and updates [themeModeNotifier].
  /// Defaults to [ThemeMode.system] if unset or if reading fails.
  Future<ThemeMode> getThemeMode() async {
    try {
      final value = await _storage.read(key: _keyThemeMode);
      final mode = parseThemeMode(value);
      themeModeNotifier.value = mode;
      return mode;
    } catch (_) {
      themeModeNotifier.value = ThemeMode.system;
      return ThemeMode.system;
    }
  }

  /// Sets and persists a new [ThemeMode], synchronously updating [themeModeNotifier].
  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      await _storage.write(
        key: _keyThemeMode,
        value: serializeThemeMode(mode),
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
    description: '随系统明暗自动切换，契合昼夜节律',
    icon: Icons.brightness_auto_outlined,
    filledIcon: Icons.brightness_auto_rounded,
  ),
  ThemeMode.light: _ThemeModePresentation(
    label: '素宣浅色',
    subtitle: 'Light',
    description: '常驻素白宣纸质感，温润清朗',
    icon: Icons.light_mode_outlined,
    filledIcon: Icons.light_mode_rounded,
  ),
  ThemeMode.dark: _ThemeModePresentation(
    label: '焦墨深色',
    subtitle: 'Dark',
    description: '常驻静谧焦墨夜巡，护眼沉静',
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

