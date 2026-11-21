import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/atmosphere_theme_models.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/theme_settings_service.dart';
import '../../helpers/mock_secure_storage.dart';
import 'package:memodiary/features/import_export/screens/import_backup_screen.dart';
import 'package:memodiary/features/recycle_bin/screens/recycle_bin_screen.dart';
import 'package:memodiary/features/settings/screens/settings_screen.dart';
import 'package:memodiary/features/settings/services/signature_seal_service.dart';
import 'package:memodiary/features/settings/services/storage_optimizer_service.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('settings_screen_test_');
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

  group('SettingsScreen Widget Tests', () {
    Future<void> pumpSettingsScreen(
      WidgetTester tester, {
      Size viewportSize = const Size(800, 1600),
      double textScale = 1.0,
      Duration delay = const Duration(milliseconds: 50),
      ThemeSettingsService? themeSettings,
      ScenerySettingsService? scenerySettingsService,
      SignatureSealService? signatureSealService,
      int activeEntriesCount = 0,
      Map<String, PermissionStatus>? permissions,
      bool liveThemeApp = false,
    }) async {
      tester.view.physicalSize = viewportSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Widget buildApp({AtmosphereThemeConfig? config}) {
        return MaterialApp(
          theme: config != null
              ? InkDiaryTheme.forLightPalette(config.activeLightPalette)
              : null,
          darkTheme: config != null
              ? InkDiaryTheme.forDarkPalette(config.activeDarkPalette)
              : null,
          themeMode: config?.themeMode ?? ThemeMode.system,
          builder: textScale == 1.0
              ? null
              : (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(textScale),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
          home: SettingsScreen(
            database: db,
            mediaService: mediaService,
            themeSettings: themeSettings,
            scenerySettingsService: scenerySettingsService,
            signatureSealService: signatureSealService,
            initialStats: StorageStats(
              activeEntriesCount: activeEntriesCount,
              deletedEntriesCount: 0,
              totalMediaFiles: 0,
              totalMediaBytes: 0,
              orphanMediaFiles: 0,
              orphanMediaBytes: 0,
            ),
            permissionChecker: () async =>
                permissions ??
                const {
                  'camera': PermissionStatus.granted,
                  'microphone': PermissionStatus.granted,
                  'photos': PermissionStatus.granted,
                },
          ),
        );
      }

      final rootWidget = (liveThemeApp && themeSettings != null)
          ? ValueListenableBuilder<AtmosphereThemeConfig>(
              valueListenable: themeSettings.configNotifier,
              builder: (context, config, _) => buildApp(config: config),
            )
          : buildApp();

      await tester.runAsync(() async {
        await tester.pumpWidget(rootWidget);
        await Future.delayed(delay);
      });

      await tester.pumpAndSettle();
    }

    testWidgets('renders all settings modules and privacy declaration', (WidgetTester tester) async {
      await pumpSettingsScreen(
        tester,
        viewportSize: const Size(800, 2600),
        delay: const Duration(milliseconds: 200),
      );

      // Verify Screen Title (no English subtitle or slogan banner)
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('Settings & Privacy'), findsNothing);
      expect(find.text('设置与守拙'), findsNothing);
      expect(find.text('墨室守拙 · 恪纯无垢'), findsNothing);

      // Verify Plain Section Headers (no English subheaders)
      expect(find.text('开卷动画'), findsOneWidget);
      expect(find.text('外观主题'), findsOneWidget);
      expect(find.text('外观模式'), findsOneWidget);
      expect(find.text('签名印章'), findsOneWidget);
      expect(find.text('存储与清理'), findsOneWidget);
      expect(find.text('写作提醒'), findsOneWidget);
      expect(find.text('导入与导出'), findsNothing);
      expect(find.text('日记数据'), findsOneWidget);
      expect(find.text('权限管理'), findsOneWidget);
      expect(find.text('隐私保护'), findsOneWidget);

      expect(find.text('Book Cover & Intro'), findsNothing);
      expect(find.text('Appearance & Theme'), findsNothing);
      expect(find.text('Signature Seal'), findsNothing);
      expect(find.text('Storage & Optimization'), findsNothing);
      expect(find.text('REMINDERS'), findsNothing);
      expect(find.text('Data Portability'), findsNothing);
      expect(find.text('Permissions Dashboard'), findsNothing);

      expect(find.byKey(const Key('settings_theme_mode_system')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_mode_light')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_mode_dark')), findsOneWidget);
      expect(find.text('Auto'), findsNothing);
      expect(find.text('Light'), findsNothing);
      expect(find.text('Dark'), findsNothing);

      // Verify Privacy Declaration Card
      expect(find.text('完全离线 · 本地隐私保护'), findsOneWidget);
      expect(find.textContaining('云皓日记全程离线运行'), findsOneWidget);
      expect(find.text('100% Offline & Private'), findsNothing);

      // Verify Permissions Listed
      expect(find.text('相机'), findsOneWidget);
      expect(find.text('语音听写'), findsOneWidget);
      expect(find.text('相册与文件'), findsOneWidget);
      expect(find.text('已授权'), findsNWidgets(3));
      expect(find.text('Camera'), findsNothing);
      expect(find.text('Microphone & Speech'), findsNothing);
      expect(find.text('Photos & Files'), findsNothing);
      expect(find.text('已获准'), findsNothing);

      // Data-moving tools live on the Import & Backup screen; Settings keeps one row
      expect(find.text('写作统计'), findsOneWidget);
      expect(find.byKey(const Key('settings_import_backup_tile')), findsOneWidget);
      expect(find.text('导入与备份'), findsOneWidget);
      expect(find.text('导入文本'), findsNothing);
      expect(find.text('导出日记'), findsNothing);
      expect(find.text('上次备份时间'), findsNothing);
      expect(find.text('导出加密备份 (.mdbak)'), findsNothing);
      expect(find.text('从备份恢复'), findsNothing);
    });

    testWidgets('displays 未授权 badge for denied hardware permissions', (WidgetTester tester) async {
      await pumpSettingsScreen(
        tester,
        viewportSize: const Size(800, 2600),
        permissions: const {
          'camera': PermissionStatus.granted,
          'microphone': PermissionStatus.denied,
          'photos': PermissionStatus.permanentlyDenied,
        },
      );

      expect(find.text('已授权'), findsOneWidget);
      expect(find.text('未授权'), findsNWidgets(2));
    });

    testWidgets('tapping the 导入与备份 row opens the Import & Backup screen', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      final importBackupTile = find.byKey(const Key('settings_import_backup_tile'));
      await tester.ensureVisible(importBackupTile);
      await tester.pumpAndSettle();
      await tester.tap(importBackupTile);
      await tester.pumpAndSettle();

      expect(find.byType(ImportBackupScreen), findsOneWidget);
      expect(find.text('导出加密备份 (.mdbak)'), findsOneWidget);
    });

    testWidgets('tapping recycle bin tile navigates to RecycleBinScreen', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      final recycleTile = find.byKey(const Key('settings_recycle_bin_tile'));
      expect(recycleTile, findsOneWidget);

      await tester.tap(recycleTile);
      await tester.pumpAndSettle();

      expect(find.byType(RecycleBinScreen), findsOneWidget);
    });

    testWidgets('tapping light and dark theme mode options toggles theme and persists preference',
        (WidgetTester tester) async {
      final mockStorage = MockSecureStorage();
      final themeSettings = ThemeSettingsService(storage: mockStorage);

      await pumpSettingsScreen(tester, themeSettings: themeSettings);

      // Default is system
      expect(themeSettings.themeModeNotifier.value, equals(ThemeMode.system));

      // Tap Light Mode
      await tester.tap(find.byKey(const Key('settings_theme_mode_light')));
      await tester.pumpAndSettle();
      expect(themeSettings.themeModeNotifier.value, equals(ThemeMode.light));
      expect(mockStorage.data['memodiary_theme_mode'], equals('light'));

      // Tap Dark Mode
      await tester.tap(find.byKey(const Key('settings_theme_mode_dark')));
      await tester.pumpAndSettle();
      expect(themeSettings.themeModeNotifier.value, equals(ThemeMode.dark));
      expect(mockStorage.data['memodiary_theme_mode'], equals('dark'));

      // Tap System Mode
      await tester.tap(find.byKey(const Key('settings_theme_mode_system')));
      await tester.pumpAndSettle();
      expect(themeSettings.themeModeNotifier.value, equals(ThemeMode.system));
      expect(mockStorage.data['memodiary_theme_mode'], equals('system'));
    });

    testWidgets('toggling scenery collapsed switch, locking atmosphere, and reset tile updates state', (tester) async {
      final mockStorage = MockSecureStorage();
      final sceneryService = ScenerySettingsService(storage: mockStorage);
      await pumpSettingsScreen(tester, scenerySettingsService: sceneryService);

      final switchFinder = find.byKey(const Key('settings_scenery_collapsed_switch'));
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(mockStorage.data['memodiary_scenery_card_collapsed'], equals('true'));

      // Test locking atmosphere
      final pinTileFinder = find.byKey(const Key('settings_scenery_pin_atmosphere_tile'));
      expect(pinTileFinder, findsOneWidget);

      await tester.tap(pinTileFinder);
      await tester.pumpAndSettle();

      expect(find.text('固定画卷氛围'), findsAtLeast(1));
      // Tap winter season chip
      final winterChip = find.byKey(const Key('settings_pin_season_chip_winter'));
      expect(winterChip, findsOneWidget);
      await tester.tap(winterChip);
      await tester.pumpAndSettle();

      // Tap night time chip
      final nightChip = find.byKey(const Key('settings_pin_time_chip_night'));
      expect(nightChip, findsOneWidget);
      await tester.tap(nightChip);
      await tester.pumpAndSettle();

      // Tap save
      final saveBtn = find.byKey(const Key('settings_pin_save_button'));
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(mockStorage.data['memodiary_scenery_pinned_season'], equals('winter'));
      expect(mockStorage.data['memodiary_scenery_pinned_time'], equals('night'));

      // Test reset tile
      final resetTileFinder = find.byKey(const Key('settings_scenery_reset_atmosphere_tile'));
      expect(resetTileFinder, findsOneWidget);

      await tester.tap(resetTileFinder);
      await tester.pumpAndSettle();

      expect(find.text('已恢复自动同步'), findsOneWidget);
      expect(mockStorage.data['memodiary_scenery_pinned_season'], isNull);
      expect(mockStorage.data['memodiary_scenery_pinned_time'], isNull);
    });

    testWidgets('renders signature seal card, opens edit dialog, updates inscription, and saves', (WidgetTester tester) async {
      final mockStorage = MockSecureStorage();
      final sealService = SignatureSealService(storage: mockStorage);

      await pumpSettingsScreen(
        tester,
        viewportSize: const Size(800, 2600),
        signatureSealService: sealService,
      );

      // Card is rendered with default seal text
      expect(find.byKey(const Key('settings_signature_seal_card')), findsOneWidget);
      expect(find.text('当前印章文字：心迹安放'), findsOneWidget);

      // Tap edit button to open dialog
      final editBtn = find.byKey(const Key('settings_edit_signature_seal_button'));
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.text('修改签名印章（2至4字）'), findsOneWidget);
      final inputFinder = find.byKey(const Key('settings_signature_seal_input'));
      expect(inputFinder, findsOneWidget);

      // Enter new seal text
      await tester.enterText(inputFinder, '春山如笑');
      await tester.pumpAndSettle();

      // Tap save
      final saveBtn = find.byKey(const Key('settings_signature_seal_save_button'));
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Card is updated
      expect(find.text('当前印章文字：春山如笑'), findsOneWidget);
      expect(await sealService.getSealText(), equals('春山如笑'));
    });

    testWidgets('主题风格 renders 云皓 (默认), 经典, 自定义 with hidden custom drawer, >=44dp tap targets, and semantics',
        (WidgetTester tester) async {
      final mockStorage = MockSecureStorage();
      final themeSettings = ThemeSettingsService(storage: mockStorage);

      await pumpSettingsScreen(tester, themeSettings: themeSettings);

      expect(find.text('主题风格'), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_preset_yunhao')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_preset_classic')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_preset_custom')), findsOneWidget);
      expect(find.text('云皓'), findsOneWidget);
      expect(find.text('默认'), findsOneWidget);
      expect(find.text('经典'), findsOneWidget);
      expect(find.text('自定义'), findsOneWidget);
      expect(find.byKey(const Key('settings_custom_palette_drawer')), findsNothing);

      for (final keyName in const [
        'settings_theme_mode_system',
        'settings_theme_mode_light',
        'settings_theme_mode_dark',
        'settings_theme_preset_yunhao',
        'settings_theme_preset_classic',
        'settings_theme_preset_custom',
      ]) {
        expect(tester.getSize(find.byKey(Key(keyName))).height, greaterThanOrEqualTo(44.0), reason: keyName);
      }

      expect(
        tester.getSemantics(find.byKey(const Key('settings_theme_preset_yunhao'))),
        isSemantics(isSelected: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('settings_theme_preset_classic'))),
        isSemantics(isSelected: false, hasTapAction: true),
      );

      // Tapping an already-selected preset is a safe no-op that preserves tap semantics.
      await tester.tap(find.byKey(const Key('settings_theme_preset_yunhao')));
      await tester.pumpAndSettle();
      expect(themeSettings.configNotifier.value.preset, equals(AtmosphereThemePreset.yunhao));

      await tester.tap(find.byKey(const Key('settings_theme_preset_classic')));
      await tester.pumpAndSettle();

      expect(themeSettings.configNotifier.value.preset, equals(AtmosphereThemePreset.classic));
      expect(mockStorage.data['memodiary_atmosphere_preset'], equals('classic'));
      expect(find.byKey(const Key('settings_custom_palette_drawer')), findsNothing);
    });

    testWidgets('selecting 自定义 reveals 3 Light + 4 Dark palettes, persists selections, and remembers pair across preset switches',
        (WidgetTester tester) async {
      final mockStorage = MockSecureStorage();
      final themeSettings = ThemeSettingsService(storage: mockStorage);

      await pumpSettingsScreen(tester, themeSettings: themeSettings);

      await tester.tap(find.byKey(const Key('settings_theme_preset_custom')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_custom_palette_drawer')), findsOneWidget);
      expect(find.text('浅色色板'), findsOneWidget);
      expect(find.text('深色色板'), findsOneWidget);

      for (final keyName in const [
        'settings_light_palette_yunhao_day',
        'settings_light_palette_classic_walnut',
        'settings_light_palette_misty_twilight',
        'settings_dark_palette_yunhao_night',
        'settings_dark_palette_classic_ebony',
        'settings_dark_palette_silvery_rain',
        'settings_dark_palette_blossom_lantern',
      ]) {
        final finder = find.byKey(Key(keyName));
        expect(finder, findsOneWidget, reason: keyName);
        expect(tester.getSize(finder).height, greaterThanOrEqualTo(44.0), reason: keyName);
      }

      expect(find.text('云岚昼'), findsOneWidget);
      expect(find.text('宣纸胡桃'), findsOneWidget);
      expect(find.text('淡墨暮岚'), findsOneWidget);
      expect(find.text('皓月夜'), findsOneWidget);
      expect(find.text('碑拓乌木'), findsOneWidget);
      expect(find.text('清辉烟雨'), findsOneWidget);
      expect(find.text('花影灯火'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings_light_palette_misty_twilight')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_dark_palette_blossom_lantern')));
      await tester.pumpAndSettle();

      expect(mockStorage.data['memodiary_custom_light_palette'], equals('mistyTwilight'));
      expect(mockStorage.data['memodiary_custom_dark_palette'], equals('blossomLantern'));
      expect(
        tester.getSemantics(find.byKey(const Key('settings_light_palette_misty_twilight'))),
        isSemantics(isSelected: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('settings_dark_palette_blossom_lantern'))),
        isSemantics(isSelected: true, hasTapAction: true),
      );

      // Switch away to classic and back to custom -> custom pair stays preserved
      await tester.tap(find.byKey(const Key('settings_theme_preset_classic')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings_custom_palette_drawer')), findsNothing);

      await tester.tap(find.byKey(const Key('settings_theme_preset_custom')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings_custom_palette_drawer')), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('settings_light_palette_misty_twilight'))),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('settings_dark_palette_blossom_lantern'))),
        isSemantics(isSelected: true),
      );
    });

    testWidgets('changing AtmosphereTheme updates live MaterialApp theme without mutating saved entry templates and fits 320px at 1.3x scale',
        (WidgetTester tester) async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'preserved_entry_1',
          notebookId: 'notebook_default',
          templateId: 'template_vintage_letter',
          title: const Value('旧笺未改'),
          contentDelta: jsonEncode([{'insert': '信纸模板应保持原样。\n'}]),
          plainText: '信纸模板应保持原样。',
          entryDate: DateTime(2026, 11, 18),
        ),
      );

      final mockStorage = MockSecureStorage();
      final themeSettings = ThemeSettingsService(storage: mockStorage);

      await pumpSettingsScreen(
        tester,
        viewportSize: const Size(320, 1400),
        textScale: 1.3,
        themeSettings: themeSettings,
        activeEntriesCount: 1,
        liveThemeApp: true,
      );

      await tester.tap(find.byKey(const Key('settings_theme_mode_dark')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_theme_preset_custom')));
      await tester.pumpAndSettle();
      final blossomFinder = find.byKey(const Key('settings_dark_palette_blossom_lantern'));
      await tester.scrollUntilVisible(blossomFinder, 200.0);
      await tester.pumpAndSettle();
      await tester.tap(blossomFinder);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF0D1B1E)));

      final entry = await db.entriesDao.getEntryById('preserved_entry_1');
      expect(entry?.templateId, equals('template_vintage_letter'));
    });
  });
}


