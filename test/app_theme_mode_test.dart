import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/atmosphere_theme_models.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/theme_settings_service.dart';
import 'package:memodiary/main.dart';
import 'helpers/mock_secure_storage.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('app_theme_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('MemoDiaryApp rebuilds MaterialApp when themeMode changes',
      (WidgetTester tester) async {
    final themeSettings = ThemeSettingsService(storage: MockSecureStorage());
    await themeSettings.setThemeMode(ThemeMode.system);

    await tester.pumpWidget(
      MemoDiaryApp(
        database: db,
        mediaService: mediaService,
        showIntroOnLaunch: false,
        themeSettings: themeSettings,
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial themeMode is ThemeMode.system
    MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, equals(ThemeMode.system));
    expect(app.theme, equals(InkDiaryTheme.light));
    expect(app.darkTheme, equals(InkDiaryTheme.dark));

    // Update to ThemeMode.light
    await themeSettings.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();

    app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, equals(ThemeMode.light));
    expect(themeSettings.configNotifier.value.themeMode, equals(ThemeMode.light));

    // Update to ThemeMode.dark
    await themeSettings.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, equals(ThemeMode.dark));
    expect(themeSettings.configNotifier.value.themeMode, equals(ThemeMode.dark));
  });

  testWidgets('MemoDiaryApp updates light and dark ThemeData live on preset and custom palette changes',
      (WidgetTester tester) async {
    final themeSettings = ThemeSettingsService(storage: MockSecureStorage());

    await tester.pumpWidget(
      MemoDiaryApp(
        database: db,
        mediaService: mediaService,
        showIntroOnLaunch: false,
        themeSettings: themeSettings,
      ),
    );
    await tester.pumpAndSettle();

    MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.extension<AtmospherePalette>()?.id, equals('yunhaoDay'));
    expect(app.darkTheme?.extension<AtmospherePalette>()?.id, equals('yunhaoNight'));
    expect(app.theme?.extension<AtmospherePalette>()?.sealAccent, equals(const Color(0xFFC24D43)));
    expect(app.darkTheme?.colorScheme.onSecondary, equals(const Color(0xFF1A140B)));
    expect(app.darkTheme?.floatingActionButtonTheme.foregroundColor, equals(const Color(0xFF1A140B)));

    // Switch to classic preset
    await themeSettings.setPreset(AtmosphereThemePreset.classic);
    await tester.pumpAndSettle();

    app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.extension<AtmospherePalette>()?.id, equals('classicWalnut'));
    expect(app.darkTheme?.extension<AtmospherePalette>()?.id, equals('classicEbony'));

    // Switch to custom and choose mistyTwilight + blossomLantern
    await themeSettings.setPreset(AtmosphereThemePreset.custom);
    await themeSettings.setCustomLightPalette(LightAtmospherePaletteId.mistyTwilight);
    await themeSettings.setCustomDarkPalette(DarkAtmospherePaletteId.blossomLantern);
    await tester.pumpAndSettle();

    app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.extension<AtmospherePalette>()?.id, equals('mistyTwilight'));
    expect(app.darkTheme?.extension<AtmospherePalette>()?.id, equals('blossomLantern'));
    expect(app.darkTheme?.extension<AtmospherePalette>()?.onAccentPrimary, equals(const Color(0xFF261015)));
  });
}

