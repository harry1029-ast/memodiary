import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/atmosphere_palettes.dart';
import 'package:memodiary/core/theme/atmosphere_theme_models.dart';
import 'package:memodiary/core/theme/theme_settings_service.dart';
import '../../helpers/mock_secure_storage.dart';

void main() {
  group('ThemeSettingsService Tests', () {
    late MockSecureStorage mockStorage;
    late ThemeSettingsService service;

    setUp(() {
      mockStorage = MockSecureStorage();
      service = ThemeSettingsService(storage: mockStorage);
    });

    test('defaults to ThemeMode.system when no preference is saved', () async {
      expect(await service.getThemeMode(), equals(ThemeMode.system));
      expect(service.themeModeNotifier.value, equals(ThemeMode.system));
    });

    test('persists and retrieves ThemeMode.light', () async {
      await service.setThemeMode(ThemeMode.light);
      expect(service.themeModeNotifier.value, equals(ThemeMode.light));

      final retrieved = await service.getThemeMode();
      expect(retrieved, equals(ThemeMode.light));
      expect(mockStorage.data['memodiary_theme_mode'], equals('light'));
    });

    test('persists and retrieves ThemeMode.dark', () async {
      await service.setThemeMode(ThemeMode.dark);
      expect(service.themeModeNotifier.value, equals(ThemeMode.dark));

      final retrieved = await service.getThemeMode();
      expect(retrieved, equals(ThemeMode.dark));
      expect(mockStorage.data['memodiary_theme_mode'], equals('dark'));
    });

    test('reverts to ThemeMode.system and updates notifier', () async {
      await service.setThemeMode(ThemeMode.dark);
      expect(service.themeModeNotifier.value, equals(ThemeMode.dark));

      await service.setThemeMode(ThemeMode.system);
      expect(service.themeModeNotifier.value, equals(ThemeMode.system));

      final retrieved = await service.getThemeMode();
      expect(retrieved, equals(ThemeMode.system));
      expect(mockStorage.data['memodiary_theme_mode'], equals('system'));
    });

    test('parses unknown or corrupted storage values safely as ThemeMode.system', () {
      expect(ThemeSettingsService.parseThemeMode('invalid_string'), equals(ThemeMode.system));
      expect(ThemeSettingsService.parseThemeMode(null), equals(ThemeMode.system));
      expect(ThemeSettingsService.parseThemeMode('light'), equals(ThemeMode.light));
      expect(ThemeSettingsService.parseThemeMode('dark'), equals(ThemeMode.dark));
      expect(ThemeSettingsService.parseThemeMode('system'), equals(ThemeMode.system));
    });

    test('serializes theme modes correctly', () {
      expect(ThemeSettingsService.serializeThemeMode(ThemeMode.light), equals('light'));
      expect(ThemeSettingsService.serializeThemeMode(ThemeMode.dark), equals('dark'));
      expect(ThemeSettingsService.serializeThemeMode(ThemeMode.system), equals('system'));
    });

    test('ThemeModePresentationX provides labels, subtitles, descriptions, and icons', () {
      expect(ThemeMode.system.label, equals('跟随系统'));
      expect(ThemeMode.system.subtitle, equals('Auto'));
      expect(ThemeMode.system.description, contains('随系统外观自动切换'));
      expect(ThemeMode.system.icon, equals(Icons.brightness_auto_outlined));
      expect(ThemeMode.system.filledIcon, equals(Icons.brightness_auto_rounded));

      expect(ThemeMode.light.label, equals('浅色模式'));
      expect(ThemeMode.light.subtitle, equals('Light'));
      expect(ThemeMode.light.description, contains('浅色外观'));
      expect(ThemeMode.light.icon, equals(Icons.light_mode_outlined));
      expect(ThemeMode.light.filledIcon, equals(Icons.light_mode_rounded));

      expect(ThemeMode.dark.label, equals('深色模式'));
      expect(ThemeMode.dark.subtitle, equals('Dark'));
      expect(ThemeMode.dark.description, contains('深色外观'));
      expect(ThemeMode.dark.icon, equals(Icons.dark_mode_outlined));
      expect(ThemeMode.dark.filledIcon, equals(Icons.dark_mode_rounded));
    });

    test('loadPreferences defaults to system + yunhao preset and yunhaoDay/yunhaoNight', () async {
      final loaded = await service.loadPreferences();

      expect(loaded.themeMode, equals(ThemeMode.system));
      expect(loaded.preset, equals(AtmosphereThemePreset.yunhao));
      expect(loaded.customLightPalette, equals(LightAtmospherePaletteId.yunhaoDay));
      expect(loaded.customDarkPalette, equals(DarkAtmospherePaletteId.yunhaoNight));
      expect(loaded.activeLightPalette, equals(LightAtmospherePaletteId.yunhaoDay));
      expect(loaded.activeDarkPalette, equals(DarkAtmospherePaletteId.yunhaoNight));
      expect(service.configNotifier.value, equals(loaded));
      expect(service.themeModeNotifier.value, equals(ThemeMode.system));
    });

    test('loadPreferences falls back safely on corrupted storage values and broken keystore', () async {
      mockStorage.data['memodiary_theme_mode'] = 'bogus_mode';
      mockStorage.data['memodiary_atmosphere_preset'] = 'bogus_preset';
      mockStorage.data['memodiary_custom_light_palette'] = 'bogus_light';
      mockStorage.data['memodiary_custom_dark_palette'] = 'bogus_dark';

      final loaded = await service.loadPreferences();
      expect(loaded.themeMode, equals(ThemeMode.system));
      expect(loaded.preset, equals(AtmosphereThemePreset.yunhao));
      expect(loaded.customLightPalette, equals(LightAtmospherePaletteId.yunhaoDay));
      expect(loaded.customDarkPalette, equals(DarkAtmospherePaletteId.yunhaoNight));

      final brokenService = ThemeSettingsService(storage: MockSecureStorage.broken());
      final brokenLoaded = await brokenService.loadPreferences();
      expect(brokenLoaded.preset, equals(AtmosphereThemePreset.yunhao));
    });

    test('preset switching resolves active palettes and preserves custom pairing across restarts', () async {
      await service.setPreset(AtmosphereThemePreset.custom);
      await service.setCustomLightPalette(LightAtmospherePaletteId.mistyTwilight);
      await service.setCustomDarkPalette(DarkAtmospherePaletteId.blossomLantern);

      expect(service.configNotifier.value.activeLightPalette, equals(LightAtmospherePaletteId.mistyTwilight));
      expect(service.configNotifier.value.activeDarkPalette, equals(DarkAtmospherePaletteId.blossomLantern));
      expect(mockStorage.data['memodiary_atmosphere_preset'], equals('custom'));
      expect(mockStorage.data['memodiary_custom_light_palette'], equals('mistyTwilight'));
      expect(mockStorage.data['memodiary_custom_dark_palette'], equals('blossomLantern'));

      // Switch to classic -> must NOT overwrite custom light/dark keys
      await service.setPreset(AtmosphereThemePreset.classic);
      expect(service.configNotifier.value.activeLightPalette, equals(LightAtmospherePaletteId.classicWalnut));
      expect(service.configNotifier.value.activeDarkPalette, equals(DarkAtmospherePaletteId.classicEbony));
      expect(mockStorage.data['memodiary_custom_light_palette'], equals('mistyTwilight'));
      expect(mockStorage.data['memodiary_custom_dark_palette'], equals('blossomLantern'));

      // Switch to yunhao -> still preserves custom keys
      await service.setPreset(AtmosphereThemePreset.yunhao);
      expect(service.configNotifier.value.activeLightPalette, equals(LightAtmospherePaletteId.yunhaoDay));
      expect(service.configNotifier.value.activeDarkPalette, equals(DarkAtmospherePaletteId.yunhaoNight));

      // Switch back to custom on a fresh service instance -> restores previous custom pair
      await service.setPreset(AtmosphereThemePreset.custom);
      final restartedService = ThemeSettingsService(storage: mockStorage);
      final restored = await restartedService.loadPreferences();
      expect(restored.preset, equals(AtmosphereThemePreset.custom));
      expect(restored.activeLightPalette, equals(LightAtmospherePaletteId.mistyTwilight));
      expect(restored.activeDarkPalette, equals(DarkAtmospherePaletteId.blossomLantern));
    });

    test('bidirectional sync keeps themeModeNotifier and configNotifier aligned without recursion', () async {
      var modeEvents = 0;
      var configEvents = 0;
      service.themeModeNotifier.addListener(() => modeEvents++);
      service.configNotifier.addListener(() => configEvents++);

      service.themeModeNotifier.value = ThemeMode.dark;
      expect(service.configNotifier.value.themeMode, equals(ThemeMode.dark));
      expect(modeEvents, equals(1));
      expect(configEvents, equals(1));

      await service.setThemeMode(ThemeMode.light);
      expect(service.themeModeNotifier.value, equals(ThemeMode.light));
      expect(service.configNotifier.value.themeMode, equals(ThemeMode.light));
      expect(modeEvents, equals(2));
      expect(configEvents, equals(2));
    });
  });

  group('AtmosphereThemeModels & AtmospherePalettes Tests', () {
    test('presets and palette enums expose expected Chinese labels and storage keys', () {
      expect(AtmosphereThemePreset.yunhao.label, equals('云皓'));
      expect(AtmosphereThemePreset.classic.label, equals('经典'));
      expect(AtmosphereThemePreset.custom.label, equals('自定义'));
      expect(AtmosphereThemePreset.yunhao.description, isNotEmpty);

      expect(LightAtmospherePaletteId.yunhaoDay.nameZh, equals('云岚昼'));
      expect(LightAtmospherePaletteId.classicWalnut.nameZh, equals('宣纸胡桃'));
      expect(LightAtmospherePaletteId.mistyTwilight.nameZh, equals('淡墨暮岚'));

      expect(DarkAtmospherePaletteId.yunhaoNight.nameZh, equals('皓月夜'));
      expect(DarkAtmospherePaletteId.classicEbony.nameZh, equals('碑拓乌木'));
      expect(DarkAtmospherePaletteId.silveryRain.nameZh, equals('清辉烟雨'));
      expect(DarkAtmospherePaletteId.blossomLantern.nameZh, equals('花影灯火'));
    });

    test('all 7 palettes match SPEC-022 color invariants and legacy preservation', () {
      for (final lightId in LightAtmospherePaletteId.values) {
        final palette = AtmospherePalettes.forLight(lightId);
        expect(palette.id, equals(lightId.name));
        expect(palette.nameZh, equals(lightId.nameZh));
        expect(palette.brightness, equals(Brightness.light));
        expect(palette.onAccentPrimary, equals(Colors.white));
      }

      for (final darkId in DarkAtmospherePaletteId.values) {
        final palette = AtmospherePalettes.forDark(darkId);
        expect(palette.id, equals(darkId.name));
        expect(palette.nameZh, equals(darkId.nameZh));
        expect(palette.brightness, equals(Brightness.dark));
      }

      expect(AtmospherePalettes.mistyTwilight.textFaint, equals(const Color(0xFF6F737A)));
      expect(AtmospherePalettes.yunhaoNight.onAccentPrimary, equals(const Color(0xFF1A140B)));
      expect(AtmospherePalettes.silveryRain.onAccentPrimary, equals(const Color(0xFF0E1720)));
      expect(AtmospherePalettes.blossomLantern.onAccentPrimary, equals(const Color(0xFF261015)));
      expect(AtmospherePalettes.classicEbony.onAccentPrimary, equals(Colors.white));

      // Semantic separation: accentPrimary != sealAccent on non-classic palettes
      expect(AtmospherePalettes.yunhaoNight.accentPrimary, equals(const Color(0xFFF2B866)));
      expect(AtmospherePalettes.yunhaoNight.sealAccent, equals(const Color(0xFFD16B62)));
      expect(AtmospherePalettes.yunhaoDay.accentPrimary, equals(const Color(0xFF4A7A9C)));
      expect(AtmospherePalettes.yunhaoDay.sealAccent, equals(const Color(0xFFC24D43)));

      // Legacy hex preservation on classicWalnut & classicEbony
      expect(AtmospherePalettes.classicWalnut.ground, equals(const Color(0xFFFCF9F2)));
      expect(AtmospherePalettes.classicWalnut.deskSurroundTop, equals(const Color(0xFFDFD3C0)));
      expect(AtmospherePalettes.classicWalnut.cardPaper, equals(const Color(0xFFFAF6EE)));
      expect(AtmospherePalettes.classicWalnut.silkMountBg, equals(const Color(0xFFE8DFCE)));
      expect(AtmospherePalettes.classicWalnut.silkMountBorder, equals(const Color(0xFFB8A689)));

      expect(AtmospherePalettes.classicEbony.ground, equals(const Color(0xFF181816)));
      expect(AtmospherePalettes.classicEbony.cardPaper, equals(const Color(0xFF242320)));
      expect(AtmospherePalettes.classicEbony.accentPrimary, equals(const Color(0xFFD25447)));
      expect(AtmospherePalettes.classicEbony.silkMountBg, equals(const Color(0xFFE8DFCE)));
      expect(AtmospherePalettes.classicEbony.silkMountBorder, equals(const Color(0xFFB8A689)));

      // copyWith & lerp smoke test
      final copied = AtmospherePalettes.yunhaoDay.copyWith(nameZh: '测试');
      expect(copied.nameZh, equals('测试'));
      expect(copied.ground, equals(AtmospherePalettes.yunhaoDay.ground));
      final lerped = AtmospherePalettes.yunhaoDay.lerp(AtmospherePalettes.yunhaoNight, 0.5);
      expect(lerped, isA<AtmospherePalette>());
    });
  });
}

