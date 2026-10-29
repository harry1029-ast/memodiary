import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/theme_settings_service.dart';
import 'package:memodiary/main.dart';

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

  testWidgets('MemoDiaryApp rebuilds MaterialApp when themeModeNotifier changes',
      (WidgetTester tester) async {
    final themeSettings = ThemeSettingsService();
    themeSettings.themeModeNotifier.value = ThemeMode.system;

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
    themeSettings.themeModeNotifier.value = ThemeMode.light;
    await tester.pumpAndSettle();

    app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, equals(ThemeMode.light));

    // Update to ThemeMode.dark
    themeSettings.themeModeNotifier.value = ThemeMode.dark;
    await tester.pumpAndSettle();

    app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, equals(ThemeMode.dark));
  });
}

