import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/models/backup_manifest.dart';
import 'package:memodiary/features/import_export/services/backup_restore_service.dart';
import 'package:memodiary/features/import_export/widgets/backup_dialogs.dart';
import 'export_service_test.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;
  late BackupRestoreService backupService;
  late MockFileSelectorService mockFileSelector;

  setUp(() {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('backup_dialogs_test_');
    mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
    backupService = BackupRestoreService(
      database: db,
      mediaService: mediaService,
      tempDirProvider: () async => tempDir,
    );
    mockFileSelector = MockFileSelectorService();
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CreateBackupDialog & RestoreBackupDialog Plain Chinese Diction Tests', () {
    testWidgets('CreateBackupDialog displays plain Chinese labels and passphrase validation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateBackupDialog(
              backupService: backupService,
              fileSelector: mockFileSelector,
              pbkdf2Iterations: 1000,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('导出加密备份 (.mdbak)'), findsOneWidget);
      expect(find.text('使用口令加密 (AES-256-GCM)'), findsOneWidget);
      expect(find.text('加密口令（至少 8 位）'), findsOneWidget);
      expect(find.text('确认加密口令'), findsOneWidget);
      expect(find.text('请输入至少 8 位字符的加密口令。'), findsOneWidget);
      expect(find.text('分享...'), findsOneWidget);
      expect(find.text('保存到设备'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('backup_passphrase_field')), '1234');
      await tester.pump();
      expect(find.text('口令至少需要 8 位字符（4/8）。'), findsOneWidget);

      await tester.tap(find.byKey(const Key('backup_encrypt_switch')));
      await tester.pump();
      expect(find.byKey(const Key('backup_unencrypted_warning')), findsOneWidget);
      expect(find.textContaining('未加密备份会以明文保存'), findsOneWidget);
    });

    testWidgets('RestoreBackupDialog displays plain Chinese labels and requires confirmation', (tester) async {
      final dummyFile = File('${tempDir.path}/sample.mdbak')..writeAsBytesSync([1, 2, 3]);
      const inspection = BackupInspection(
        formatVersion: 1,
        isEncrypted: true,
        pbkdf2Iterations: 1000,
        fileSizeBytes: 128,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestoreBackupDialog(
              sourceFile: dummyFile,
              inspection: inspection,
              backupService: backupService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('从备份恢复'), findsOneWidget);
      expect(find.text('已选择备份文件：sample.mdbak'), findsOneWidget);
      expect(find.text('备份口令'), findsOneWidget);
      expect(find.text('我已知晓恢复备份将覆盖当前全部日记数据'), findsOneWidget);
      expect(find.text('覆盖并恢复'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);

      final confirmBtnBefore = tester.widget<FilledButton>(
        find.byKey(const Key('restore_confirm_button')),
      );
      expect(confirmBtnBefore.onPressed, isNull);

      await tester.enterText(find.byKey(const Key('restore_passphrase_field')), 'secret-pass');
      await tester.tap(find.byKey(const Key('restore_confirm_checkbox')));
      await tester.pump();

      final confirmBtnAfter = tester.widget<FilledButton>(
        find.byKey(const Key('restore_confirm_button')),
      );
      expect(confirmBtnAfter.onPressed, isNotNull);
    });
  });
}
