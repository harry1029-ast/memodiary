import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/screens/import_staging_screen.dart';
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
  });
}

