import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/atmosphere_theme_models.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/import_export/screens/import_backup_screen.dart';
import 'package:memodiary/features/import_export/screens/import_staging_screen.dart';
import 'package:memodiary/features/import_export/services/backup_restore_service.dart';
import 'package:memodiary/features/import_export/widgets/export_dialog.dart';

import 'export_service_test.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late MockFileSelectorService mockFileSelector;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('import_backup_screen_test_');
    mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
    mockFileSelector = MockFileSelectorService();
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> pumpImportBackupScreen(
    WidgetTester tester, {
    Size viewportSize = const Size(800, 1600),
    double textScale = 1.0,
    BackupRestoreService? backupService,
    int backupPbkdf2Iterations = 1000,
    Duration delay = const Duration(milliseconds: 50),
    DarkAtmospherePaletteId? darkPalette,
  }) async {
    tester.view.physicalSize = viewportSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          darkTheme: darkPalette != null ? InkDiaryTheme.forDarkPalette(darkPalette) : null,
          themeMode: darkPalette != null ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          home: ImportBackupScreen(
            database: db,
            mediaService: mediaService,
            fileSelector: mockFileSelector,
            backupService: backupService,
            backupPbkdf2Iterations: backupPbkdf2Iterations,
          ),
        ),
      );
      await Future.delayed(delay);
    });
    await tester.pumpAndSettle();
  }

  group('ImportBackupScreen', () {
    testWidgets('titled 导入与备份 and lists the import, export and backup tools', (tester) async {
      await pumpImportBackupScreen(tester);

      expect(find.text('导入与备份'), findsOneWidget);
      expect(find.text('导入文本'), findsOneWidget);
      expect(find.text('导出日记'), findsOneWidget);
      expect(find.byKey(const Key('import_backup_last_backup_tile')), findsOneWidget);
      expect(find.text('尚未创建备份'), findsOneWidget);
      expect(find.text('导出加密备份 (.mdbak)'), findsOneWidget);
      expect(find.text('从备份恢复'), findsOneWidget);
      expect(find.text('写作统计'), findsNothing);
    });

    testWidgets('导入文本 with a picked file opens import staging with the parsed entries', (tester) async {
      final sampleFile = File('${tempDir.path}/imported_notes.md');
      sampleFile.writeAsStringSync('''
# 2026-10-16 Trip to Osaka
Visiting Dotonbori in the evening.
''');
      mockFileSelector.pickedFile = sampleFile;

      await pumpImportBackupScreen(tester);

      await tester.tap(find.text('导入文本'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byType(ImportStagingScreen), findsOneWidget);
      expect(find.text('导入预览'), findsOneWidget);
      expect(find.text('Trip to Osaka'), findsOneWidget);
    });

    testWidgets('导入文本 with a file holding no diary content explains there is nothing to import',
        (tester) async {
      final emptyFile = File('${tempDir.path}/empty.txt')..writeAsStringSync('');
      mockFileSelector.pickedFile = emptyFile;

      await pumpImportBackupScreen(tester);

      await tester.tap(find.text('导入文本'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byType(ImportStagingScreen), findsNothing);
      expect(find.text('所选文件中没有可导入的日记内容'), findsOneWidget);
    });

    testWidgets('导出日记 opens the export dialog', (tester) async {
      await pumpImportBackupScreen(tester);

      await tester.tap(find.text('导出日记'));
      await tester.pumpAndSettle();

      expect(find.byType(ExportDialog), findsOneWidget);
    });

    testWidgets('导出加密备份 opens the backup dialog and validates the passphrase', (tester) async {
      await pumpImportBackupScreen(tester);

      await tester.tap(find.byKey(const Key('import_backup_create_backup_tile')));
      await tester.pumpAndSettle();

      expect(find.text('导出加密备份 (.mdbak)'), findsAtLeast(1));
      expect(find.byKey(const Key('backup_passphrase_field')), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('backup_save_button'))).onPressed,
        isNull,
      );

      await tester.enterText(find.byKey(const Key('backup_passphrase_field')), 'strong-pass-2026');
      await tester.enterText(find.byKey(const Key('backup_confirm_passphrase_field')), 'strong-pass-2026');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('backup_save_button'))).onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(const Key('backup_encrypt_switch')));
      await tester.pump();
      expect(find.byKey(const Key('backup_unencrypted_warning')), findsOneWidget);
    });

    testWidgets('shows the formatted last-backup time when a backup exists', (tester) async {
      File('${tempDir.path}/backup_meta.json')
          .writeAsStringSync('{"lastBackupAt":"2026-10-19T10:30:00.000Z"}');

      await pumpImportBackupScreen(tester, delay: const Duration(milliseconds: 100));

      expect(find.text('尚未创建备份'), findsNothing);
      expect(find.textContaining('2026-10-19'), findsOneWidget);
      final tile = tester.widget<ListTile>(find.byKey(const Key('import_backup_last_backup_tile')));
      final icon = tile.leading as Icon;
      expect(icon.icon, Icons.history_edu_outlined);
      expect(icon.size, 20.0);
    });

    testWidgets('creating a backup refreshes the last-backup time on screen', (tester) async {
      await pumpImportBackupScreen(tester, backupPbkdf2Iterations: 100);
      expect(find.text('尚未创建备份'), findsOneWidget);

      await tester.tap(find.byKey(const Key('import_backup_create_backup_tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('backup_encrypt_switch')));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('backup_save_button')));
        for (var attempt = 0; attempt < 20; attempt++) {
          await Future.delayed(const Duration(milliseconds: 50));
          await tester.pump(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('backup_save_button')), findsNothing);
      expect(find.text('尚未创建备份'), findsNothing);
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      expect(find.textContaining(todayStr), findsOneWidget);
      expect(find.textContaining('已导出备份'), findsOneWidget);
    });

    testWidgets('从备份恢复 with a valid backup opens the restore dialog', (tester) async {
      final backupService = BackupRestoreService(
        database: db,
        mediaService: mediaService,
        tempDirProvider: () async => tempDir,
      );
      final backupFile = File('${tempDir.path}/sample.mdbak');
      await tester.runAsync(() => backupService.createBackup(destination: backupFile));
      mockFileSelector.pickedBackupFile = backupFile;

      await pumpImportBackupScreen(tester, backupService: backupService);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('import_backup_restore_backup_tile')));
        for (var attempt = 0; attempt < 10; attempt++) {
          await Future.delayed(const Duration(milliseconds: 50));
          await tester.pump(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('restore_confirm_checkbox')), findsOneWidget);
      expect(find.byKey(const Key('restore_replace_warning')), findsOneWidget);
    });

    testWidgets('从备份恢复 with an unreadable file reports the backup as invalid', (tester) async {
      mockFileSelector.pickedBackupFile = File('${tempDir.path}/broken.mdbak')
        ..writeAsBytesSync([1, 2, 3]);

      await pumpImportBackupScreen(tester);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('import_backup_restore_backup_tile')));
        for (var attempt = 0; attempt < 10; attempt++) {
          await Future.delayed(const Duration(milliseconds: 50));
          await tester.pump(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('restore_confirm_checkbox')), findsNothing);
      expect(find.textContaining('备份文件无效或无法读取'), findsOneWidget);
    });

    testWidgets('follows the active dark Atmosphere Palette and fits 320dp at 1.3x text scale',
        (tester) async {
      await pumpImportBackupScreen(
        tester,
        viewportSize: const Size(320, 900),
        textScale: 1.3,
        darkPalette: DarkAtmospherePaletteId.blossomLantern,
      );

      expect(tester.takeException(), isNull);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF0D1B1E)));
      expect(find.text('从备份恢复'), findsOneWidget);
    });
  });
}
