import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'core/database/app_database.dart';
import 'core/database/database_key_manager.dart';
import 'core/services/media_sandbox_service.dart';
import 'core/services/recycle_bin_service.dart';
import 'core/theme/ink_diary_theme.dart';
import 'features/auth/app_lock_gate.dart';
import 'features/intro/screens/book_intro_screen.dart';
import 'features/intro/services/book_intro_settings_service.dart';
import 'features/timeline/screens/timeline_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Ensure SQLCipher native libraries are properly loaded on Android
  if (Platform.isAndroid) {
    try {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    } catch (e) {
      debugPrint('SQLCipher Android workaround note: $e');
    }
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }

  // 1. Initialize encrypted database with secure hardware key
  final keyManager = DatabaseKeyManager();
  final encryptionKey = await keyManager.getOrCreateKey();
  final appDocsDir = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(appDocsDir.path, 'memodiary_encrypted.db'));

  final database = AppDatabase.encrypted(
    dbFile: dbFile,
    encryptionKey: encryptionKey,
  );
  final mediaService = MediaSandboxService();

  // 2. Execute 30-day auto-purge on cold startup to reclaim physical storage
  try {
    await RecycleBinService.purgeExpiredEntries(
      database: database,
      mediaService: mediaService,
    );
  } catch (e) {
    debugPrint('Auto-purge exception during cold start: $e');
  }

  // 3. Check whether to display the 3D Book Intro cover on launch
  final introSettings = BookIntroSettingsService();
  final showIntroOnLaunch = await introSettings.getShouldShowOnLaunch();

  // 4. Launch with AppLockGate protecting all views
  runApp(
    AppLockGate(
      child: MemoDiaryApp(
        database: database,
        mediaService: mediaService,
        showIntroOnLaunch: showIntroOnLaunch,
      ),
    ),
  );
}

class MemoDiaryApp extends StatelessWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final bool showIntroOnLaunch;

  const MemoDiaryApp({
    super.key,
    required this.database,
    required this.mediaService,
    this.showIntroOnLaunch = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoDiary',
      debugShowCheckedModeBanner: false,
      theme: InkDiaryTheme.light,
      darkTheme: InkDiaryTheme.dark,
      home: showIntroOnLaunch
          ? BookIntroScreen(
              database: database,
              mediaService: mediaService,
            )
          : TimelineScreen(
              database: database,
              mediaService: mediaService,
            ),
    );
  }
}
