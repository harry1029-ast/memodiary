import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/theme_settings_service.dart';
import '../../helpers/mock_secure_storage.dart';
import 'package:memodiary/features/import_export/screens/import_staging_screen.dart';
import 'package:memodiary/features/recycle_bin/screens/recycle_bin_screen.dart';
import 'package:memodiary/features/settings/screens/settings_screen.dart';
import 'package:memodiary/features/settings/services/storage_optimizer_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../import_export/export_service_test.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late MockFileSelectorService mockFileSelector;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('settings_screen_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
    mockFileSelector = MockFileSelectorService();
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders all settings modules and privacy declaration', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            database: db,
            mediaService: mediaService,
            fileSelector: mockFileSelector,
            initialStats: const StorageStats(
              activeEntriesCount: 0,
              deletedEntriesCount: 0,
              totalMediaFiles: 0,
              totalMediaBytes: 0,
              orphanMediaFiles: 0,
              orphanMediaBytes: 0,
            ),
            permissionChecker: () async => {
              'camera': PermissionStatus.granted,
              'microphone': PermissionStatus.granted,
              'photos': PermissionStatus.granted,
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Settings & Privacy'), findsOneWidget);

      // Verify Sections
      expect(find.text('Appearance & Theme'), findsOneWidget);
      expect(find.text('墨色明暗设定'), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_mode_system')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_mode_light')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_mode_dark')), findsOneWidget);
      expect(find.text('Storage & Optimization'), findsOneWidget);
      expect(find.text('Data Portability'), findsOneWidget);
      expect(find.text('Permissions Dashboard'), findsOneWidget);

      // Verify Privacy Declaration Card
      expect(find.text('100% Offline & Private'), findsOneWidget);
      expect(find.textContaining('MemoDiary operates with zero cloud servers'), findsOneWidget);

      // Verify Permissions Listed
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Microphone & Speech'), findsOneWidget);
      expect(find.text('Photos & Files'), findsOneWidget);

      // Verify Data Portability Actions
      expect(find.text('Import from .txt / .md'), findsOneWidget);
      expect(find.text('Export All Diaries'), findsOneWidget);
      expect(find.byKey(const Key('settings_last_backup_tile')), findsOneWidget);
      expect(find.text('No backup created yet'), findsOneWidget);
      expect(find.byKey(const Key('settings_create_backup_tile')), findsOneWidget);
      expect(find.byKey(const Key('settings_restore_backup_tile')), findsOneWidget);
    });

    testWidgets('tapping Create Encrypted Backup opens CreateBackupDialog and validates passphrase',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            database: db,
            mediaService: mediaService,
            fileSelector: mockFileSelector,
            backupPbkdf2Iterations: 1000,
            initialStats: const StorageStats(
              activeEntriesCount: 0,
              deletedEntriesCount: 0,
              totalMediaFiles: 0,
              totalMediaBytes: 0,
              orphanMediaFiles: 0,
              orphanMediaBytes: 0,
            ),
            permissionChecker: () async => {
              'camera': PermissionStatus.granted,
              'microphone': PermissionStatus.granted,
              'photos': PermissionStatus.granted,
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_create_backup_tile')));
      await tester.pumpAndSettle();

      expect(find.text('Create Full-Archive Backup'), findsOneWidget);
      expect(find.byKey(const Key('backup_passphrase_field')), findsOneWidget);

      // Save & Share buttons should be disabled when passphrase is empty
      final saveBtnBefore = tester.widget<FilledButton>(
        find.byKey(const Key('backup_save_button')),
      );
      expect(saveBtnBefore.onPressed, isNull);

      // Enter valid matching passphrase (>= 8 chars)
      await tester.enterText(
        find.byKey(const Key('backup_passphrase_field')),
        'strong-pass-2026',
      );
      await tester.enterText(
        find.byKey(const Key('backup_confirm_passphrase_field')),
        'strong-pass-2026',
      );
      await tester.pump();

      final saveBtnAfter = tester.widget<FilledButton>(
        find.byKey(const Key('backup_save_button')),
      );
      expect(saveBtnAfter.onPressed, isNotNull);

      // Toggle encryption off -> shows warning banner
      await tester.tap(find.byKey(const Key('backup_encrypt_switch')));
      await tester.pump();
      expect(
        find.byKey(const Key('backup_unencrypted_warning')),
        findsOneWidget,
      );
    });

    testWidgets('tapping import with picked file opens ImportStagingScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Create mock file with sample diary text
      final sampleFile = File('${tempDir.path}/imported_notes.md');
      sampleFile.writeAsStringSync('''
# 2026-10-16 Trip to Osaka
Visiting Dotonbori in the evening.
''');
      mockFileSelector.pickedFile = sampleFile;

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            database: db,
            mediaService: mediaService,
            fileSelector: mockFileSelector,
            initialStats: const StorageStats(
              activeEntriesCount: 0,
              deletedEntriesCount: 0,
              totalMediaFiles: 0,
              totalMediaBytes: 0,
              orphanMediaFiles: 0,
              orphanMediaBytes: 0,
            ),
            permissionChecker: () async => {
              'camera': PermissionStatus.granted,
              'microphone': PermissionStatus.granted,
              'photos': PermissionStatus.granted,
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Tap "Import from .txt / .md"
      await tester.tap(find.text('Import from .txt / .md'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // ImportStagingScreen should now be on top of navigation
      expect(find.byType(ImportStagingScreen), findsOneWidget);
      expect(find.text('Import Staging'), findsOneWidget);
      expect(find.text('Trip to Osaka'), findsOneWidget);
    });

    Future<void> pumpSettingsScreen(
      WidgetTester tester, {
      int backupPbkdf2Iterations = 200000,
      Duration delay = const Duration(milliseconds: 50),
      ThemeSettingsService? themeSettings,
    }) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(
              database: db,
              mediaService: mediaService,
              fileSelector: mockFileSelector,
              backupPbkdf2Iterations: backupPbkdf2Iterations,
              themeSettings: themeSettings,
              initialStats: const StorageStats(
                activeEntriesCount: 0,
                deletedEntriesCount: 0,
                totalMediaFiles: 0,
                totalMediaBytes: 0,
                orphanMediaFiles: 0,
                orphanMediaBytes: 0,
              ),
              permissionChecker: () async => {
                'camera': PermissionStatus.granted,
                'microphone': PermissionStatus.granted,
                'photos': PermissionStatus.granted,
              },
            ),
          ),
        );
        await Future.delayed(delay);
      });

      await tester.pumpAndSettle();
    }

    testWidgets('displays formatted timestamp when last backup exists',
        (WidgetTester tester) async {
      // Write mock backup_meta.json in parent of media sandbox
      final metaFile = File('${tempDir.path}/backup_meta.json');
      metaFile.writeAsStringSync('{"lastBackupAt":"2026-10-19T10:30:00.000Z"}');

      await pumpSettingsScreen(tester, delay: const Duration(milliseconds: 100));

      final tileFinder = find.byKey(const Key('settings_last_backup_tile'));
      expect(tileFinder, findsOneWidget);
      expect(find.text('No backup created yet'), findsNothing);
      expect(find.textContaining('2026-10-19'), findsOneWidget);

      final listTile = tester.widget<ListTile>(tileFinder);
      expect(listTile.leading, isA<Icon>());
      final icon = listTile.leading as Icon;
      expect(icon.icon, Icons.history_edu_outlined);
      expect(icon.size, 20.0);
    });

    testWidgets('creating backup dynamically updates last backup tile timestamp on screen',
        (WidgetTester tester) async {
      await pumpSettingsScreen(tester, backupPbkdf2Iterations: 100);

      // Initially shows no backup created yet
      expect(find.byKey(const Key('settings_last_backup_tile')), findsOneWidget);
      expect(find.text('No backup created yet'), findsOneWidget);

      // Tap "Create Encrypted Backup" tile to open dialog
      await tester.tap(find.byKey(const Key('settings_create_backup_tile')));
      await tester.pumpAndSettle();

      expect(find.text('Create Full-Archive Backup'), findsOneWidget);

      // Toggle off encryption to create an unencrypted backup instantly
      await tester.tap(find.byKey(const Key('backup_encrypt_switch')));
      await tester.pumpAndSettle();

      // Tap "Save to Device" button and await disk write in runAsync
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('backup_save_button')));
        for (var i = 0; i < 20; i++) {
          await Future.delayed(const Duration(milliseconds: 50));
          await tester.pump(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();

      // Dialog dismissed and tile dynamically refreshed with today's date
      expect(find.text('Create Full-Archive Backup'), findsNothing);
      expect(find.byKey(const Key('settings_last_backup_tile')), findsOneWidget);
      expect(find.text('No backup created yet'), findsNothing);
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      expect(find.textContaining(todayStr), findsOneWidget);
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
  });
}


