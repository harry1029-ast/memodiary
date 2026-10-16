import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'core/database/app_database.dart';
import 'core/database/database_key_manager.dart';
import 'core/services/media_sandbox_service.dart';
import 'core/services/recycle_bin_service.dart';
import 'features/auth/app_lock_gate.dart';
import 'features/timeline/screens/timeline_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // 3. Launch with AppLockGate protecting all views
  runApp(
    AppLockGate(
      child: MemoDiaryApp(
        database: database,
        mediaService: mediaService,
      ),
    ),
  );
}

class MemoDiaryApp extends StatelessWidget {
  final AppDatabase database;
  final MediaSandboxService mediaService;

  const MemoDiaryApp({
    super.key,
    required this.database,
    required this.mediaService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoDiary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
      ),
      home: TimelineScreen(
        database: database,
        mediaService: mediaService,
      ),
    );
  }
}
