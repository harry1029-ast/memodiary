import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      expect(ThemeMode.system.description, contains('随系统明暗'));
      expect(ThemeMode.system.icon, equals(Icons.brightness_auto_outlined));
      expect(ThemeMode.system.filledIcon, equals(Icons.brightness_auto_rounded));

      expect(ThemeMode.light.label, equals('素宣浅色'));
      expect(ThemeMode.light.subtitle, equals('Light'));
      expect(ThemeMode.light.description, contains('常驻素白宣纸'));
      expect(ThemeMode.light.icon, equals(Icons.light_mode_outlined));
      expect(ThemeMode.light.filledIcon, equals(Icons.light_mode_rounded));

      expect(ThemeMode.dark.label, equals('焦墨深色'));
      expect(ThemeMode.dark.subtitle, equals('Dark'));
      expect(ThemeMode.dark.description, contains('常驻静谧焦墨'));
      expect(ThemeMode.dark.icon, equals(Icons.dark_mode_outlined));
      expect(ThemeMode.dark.filledIcon, equals(Icons.dark_mode_rounded));
    });
  });
}

