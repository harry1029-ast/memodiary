import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:memodiary/features/settings/screens/settings_screen.dart';
import 'package:memodiary/features/settings/services/storage_optimizer_service.dart';
import '../../helpers/mock_secure_storage.dart';
import '../import_export/export_service_test.dart';

void main() {
  group('SettingsScreen Scenery Realm Preferences Tests', () {
    late AppDatabase db;
    late Directory tempDir;
    late MediaSandboxService mediaService;
    late MockFileSelectorService fileSelector;
    late MockSecureStorage mockStorage;
    late ScenerySettingsService scenerySettings;

    setUp(() {
      db = AppDatabase.memory();
      tempDir = Directory.systemTemp.createTempSync('settings_realm_test_');
      mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
      fileSelector = MockFileSelectorService();
      mockStorage = MockSecureStorage();
      scenerySettings = ScenerySettingsService(storage: mockStorage);
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<void> pumpSettings(WidgetTester tester, {double width = 800}) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: SettingsScreen(
            database: db,
            mediaService: mediaService,
            fileSelector: fileSelector,
            scenerySettingsService: scenerySettings,
            permissionChecker: () async => {},
            initialStats: const StorageStats(
              activeEntriesCount: 0,
              deletedEntriesCount: 0,
              totalMediaFiles: 0,
              totalMediaBytes: 0,
              orphanMediaFiles: 0,
              orphanMediaBytes: 0,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'displays 画卷场景 tile with default 自动 subtitle',
      (tester) async {
        await pumpSettings(tester);

        final tileFinder = find.byKey(const Key('settings_scenery_realm_tile'));
        expect(tileFinder, findsOneWidget);
        expect(find.text('画卷场景'), findsOneWidget);
        expect(find.textContaining('Scenery Realm'), findsNothing);
        expect(find.textContaining('自动'), findsAtLeast(1));
      },
    );

    testWidgets(
      'tapping realm tile opens selection dialog and persists selected preference',
      (tester) async {
        await pumpSettings(tester);

        // Tap the tile
        await tester.tap(find.byKey(const Key('settings_scenery_realm_tile')));
        await tester.pumpAndSettle();

        // Verify options in dialog
        expect(find.byKey(const Key('settings_realm_option_auto')), findsOneWidget);
        expect(find.byKey(const Key('settings_realm_option_nature')), findsOneWidget);
        expect(find.byKey(const Key('settings_realm_option_indoor')), findsOneWidget);
        expect(find.byKey(const Key('settings_realm_option_outdoor')), findsOneWidget);

        // Select Indoor (室内)
        await tester.tap(find.byKey(const Key('settings_realm_option_indoor')));
        await tester.pumpAndSettle();

        // Dialog should be dismissed
        expect(find.byKey(const Key('settings_realm_option_indoor')), findsNothing);

        // Preference persisted
        expect(mockStorage.data['memodiary_scenery_realm_preference'], equals('indoor'));

        // Feedback SnackBar shown
        expect(find.textContaining('已设置画卷场景'), findsOneWidget);

        // Tile subtitle updated to reflect 室内
        expect(find.textContaining('室内'), findsAtLeast(1));
      },
    );

    testWidgets(
      'resetting pinned atmosphere also resets realm preference to auto',
      (tester) async {
        // Pre-set pinned atmosphere and indoor realm preference
        mockStorage.data['memodiary_scenery_pinned_season'] = 'winter';
        mockStorage.data['memodiary_scenery_pinned_time'] = 'night';
        mockStorage.data['memodiary_scenery_pinned_weather'] = 'snowy';
        mockStorage.data['memodiary_scenery_realm_preference'] = 'indoor';

        await pumpSettings(tester);

        // Verify initial state shows indoor
        expect(find.textContaining('室内'), findsAtLeast(1));

        // Tap reset atmosphere tile
        final resetTile = find.byKey(const Key('settings_scenery_reset_atmosphere_tile'));
        expect(resetTile, findsOneWidget);
        await tester.tap(resetTile);
        await tester.pumpAndSettle();

        // SnackBar feedback
        expect(find.text('已恢复实时四时天候同步'), findsOneWidget);

        // Storage cleared
        expect(mockStorage.data['memodiary_scenery_realm_preference'], isNull);

        // Subtitle restored to 自动
        expect(find.textContaining('自动（根据近期日记切换）'), findsOneWidget);
      },
    );

    testWidgets(
      'renders cleanly without overflow down to 320px width',
      (tester) async {
        await pumpSettings(tester, width: 320);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
